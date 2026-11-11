"""
Audio Synth - Windows 原生 waveOut 工业级高保真音频合成与直通播放引擎
支持 48 键全键盘、带黄金引力防漂移的声部平滑诱导 (Voice-Leading Guided)、开放声部 Drop-2 与和弦识别兼容、主和弦最低基准与实时八度移调。
"""

import ctypes
import itertools
import os
import sys
import threading
import time
import numpy as np

from PyQt5.QtCore import QObject, QTimer
from theory_engine import NOTE_NAMES, normalize_note_name, note_name_to_pitch_class

try:
    winmm = ctypes.windll.winmm
except Exception as e:
    winmm = None
    print(f"Failed to load winmm.dll: {e}")

class WAVEFORMATEX(ctypes.Structure):
    _fields_ = [
        ('wFormatTag', ctypes.c_ushort),
        ('nChannels', ctypes.c_ushort),
        ('nSamplesPerSec', ctypes.c_ulong),
        ('nAvgBytesPerSec', ctypes.c_ulong),
        ('nBlockAlign', ctypes.c_ushort),
        ('wBitsPerSample', ctypes.c_ushort),
        ('cbSize', ctypes.c_ushort)
    ]

class WAVEHDR(ctypes.Structure):
    pass

WAVEHDR._fields_ = [
    ('lpData', ctypes.c_char_p),
    ('dwBufferLength', ctypes.c_ulong),
    ('dwBytesRecorded', ctypes.c_ulong),
    ('dwUser', ctypes.c_ulong),
    ('dwFlags', ctypes.c_ulong),
    ('dwLoops', ctypes.c_ulong),
    ('lpNext', ctypes.POINTER(WAVEHDR)),
    ('reserved', ctypes.c_ulong)
]


class WaveOutChannel:
    """Windows 原生硬件混音通道 (waveOut Voice Channel)"""

    def __init__(self, sample_rate=44100):
        self.sample_rate = sample_rate
        self.hWaveOut = ctypes.c_void_p()
        self.is_open = False
        self.current_header = None
        self.current_buffer = None
        self._init_device()

    def _init_device(self):
        if not winmm:
            return
        wfx = WAVEFORMATEX()
        wfx.wFormatTag = 1  # WAVE_FORMAT_PCM
        wfx.nChannels = 2  # 立体声
        wfx.nSamplesPerSec = self.sample_rate
        wfx.wBitsPerSample = 16  # 16-bit
        wfx.nBlockAlign = 4  # 2 channels * 2 bytes
        wfx.nAvgBytesPerSec = self.sample_rate * 4
        wfx.cbSize = 0

        res = winmm.waveOutOpen(ctypes.byref(self.hWaveOut), -1, ctypes.byref(wfx), 0, 0, 0)
        if res == 0:
            self.is_open = True
        else:
            self.is_open = False

    def play_pcm_bytes(self, stereo_bytes):
        """将立体声 PCM 字节流直接提交给 Windows 声卡播放"""
        if not self.is_open:
            self._init_device()
            if not self.is_open:
                return

        try:
            winmm.waveOutReset(self.hWaveOut)
            if self.current_header:
                winmm.waveOutUnprepareHeader(self.hWaveOut, ctypes.byref(self.current_header), ctypes.sizeof(self.current_header))
        except Exception:
            pass

        self.current_buffer = stereo_bytes
        self.current_header = WAVEHDR()
        self.current_header.lpData = self.current_buffer
        self.current_header.dwBufferLength = len(self.current_buffer)
        self.current_header.dwFlags = 0

        winmm.waveOutPrepareHeader(self.hWaveOut, ctypes.byref(self.current_header), ctypes.sizeof(self.current_header))
        winmm.waveOutWrite(self.hWaveOut, ctypes.byref(self.current_header), ctypes.sizeof(self.current_header))

    def stop(self):
        if self.is_open:
            try:
                winmm.waveOutReset(self.hWaveOut)
                if self.current_header:
                    winmm.waveOutUnprepareHeader(self.hWaveOut, ctypes.byref(self.current_header), ctypes.sizeof(self.current_header))
            except Exception:
                pass
            self.current_header = None
            self.current_buffer = None

    def close(self):
        if self.is_open:
            try:
                winmm.waveOutReset(self.hWaveOut)
                if self.current_header:
                    winmm.waveOutUnprepareHeader(self.hWaveOut, ctypes.byref(self.current_header), ctypes.sizeof(self.current_header))
                winmm.waveOutClose(self.hWaveOut)
            except Exception:
                pass
            self.is_open = False


