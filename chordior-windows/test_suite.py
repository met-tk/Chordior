"""
自动化全面测试套件 (Test Suite)
验证乐理引擎、0 延迟音频合成、MIDI 导出、预设库、UI 组件实例化、吉他品位交互与调式列表点击安全性。
"""

import os
import sys
import unittest
import numpy as np

# 导入所有核心模块
from theory_engine import (
    NOTE_NAMES, CHORD_TYPES, MODES, get_chord_notes,
    get_all_scales, identify_chord_name, get_mode_harmonics,
    CIRCLE_OF_FIFTHS, note_name_to_pitch_class
)
from audio_synth import SynthEngine, notes_to_piano_indices
from midi_utils import build_progression_midi, export_progression_as_text
from presets_dialog import PROGRESSION_PRESETS
from PyQt5.QtWidgets import QApplication, QListWidgetItem
from PyQt5.QtCore import Qt


class TestChordStudio(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        if not QApplication.instance():
            cls.app = QApplication(sys.argv)
        else:
            cls.app = QApplication.instance()

    def test_01_theory_engine_chords(self):
        """测试基础与进阶和弦构成音计算"""
        c_maj = get_chord_notes('C', 'Maj')
        self.assertEqual(c_maj, ['C', 'E', 'G'])

        a_m7 = get_chord_notes('A', 'm7')
        self.assertEqual(a_m7, ['A', 'C', 'E', 'G'])

        g_7 = get_chord_notes('G', '7')
        self.assertEqual(g_7, ['G', 'B', 'D', 'F'])

        d_m7b5 = get_chord_notes('D', 'm7b5')
        self.assertEqual(d_m7b5, ['D', 'F', 'G#/Ab', 'C'])

    def test_02_chord_identification(self):
        """测试和弦反向识别与转位分析"""
        name1 = identify_chord_name([12, 16, 19])
        self.assertIn("C Maj", name1)

        name2 = identify_chord_name([16, 19, 24])
        self.assertTrue("1转位" in name2 or "E" in name2)

        name3 = identify_chord_name([9, 12, 16])
        self.assertIn("A min", name3)

    def test_03_scale_generation_and_harmonics(self):
        """测试所有调式音阶生成与顺阶和弦级数"""
        scales = get_all_scales()
        self.assertIn("C Ionian (自然大调 Major)", scales)
        self.assertEqual(len(scales["C Ionian (自然大调 Major)"]), 7)

        harmonics = get_mode_harmonics('C', 'Ionian (自然大调 Major)', depth='Triad')
        self.assertEqual(len(harmonics), 7)
        self.assertEqual(harmonics[0]['roman'], 'I')
        self.assertIn("C Maj", harmonics[0]['name'])
        self.assertEqual(harmonics[4]['roman'], 'V')
        self.assertIn("G Maj", harmonics[4]['name'])

    def test_04_audio_synth_waveforms_and_low_latency(self):
        """测试音频合成器 0 延迟单音与和弦 PCM 生成"""
        synth = SynthEngine()
        settings = {'timbre': 'Grand Piano', 'mode': 'Simultaneous', 'volume': 0.85, 'octave_shift': 0}

        # 0 延迟单音测试
        synth.play_single_key(12, settings)

        # 和弦渲染测试
        pcm = synth.render_chord_wave([12, 16, 19], settings)
        self.assertGreater(len(pcm), 0)
        self.assertEqual(pcm.dtype, np.int16)
        self.assertFalse(np.isnan(pcm).any())
        synth.close()

    def test_05_midi_generation(self):
        """测试 MIDI 文件与文本谱生成"""
        test_blocks = [
            {'notes': ['C', 'E', 'G'], 'label': 'C Maj', 'beats': 2},
            {'notes': ['A', 'C', 'E'], 'label': 'A min', 'beats': 2},
            {'notes': ['F', 'A', 'C'], 'label': 'F Maj', 'beats': 2},
            {'notes': ['G', 'B', 'D'], 'label': 'G Maj', 'beats': 2}
        ]
        midi_bytes = build_progression_midi(test_blocks, bpm=120)
        self.assertTrue(midi_bytes.startswith(b'MThd'))
        self.assertIn(b'MTrk', midi_bytes)

        text_score = export_progression_as_text(test_blocks, bpm=120)
        self.assertIn("C Maj", text_score)
        self.assertIn("120", text_score)

    def test_06_presets_integrity(self):
        """测试和弦进行预设库数据完整性"""
        self.assertGreaterEqual(len(PROGRESSION_PRESETS), 10)
        for p in PROGRESSION_PRESETS:
            self.assertIn("name", p)
            self.assertIn("category", p)
            self.assertIn("chords", p)
            self.assertGreater(len(p["chords"]), 0)

    def test_07_main_window_and_scale_click_safety(self):
        """测试主窗口左右双栏布局、吉他品位点击与调式列表点击防崩溃安全性"""
        from chord_finder import ChordStudioMainWindow

        win = ChordStudioMainWindow()
        self.assertIsNotNone(win)
        self.assertEqual(win.left_tabs.count(), 2)

        win.clear_all_selection()
        # 模拟在吉他指板上点击 (第 1 弦第 0 品 E)
        win.on_guitar_fret_clicked(16, "E")
        self.assertIn("E", win.chord_notes_label.text())

        # 模拟点击调式列表项，确保绝不崩溃 0xC0000409
        item = QListWidgetItem("C Ionian (自然大调 Major)        级数: I   ")
        item.setData(Qt.UserRole, {'root': 'C', 'mode': 'Ionian (自然大调 Major)', 'degree': 'I'})
        win.on_scale_item_clicked(item)

        # 切换乐器三态模式
        win.cycle_instrument_view_mode()
        self.assertEqual(win.current_view_mode, 0)
        win.cycle_instrument_view_mode()
        self.assertEqual(win.current_view_mode, 1)
        win.cycle_instrument_view_mode()
        self.assertEqual(win.current_view_mode, 2)

        win.close()


if __name__ == '__main__':
    unittest.main()
