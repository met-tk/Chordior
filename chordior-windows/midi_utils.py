"""
MIDI Utils - 标准 MIDI 文件构建与和弦文本生成工具
支持自定义 BPM、动态小节拍数、开放排列、力度与多和弦音轨导出。
"""

import struct
from theory_engine import note_name_to_pitch_class
from audio_synth import notes_to_piano_indices


def encode_midi_vlq(value):
    """编码 MIDI 标准变长数值 (Variable-Length Quantity)"""
    value = max(0, int(value))
    result = bytearray([value & 0x7F])
    value >>= 7
    while value:
        result.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return result


def notes_to_midi_pitches(notes, open_voicing=False, base_octave_offset=0):
    """
    将音名列表转换为标准 MIDI 音高数值 (0-127)。
    模拟键盘第 1 个八度的 C 对应 MIDI 48 (C3) 或 MIDI 60 (C4)。
    此处使用标准 C4 (MIDI 60) 作为第二组八度基准（即 index 12 -> 60）。
    """
    piano_indices = notes_to_piano_indices(notes, open_voicing=open_voicing)
    # index 24 对应 MIDI 60 (C4)，index 0 对应 MIDI 36 (C2)
    return [36 + idx + (base_octave_offset * 12) for idx in piano_indices]


def build_progression_midi(chord_blocks_data, bpm=120, ticks_per_beat=480, open_voicing=False):
    """
    生成标准单轨 MIDI 二进制数据。
    chord_blocks_data: 列表，每项为字典 {'notes': [...], 'beats': 2, 'label': 'C Maj'}
    """
    bpm = max(20, min(300, int(bpm)))
    microseconds_per_beat = round(60_000_000 / bpm)
    tempo_bytes = microseconds_per_beat.to_bytes(3, byteorder='big')

    # 初始化音轨：设置 Tempo
    track_data = bytearray(b'\x00\xFF\x51\x03') + tempo_bytes

    # 写入 Track Name
    track_name = "Chord Progression"
    name_bytes = track_name.encode('utf-8')
    track_data += b'\x00\xFF\x03' + encode_midi_vlq(len(name_bytes)) + name_bytes

    for block in chord_blocks_data:
        notes = block.get('notes', [])
        beats = float(block.get('beats', 2))
        ticks_duration = int(ticks_per_beat * beats)
        
        midi_pitches = notes_to_midi_pitches(notes, open_voicing=open_voicing)
        if not midi_pitches:
            # 休止符空拍
            track_data += encode_midi_vlq(ticks_duration) + b'\x80\x3C\x00'
            continue

        # Note-On 事件（所有音同时按下）
        for i, pitch in enumerate(midi_pitches):
            delta = 0
            # 基础力度 96，根音略重 105
            vel = 105 if i == 0 else 92
            track_data += encode_midi_vlq(delta) + bytes((0x90, pitch, vel))

        # Note-Off 事件（所有音持续 ticks_duration 后松开）
        for i, pitch in enumerate(midi_pitches):
            delta = ticks_duration if i == 0 else 0
            track_data += encode_midi_vlq(delta) + bytes((0x80, pitch, 0))

    # 音轨结束标志 (End of Track)
    track_data += b'\x00\xFF\x2F\x00'

    # MIDI Header (Format 0, 1 Track, Div=ticks_per_beat)
    header = b'MThd' + struct.pack('>IHHH', 6, 0, 1, ticks_per_beat)
    track = b'MTrk' + struct.pack('>I', len(track_data)) + track_data

    return header + track


def export_progression_as_text(chord_blocks_data, bpm=120):
    """将和弦进行格式化为清晰的乐谱/歌词文本格式"""
    lines = [
        "=" * 40,
        "  Chord & Harmony Studio Pro - 和弦进行谱",
        f"  速度 (BPM): {bpm} | 和弦总数: {len(chord_blocks_data)}",
        "=" * 40,
        ""
    ]
    
    prog_line = ""
    notes_line = ""
    for idx, b in enumerate(chord_blocks_data):
        label = b.get('label', 'Chord')
        beats = b.get('beats', 2)
        notes = ' '.join([n.split('/')[0] for n in b.get('notes', [])])
        
        item_str = f"[{label} ({beats}拍)]"
        prog_line += f"{item_str:<16}"
        notes_line += f"({notes}){' ' * max(0, 16 - len(notes) - 2)}"
        
        if (idx + 1) % 4 == 0:
            lines.append(prog_line)
            lines.append(notes_line)
            lines.append("-" * 40)
            prog_line = ""
            notes_line = ""

    if prog_line:
        lines.append(prog_line)
        lines.append(notes_line)

    lines.append("")
    lines.append("生成的和弦进行直接兼容各大 DAW (FL Studio, Ableton, Logic Pro, Cubase)。")
    return "\n".join(lines)