def notes_to_piano_indices(notes, scale_root=None, strategy="Voice-Leading Compact", previous_indices=None, open_voicing=False, step_count=0, contraction_interval=4):
    """
    智能声部排列引擎：将音名列表映射为钢琴 48 键琴键索引 (0~47，对应 C2~B5)。
    - Voice-Leading Compact: 紧凑平滑声部诱导 + 跨度紧凑度惩罚 + 周期性向心收缩居中 (防止声部无限扩张)；
    - Voice-Leading Guided: 以一前一后和弦声部最小移动为导向；
    - Tonic-Root Base: 调内 I 级主和弦为最低音域基准；
    - Key-Anchored: 顺阶音程平缓上升；
    - Strict Root: 根音落在中低音区，后续各音单调递增。
    """
    if not notes:
        return []

    pcs = []
    for n in notes:
        pc = note_name_to_pitch_class(normalize_note_name(n))
        if pc is not None:
            pcs.append(pc)

    if not pcs:
        return []

    root_pc = pcs[0]
    result_indices = []

    # 1. 平滑声部诱导 (Voice-Leading Compact / Voice-Leading Guided)
    if "Voice-Leading" in strategy or "Smooth Voice Leading" in strategy:
        is_compact_strategy = ("Compact" in strategy)
        is_contraction_step = is_compact_strategy and (step_count > 0 and step_count % contraction_interval == 0)

        candidates_pool = []
        for p in pcs:
            candidates_pool.append([i for i in range(48) if i % 12 == p])

        best_combo = None
        min_cost = float('inf')
        target_center = 24.5  # 48 键黄金听感中心 (C4~E4 附近)

        for combo in itertools.product(*candidates_pool):
            if len(set(combo)) != len(combo):
                continue
            sorted_combo = sorted(combo)
            if sorted_combo[0] % 12 != root_pc:
                continue

            # 跨度惩罚 (Span Penalty)：防止声部距离无限拉大
            span = sorted_combo[-1] - sorted_combo[0]
            span_cost = 0.0
            if is_compact_strategy:
                if span > 16:
                    span_cost = 3.5 * (span - 16)
                if span > 24:
                    span_cost += 30.0

            if previous_indices and len(previous_indices) > 0 and not is_contraction_step:
                p_len = min(len(sorted_combo), len(previous_indices))
                move_cost = sum(abs(a - b) for a, b in zip(sorted_combo[:p_len], previous_indices[:p_len]))
            else:
                move_cost = 0.0

            avg_center = sum(sorted_combo) / float(len(sorted_combo))

            # 中心向心力：收缩步大幅增强向黄金中心 (C4) 收缩回归
            gravity_weight = 4.5 if is_contraction_step else 1.3
            gravity_cost = gravity_weight * abs(avg_center - target_center)

            if avg_center > 36.0 or avg_center < 12.0:
                gravity_cost += 35.0

            total_cost = move_cost + gravity_cost + span_cost
            if total_cost < min_cost:
                min_cost = total_cost
                best_combo = sorted_combo

        if best_combo:
            result_indices = list(best_combo)

    # 2. 主和弦最低基准方案 (Tonic-Root Base)
    elif strategy == "Tonic-Root Base" and scale_root:
        scale_root_pc = note_name_to_pitch_class(normalize_note_name(scale_root))
        if scale_root_pc is not None:
            tonic_base_idx = scale_root_pc + 12  # C3~B3 基准
            interval = (root_pc - scale_root_pc) % 12
            chord_root_idx = tonic_base_idx + interval
            if chord_root_idx >= 34:
                chord_root_idx -= 12

            cur_idx = chord_root_idx
            res = [cur_idx]
            for pc in pcs[1:]:
                found = False
                for cand in range(cur_idx + 1, 48):
                    if cand % 12 == pc:
                        cur_idx = cand
                        res.append(cur_idx)
                        found = True
                        break
                if not found:
                    for cand in range(0, 48):
                        if cand % 12 == pc:
                            res.append(cand)
                            break
            result_indices = sorted(res)

    # 3. 调式主音锚定 (Key-Anchored)
    elif strategy == "Key-Anchored" and scale_root:
        scale_root_pc = note_name_to_pitch_class(normalize_note_name(scale_root))
        if scale_root_pc is not None:
            interval_from_scale_root = (root_pc - scale_root_pc) % 12
            base_key = scale_root_pc + 12
            if base_key < 15:
                base_key += 12
            chord_root_idx = base_key + interval_from_scale_root
            if chord_root_idx >= 34:
                chord_root_idx -= 12

            cur_idx = chord_root_idx
            res = [cur_idx]
            for pc in pcs[1:]:
                found = False
                for cand in range(cur_idx + 1, 48):
                    if cand % 12 == pc:
                        cur_idx = cand
                        res.append(cur_idx)
                        found = True
                        break
                if not found:
                    for cand in range(0, 48):
                        if cand % 12 == pc:
                            res.append(cand)
                            break
            result_indices = sorted(res)

    # 4. 严格原位基础排列 (Strict Root)
    if not result_indices:
        base_root_idx = root_pc + 12  # C3~B3 基准 (12~23)
        if base_root_idx < 16:
            base_root_idx += 12

        cur_idx = base_root_idx
        res = [cur_idx]
        for pc in pcs[1:]:
            found = False
            for cand in range(cur_idx + 1, 48):
                if cand % 12 == pc:
                    cur_idx = cand
                    res.append(cur_idx)
                    found = True
                    break
            if not found:
                for cand in range(0, 48):
                    if cand % 12 == pc:
                        res.append(cand)
                        break
        result_indices = sorted(res)

    # 5. 开放声部排列 (Drop-2 Open Voicing) 处理
    if open_voicing and len(result_indices) >= 4:
        # 在保留最低音为根音的前提下，将次高音提升一个八度，形成开放声部
        sorted_res = sorted(result_indices)
        second_highest = sorted_res[-2]
        if second_highest + 12 < 48:
            sorted_res[-2] = second_highest + 12
            result_indices = sorted(sorted_res)

    return result_indices


class SynthEngine(QObject):
    """基于 Windows waveOut 原生声卡直通的 48 键极速音频合成引擎 (支持实时八度移调)"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.sample_rate = 44100

        self.num_channels = 16
        self.channels = [WaveOutChannel(self.sample_rate) for _ in range(self.num_channels)]
        self.channel_idx = 0

        self._pcm_cache = {}
        self._precache_all_timbres()

    def pitch_to_frequency(self, absolute_index, octave_shift=0):
        """琴键 24 为中央 C4 (261.63 Hz)，支持实时八度移调"""
        return 261.63 * (2.0 ** (((absolute_index - 24) / 12.0) + octave_shift))

    def generate_piano_tone(self, freq, duration=1.4, velocity=0.95):
        fs = self.sample_rate
        num_samples = int(fs * duration)
        t = np.linspace(0, duration, num_samples, False)

        harmonics = [
            (1.0, 1.00, 2.6),
            (2.0, 0.65, 3.6),
            (3.0, 0.42, 4.8),
            (4.0, 0.25, 6.0),
            (5.0, 0.14, 7.5),
            (6.0, 0.08, 9.0),
            (7.0, 0.04, 11.0)
        ]

        wave_arr = np.zeros(num_samples)
        for mult, amp, decay in harmonics:
            h_freq = freq * mult
            if h_freq < fs / 2.1:
                detune = 1.0 + 0.0006 * (mult - 1)
                wave_arr += amp * np.sin(2 * np.pi * h_freq * detune * t) * np.exp(-decay * t)

        attack_len = min(int(fs * 0.005), num_samples)
        if attack_len > 0:
            wave_arr[:attack_len] *= np.linspace(0.0, 1.0, attack_len)

        rel_len = min(int(fs * 0.04), num_samples)
        if rel_len > 0:
            wave_arr[-rel_len:] *= np.linspace(1.0, 0.0, rel_len)

        return wave_arr * velocity

    def generate_electric_piano_tone(self, freq, duration=1.4, velocity=0.95):
        fs = self.sample_rate
        num_samples = int(fs * duration)
        t = np.linspace(0, duration, num_samples, False)

        mod_index = 0.9 * np.exp(-4.5 * t)
        fm_mod = mod_index * np.sin(2 * np.pi * (freq * 2.0) * t)
        carrier = np.sin(2 * np.pi * freq * t + fm_mod)

        sub_h = 0.35 * np.sin(2 * np.pi * (freq * 2.0) * t) * np.exp(-3.2 * t)
        third_h = 0.15 * np.sin(2 * np.pi * (freq * 3.0) * t) * np.exp(-5.5 * t)

        wave_arr = carrier * np.exp(-2.2 * t) + sub_h + third_h

        attack_len = min(int(fs * 0.008), num_samples)
        if attack_len > 0:
            wave_arr[:attack_len] *= np.linspace(0.0, 1.0, attack_len)
        rel_len = min(int(fs * 0.04), num_samples)
        if rel_len > 0:
            wave_arr[-rel_len:] *= np.linspace(1.0, 0.0, rel_len)

        return wave_arr * velocity

    def generate_synth_pad_tone(self, freq, duration=1.6, velocity=0.90):
        fs = self.sample_rate
        num_samples = int(fs * duration)
        t = np.linspace(0, duration, num_samples, False)

        detunes = [0.998, 1.000, 1.002]
        wave_arr = np.zeros(num_samples)
        for d in detunes:
            wave_arr += (1.0 / len(detunes)) * (
                0.7 * np.sin(2 * np.pi * freq * d * t) +
                0.3 * np.sin(2 * np.pi * freq * 2 * d * t)
            )

        attack_len = min(int(fs * 0.10), num_samples // 3)
        if attack_len > 0:
            wave_arr[:attack_len] *= np.linspace(0.0, 1.0, attack_len)
        decay_len = min(int(fs * 0.15), num_samples)
        if decay_len > 0:
            wave_arr[-decay_len:] *= np.linspace(1.0, 0.0, decay_len)

        return wave_arr * velocity

    def generate_pure_sine_tone(self, freq, duration=1.2, velocity=0.95):
        fs = self.sample_rate
        num_samples = int(fs * duration)
        t = np.linspace(0, duration, num_samples, False)
        wave_arr = np.sin(2 * np.pi * freq * t)

        fade_len = min(int(fs * 0.01), num_samples // 4)
        if fade_len > 0:
            wave_arr[:fade_len] *= np.linspace(0.0, 1.0, fade_len)
            wave_arr[-fade_len:] *= np.linspace(1.0, 0.0, fade_len)
        return wave_arr * velocity

    def generate_single_tone(self, freq, duration=1.4, timbre="Grand Piano", velocity=0.95):
        if timbre in ["Grand Piano", "Piano Sim", "Acoustic Piano"]:
            return self.generate_piano_tone(freq, duration, velocity)
        elif timbre in ["Electric Piano", "Rhodes", "EP"]:
            return self.generate_electric_piano_tone(freq, duration, velocity)
        elif timbre in ["Synth Pad", "Atmosphere"]:
            return self.generate_synth_pad_tone(freq, duration, velocity)
        else:
            return self.generate_pure_sine_tone(freq, duration, velocity)

    def _convert_pcm_to_stereo_bytes(self, mono_arr, volume=0.85):
        max_val = np.max(np.abs(mono_arr))
        if max_val > 0.001:
            mono_arr = (mono_arr / max_val) * (32760.0 * max(0.1, min(1.0, volume)))

        int16_mono = mono_arr.astype(np.int16)
        stereo_bytes = np.column_stack((int16_mono, int16_mono)).tobytes()
        return stereo_bytes

    def _precache_all_timbres(self):
        timbres = ["Grand Piano", "Electric Piano", "Synth Pad", "Pure Sine"]
        for t_name in timbres:
            dur = 1.6 if t_name == "Synth Pad" else 1.3
            for abs_idx in range(48):
                freq = self.pitch_to_frequency(abs_idx, octave_shift=0)
                mono = self.generate_single_tone(freq, duration=dur, timbre=t_name, velocity=0.95)
                self._pcm_cache[(t_name, abs_idx)] = self._convert_pcm_to_stereo_bytes(mono, volume=0.85)

    def _get_next_channel(self):
        ch = self.channels[self.channel_idx]
        self.channel_idx = (self.channel_idx + 1) % self.num_channels
        return ch

    def play_single_key(self, abs_idx, settings=None):
        if settings is None:
            settings = {}

        timbre = settings.get('timbre', 'Grand Piano')
        vol = float(settings.get('volume', 0.85))
        oct_shift = int(settings.get('octave_shift', 0))

        if oct_shift == 0 and (timbre, abs_idx) in self._pcm_cache:
            stereo_bytes = self._pcm_cache[(timbre, abs_idx)]
        else:
            freq = self.pitch_to_frequency(abs_idx, octave_shift=oct_shift)
            mono = self.generate_single_tone(freq, duration=1.3, timbre=timbre)
            stereo_bytes = self._convert_pcm_to_stereo_bytes(mono, volume=vol)

        ch = self._get_next_channel()
        ch.play_pcm_bytes(stereo_bytes)

    def play_chord(self, key_indices, settings):
        if not key_indices:
            return

        sorted_indices = sorted(key_indices)
        timbre = settings.get('timbre', 'Grand Piano')
        mode = settings.get('mode', 'Simultaneous')
        pattern = settings.get('pattern', 'Up')
        speed = float(settings.get('speed', 0.12))
        vol = float(settings.get('volume', 0.85))
        oct_shift = int(settings.get('octave_shift', 0))

        note_sequence = list(sorted_indices)
        if mode == 'Arpeggio':
            if pattern == 'Down':
                note_sequence = sorted_indices[::-1]
            elif pattern == 'Up-Down':
                if len(sorted_indices) > 1:
                    note_sequence = sorted_indices + sorted_indices[-2:0:-1]

        if mode == 'Simultaneous':
            duration = 1.4
            fs = self.sample_rate
            mono_chord = np.zeros(int(fs * duration))
            for idx in note_sequence:
                freq = self.pitch_to_frequency(idx, octave_shift=oct_shift)
                mono_chord += self.generate_single_tone(freq, duration=duration, timbre=timbre, velocity=0.92)

            stereo_bytes = self._convert_pcm_to_stereo_bytes(mono_chord, volume=vol)
            ch = self._get_next_channel()
            ch.play_pcm_bytes(stereo_bytes)

        elif mode == 'Pop Strum':
            strum_gap_ms = 35
            for i, idx in enumerate(note_sequence):
                delay = int(i * strum_gap_ms)
                if delay == 0:
                    self.play_single_key(idx, settings)
                else:
                    QTimer.singleShot(delay, lambda target_idx=idx: self.play_single_key(target_idx, settings))

        else:
            arpeggio_gap_ms = max(50, int(speed * 1000))
            for i, idx in enumerate(note_sequence):
                delay = int(i * arpeggio_gap_ms)
                if delay == 0:
                    self.play_single_key(idx, settings)
                else:
                    QTimer.singleShot(delay, lambda target_idx=idx: self.play_single_key(target_idx, settings))

    def render_chord_wave(self, key_indices, settings):
        if not key_indices:
            return np.zeros(0, dtype=np.int16)
        timbre = settings.get('timbre', 'Grand Piano')
        oct_shift = int(settings.get('octave_shift', 0))
        duration = 1.3
        fs = self.sample_rate
        mono_wave = np.zeros(int(fs * duration))
        for idx in key_indices:
            freq = self.pitch_to_frequency(idx, octave_shift=oct_shift)
            mono_wave += self.generate_single_tone(freq, duration, timbre)
        max_val = np.max(np.abs(mono_wave))
        if max_val > 0.001:
            mono_wave = (mono_wave / max_val) * 30000.0
        return mono_wave.astype(np.int16)

    def stop(self):
        for ch in self.channels:
            ch.stop()

    def close(self):
        for ch in self.channels:
            ch.close()
