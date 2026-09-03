"""
Chord & Harmony Studio Pro - 现代专业乐理与和声工作站
双层音符体系 (同心双环光晕融合渲染)、和弦块平滑声部诱导 (Voice-Leading Guided)、主和弦最低基准 (Tonic-Root Base) 与检索严格原位独立作用域。
"""

import json
import os
import re
import sys

# 自动修复 Windows 下 PyQt5 平台插件加载路径
def _fix_qt_platform_plugin_path():
    try:
        import PyQt5
        pyqt_base = os.path.dirname(PyQt5.__file__)
        candidates = [
            os.path.join(pyqt_base, "Qt5", "plugins", "platforms"),
            os.path.join(pyqt_base, "Qt", "plugins", "platforms"),
            os.path.join(pyqt_base, "plugins", "platforms")
        ]
        for path in candidates:
            if os.path.isdir(path):
                os.environ["QT_QPA_PLATFORM_PLUGIN_PATH"] = path
                break
    except Exception:
        pass

_fix_qt_platform_plugin_path()

def resource_path(relative_path):
    """获取资源绝对路径，兼容 PyInstaller 单文件打包临时解压目录与源码工作目录"""
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.abspath("."), relative_path)

# 开启 High-DPI 高分屏自动缩放与高清像素图
from PyQt5.QtCore import QEvent, QPoint, QSettings, QSize, Qt, QTimer, pyqtSignal
from PyQt5.QtGui import QColor, QFont, QIcon, QKeySequence, QPalette
from PyQt5.QtWidgets import (QAction, QApplication, QButtonGroup, QCheckBox,
                             QComboBox, QFileDialog, QFrame,
                             QGraphicsDropShadowEffect, QGroupBox, QHBoxLayout,
                             QLabel, QLineEdit, QListWidget, QListWidgetItem,
                             QMainWindow, QMessageBox, QPushButton, QRadioButton,
                             QScrollArea, QShortcut, QSlider, QSpinBox,
                             QSplitter, QTabWidget, QTextEdit, QVBoxLayout,
                             QWidget)

from audio_settings_dialog import AudioSettingsDialog, COORDINATED_PRESETS
from audio_synth import SynthEngine, notes_to_piano_indices
from circle_of_fifths import CircleOfFifthsWidget
from guitar_widget import GuitarFretboardView
from harmonic_matrix import HarmonicMatrixWidget
from midi_utils import build_progression_midi
from piano_widget import ZoomablePianoView
from progression_studio import ProgressionStudioWidget
from styles import DARK_THEME_QSS, LIGHT_THEME_QSS
from theory_engine import (CHORD_CATEGORIES, CHORD_TYPES, HIDDEN_CHORD_TYPES,
                           MODE_COLORS, MODES, NO5_UI_MAP, NOTE_NAMES,
                           analyze_chord_structure, get_all_scales,
                           get_chord_notes, identify_chord_name,
                           normalize_note_name, note_name_to_pitch_class)


class ZoomableScalesListWidget(QListWidget):
    """支持 Ctrl+滚轮缩放与行高显示密度调节的调式匹配列表"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.density_mode = "compact"
        self.font_size = 11
        self.apply_density("compact")

    def apply_density(self, density):
        self.density_mode = density
        if density == "ultra":
            self.font_size = 10
            pad_v = 1
        elif density == "comfortable":
            self.font_size = 12
            pad_v = 6
        else:  # compact (默认推荐，同屏容纳更多项目)
            self.font_size = 11
            pad_v = 3

        self.setStyleSheet(f"""
            QListWidget::item {{
                padding: {pad_v}px 8px;
                margin: 1px 0px;
            }}
        """)
        self.apply_font()

    def apply_font(self):
        font = QFont("Consolas", self.font_size, QFont.Bold)
        self.setFont(font)
        for i in range(self.count()):
            item = self.item(i)
            if item:
                item.setFont(font)

    def wheelEvent(self, event):
        if event.modifiers() & Qt.ControlModifier:
            delta = event.angleDelta().y()
            if delta > 0:
                self.font_size = min(20, self.font_size + 1)
            else:
                self.font_size = max(8, self.font_size - 1)
            self.apply_font()
            event.accept()
            return
        super().wheelEvent(event)


class ChordStudioMainWindow(QMainWindow):
    """乐理与和声工作站主窗口"""

    VIEW_MODE_PIANO_ONLY = 0
    VIEW_MODE_GUITAR_ONLY = 1
    VIEW_MODE_BOTH = 2

    def __init__(self):
        super().__init__()
        self.setWindowTitle("Chordior")
        self.resize(1440, 860)
        self.setMinimumSize(1180, 700)

        # 设置程序主图标 (优先使用定制 app_icon.ico / icon.png)
        for icon_candidate in ["app_icon.ico", "icon_concepts/icon.png", "钢琴.ico"]:
            full_path = resource_path(icon_candidate)
            if os.path.exists(full_path):
                self.setWindowIcon(QIcon(full_path))
                break

        # 初始化配置与引擎
        self.settings_store = QSettings("TaketoAudio", "Chordior")
        self.all_scales = get_all_scales()
        self.is_dark_theme = bool(self.settings_store.value("is_dark_theme", True, type=bool))
        self.current_view_mode = int(self.settings_store.value("instrument_view_mode", self.VIEW_MODE_BOTH))
        self.scale_sort_mode = int(self.settings_store.value("scale_sort_mode", 0))

        # 调式音阶状态
        self.current_scale_root = ""
        self.current_scale_mode = ""
        self.current_scale_pitch_classes = set()

        # 状态防抖锁
        self._is_updating_ui = False

        self.synth = SynthEngine(self)
        self.load_audio_settings()

        # 和弦进行工坊子窗口
        self.prog_studio = ProgressionStudioWidget(synth_engine=self.synth, parent=self)
        self.prog_studio.preview_chord_requested.connect(self.on_progression_chord_preview)
        self.prog_studio.add_curr_btn.clicked.connect(self.add_current_to_progression)

        self.init_ui()
        self.apply_theme(self.is_dark_theme)
        self.update_instrument_view_mode(self.current_view_mode)

        # 应用键盘与吉他独立高亮色彩方案
        if 'piano_color_scheme' in self.play_settings:
            self.piano_view.set_color_scheme(self.play_settings['piano_color_scheme'])
        elif 'color_scheme' in self.play_settings:
            self.piano_view.set_color_scheme(self.play_settings['color_scheme'])

        if 'guitar_color_scheme' in self.play_settings:
            self.guitar_view.set_color_scheme(self.play_settings['guitar_color_scheme'])
        elif 'color_scheme' in self.play_settings:
            self.guitar_view.set_color_scheme(self.play_settings['color_scheme'])

        # 应用吉他根音高亮设置与八度淡化透光率
        self.guitar_view.set_highlight_root(self.play_settings.get('highlight_guitar_root', True))
        self.guitar_view.set_octave_fade_opacity(self.play_settings.get('guitar_octave_fade_opacity', 0.38))

        # 全面恢复用户上一次退出的全部配置、窗口布局与所有下拉菜单状态
        self.restore_full_ui_state()

        # 快捷键
        QShortcut(QKeySequence(Qt.Key_Space), self, self.play_current_selection)
        QShortcut(QKeySequence("Ctrl+P"), self, self.toggle_progression_window)
        QShortcut(QKeySequence("Ctrl+G"), self, self.cycle_instrument_view_mode)
        QShortcut(QKeySequence("Ctrl+D"), self, self.toggle_theme)

    def load_audio_settings(self):
        self.voice_leading_step_count = 0
        preset_name = self.settings_store.value('color_preset_name', '默认电光蓝与象牙白 (Electric Blue & Ivory)')
        matched_preset = COORDINATED_PRESETS.get(preset_name)

        # 默认基础配色
        default_piano = {
            'black_chord_color': '#ffffff',
            'white_chord_color': '#38bdf8',
            'scale_color': '#0ea5e9',
            'both_accent_color': '#f59e0b'
        }
        if matched_preset and 'piano' in matched_preset:
            default_piano.update(matched_preset['piano'])

        default_guitar = {
            'chord_color': '#38bdf8',
            'scale_color': '#0ea5e9',
            'both_accent_color': '#f59e0b',
            'root_color': '#f97316'
        }
        if matched_preset and 'guitar' in matched_preset:
            default_guitar.update(matched_preset['guitar'])

        # 优先读取 JSON 整体配置，多级安全容错
        def read_scheme(prefix, default_dict):
            raw_json = self.settings_store.value(f"{prefix}_color_scheme_json", "")
            if raw_json:
                try:
                    data = json.loads(raw_json) if isinstance(raw_json, str) else raw_json
                    if isinstance(data, dict):
                        res = dict(default_dict)
                        res.update(data)
                        return res
                except Exception:
                    pass

            res = dict(default_dict)
            for k in default_dict.keys():
                v = self.settings_store.value(f"{prefix}_{k}")
                if not v:
                    short_k = k.replace('_color', '')
                    v = self.settings_store.value(f"{prefix}_{short_k}")
                if not v:
                    v = self.settings_store.value(k)
                if v:
                    res[k] = str(v)
            return res

        piano_scheme = read_scheme('piano', default_piano)
        guitar_scheme = read_scheme('guitar', default_guitar)

        self.play_settings = {
            'voicing_strategy': self.settings_store.value('voicing_strategy', 'Voice-Leading Compact'),
            'contraction_interval': int(self.settings_store.value('contraction_interval', 4)),
            'scales_list_density': self.settings_store.value('scales_list_density', 'compact'),
            'timbre': self.settings_store.value('timbre', 'Grand Piano'),
            'mode': self.settings_store.value('mode', 'Simultaneous'),
            'pattern': self.settings_store.value('pattern', 'Up'),
            'speed': float(self.settings_store.value('speed', 0.12)),
            'volume': float(self.settings_store.value('volume', 0.85)),
            'octave_shift': int(self.settings_store.value('octave_shift', 0)),
            'highlight_guitar_root': bool(self.settings_store.value('highlight_guitar_root', True, type=bool)),
            'distinguish_guitar_octaves': bool(self.settings_store.value('distinguish_guitar_octaves', True, type=bool)),
            'guitar_octave_fade_opacity': float(self.settings_store.value('guitar_octave_fade_opacity', 0.38)),
            'color_preset_name': preset_name,
            'piano_color_scheme': piano_scheme,
            'guitar_color_scheme': guitar_scheme
        }

    def save_audio_settings(self):
        for k, v in self.play_settings.items():
            if k == 'piano_color_scheme' and isinstance(v, dict):
                self.settings_store.setValue("piano_color_scheme_json", json.dumps(v))
                for ck, cv in v.items():
                    self.settings_store.setValue(f"piano_{ck}", cv)
                    self.settings_store.setValue(f"piano_{ck.replace('_color', '')}", cv)
            elif k == 'guitar_color_scheme' and isinstance(v, dict):
                self.settings_store.setValue("guitar_color_scheme_json", json.dumps(v))
                for ck, cv in v.items():
                    self.settings_store.setValue(f"guitar_{ck}", cv)
                    self.settings_store.setValue(f"guitar_{ck.replace('_color', '')}", cv)
            elif isinstance(v, dict):
                for ck, cv in v.items():
                    self.settings_store.setValue(ck, cv)
            else:
                self.settings_store.setValue(k, v)

    def apply_theme(self, is_dark):
        self.is_dark_theme = is_dark
        self.settings_store.setValue("is_dark_theme", is_dark)
        if is_dark:
            self.setStyleSheet(DARK_THEME_QSS)
            self.prog_studio.setStyleSheet(DARK_THEME_QSS)
            self.theme_btn.setText("☀ 明亮模式")
            if hasattr(self, 'left_tabs'):
                self.left_tabs.tabBar().setExpanding(False)
                self.left_tabs.setStyleSheet("""
                    QTabWidget::pane {
                        border: 1px solid #282c35;
                        background-color: #181a20;
                        border-radius: 12px;
                        padding: 4px;
                    }
                    QTabBar {
                        alignment: center;
                        background: transparent;
                    }
                    QTabBar::tab {
                        background-color: #20232c;
                        color: #94a3b8;
                        border: 1px solid #333947;
                        border-radius: 8px;
                        padding: 6px 16px;
                        margin: 2px 4px 6px 4px;
                        font-weight: 700;
                        font-size: 12px;
                    }
                    QTabBar::tab:selected {
                        background-color: #282d39;
                        color: #38bdf8;
                        border: 1.5px solid #38bdf8;
                    }
                """)
        else:
            self.setStyleSheet(LIGHT_THEME_QSS)
            self.prog_studio.setStyleSheet(LIGHT_THEME_QSS)
            self.theme_btn.setText("🌙 暗黑模式")
            if hasattr(self, 'left_tabs'):
                self.left_tabs.tabBar().setExpanding(False)
                self.left_tabs.setStyleSheet("""
                    QTabWidget::pane {
                        border: 1.5px solid #e2e8f0;
                        background-color: #ffffff;
                        border-radius: 12px;
                        padding: 4px;
                    }
                    QTabBar {
                        alignment: center;
                        background: transparent;
                    }
                    QTabBar::tab {
                        background-color: #f1f5f9;
                        color: #64748b;
                        border: 1.5px solid #e2e8f0;
                        border-radius: 8px;
                        padding: 6px 16px;
                        margin: 2px 4px 6px 4px;
                        font-weight: 700;
                        font-size: 12px;
                    }
                    QTabBar::tab:selected {
                        background-color: #ffffff;
                        color: #0284c7;
                        border: 1.5px solid #0284c7;
                    }
                """)

        if hasattr(self, 'harmonic_matrix'):
            self.harmonic_matrix.apply_theme(is_dark)

        if hasattr(self, 'scales_list'):
            self._update_analysis_and_scales_list()
            self.scales_list.apply_density(self.play_settings.get('scales_list_density', 'compact'))

        if hasattr(self, 'prog_studio'):
            self.prog_studio.apply_theme(is_dark)

    def center_on_screen(self):
        """将主窗口优雅自适应居中在当前屏幕，绝不挤在角落"""
        screen = QApplication.primaryScreen()
        if screen:
            avail = screen.availableGeometry()
            target_w = min(1520, max(1280, int(avail.width() * 0.90)))
            target_h = min(920, max(800, int(avail.height() * 0.88)))
            self.resize(target_w, target_h)
            x = avail.x() + (avail.width() - target_w) // 2
            y = avail.y() + (avail.height() - target_h) // 2
            self.move(max(0, x), max(0, y))

    def toggle_theme(self):
        self.apply_theme(not self.is_dark_theme)

    def init_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(14, 8, 14, 8)
        main_layout.setSpacing(8)

        # =========================================================================
        # 1. 顶部全局工具栏 (左上角嵌入【当前识别和弦与构成音】，右上角放置功能按钮)
        # =========================================================================
        header_card = QFrame()
        header_card.setObjectName("HeaderCard")
        header_layout = QHBoxLayout(header_card)
        header_layout.setContentsMargins(14, 6, 14, 6)
        header_layout.setSpacing(12)

        # 左上角：当前识别和弦与构成音实时指示区
        chord_live_box = QHBoxLayout()
        chord_live_box.setSpacing(8)

        c_tag = QLabel("当前和弦:")
        c_tag.setFont(QFont("Segoe UI", 11, QFont.Bold))
        chord_live_box.addWidget(c_tag)

        self.chord_display_label = QLabel("None")
        self.chord_display_label.setObjectName("ChordDisplay")
        chord_live_box.addWidget(self.chord_display_label)

        chord_live_box.addSpacing(12)
        n_tag = QLabel("构成音:")
        n_tag.setFont(QFont("Segoe UI", 11, QFont.Bold))
        chord_live_box.addWidget(n_tag)

        self.chord_notes_label = QLabel("—")
        self.chord_notes_label.setFont(QFont("Consolas", 13, QFont.Bold))
        self.chord_notes_label.setStyleSheet("color: #10b981;")
        chord_live_box.addWidget(self.chord_notes_label)

        header_layout.addLayout(chord_live_box)
        header_layout.addStretch()

        # 右上角：功能动作按钮组
        self.view_mode_btn = QPushButton("🎹 视图: 双乐器对照")
        self.view_mode_btn.setObjectName("ModeSwitchButton")
        self.view_mode_btn.setToolTip("点击循环切换：[仅大钢琴] / [仅吉他指板] / [双乐器对照] (快捷键: Ctrl+G)")
        self.view_mode_btn.clicked.connect(self.cycle_instrument_view_mode)
        header_layout.addWidget(self.view_mode_btn)

        self.prog_open_btn = QPushButton("🎹 和弦进行工坊")
        self.prog_open_btn.setObjectName("PlayActionButton")
        self.prog_open_btn.clicked.connect(self.toggle_progression_window)
        header_layout.addWidget(self.prog_open_btn)

        self.theme_btn = QPushButton("🌙 暗黑模式")
        self.theme_btn.clicked.connect(self.toggle_theme)
        header_layout.addWidget(self.theme_btn)

        self.settings_btn = QPushButton("⚙ 音频设置")
        self.settings_btn.clicked.connect(self.open_audio_settings)
        header_layout.addWidget(self.settings_btn)

        main_layout.addWidget(header_card)

        # =======================================================
        # 2. 中部核心工作区：左右双栏黄金布局 (Horizontal Splitter)
        # =======================================================
        self.workspace_splitter = QSplitter(Qt.Horizontal)

        # -------------------------------------------------------
        # 👈 左侧面板：完全由【五度圈调式罗盘】与【调式音阶列表】独占 (Width ~380px)
        # -------------------------------------------------------
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(4, 0, 4, 0)
        left_layout.setSpacing(0)

        self.left_tabs = QTabWidget()
        self.left_tabs.tabBar().setExpanding(False)

        # Tab 1: 五度圈调式罗盘
        tab_circle = QWidget()
        tc_layout = QVBoxLayout(tab_circle)
        tc_layout.setContentsMargins(10, 10, 10, 10)
        self.circle_widget = CircleOfFifthsWidget(self)
        self.circle_widget.key_selected.connect(self.on_circle_key_selected)
        tc_layout.addWidget(self.circle_widget, alignment=Qt.AlignCenter)
        self.left_tabs.addTab(tab_circle, "🌐 五度圈调式罗盘")

        # Tab 2: 调式匹配与分类列表
        tab_scales = QWidget()
        ts_layout = QVBoxLayout(tab_scales)
        ts_layout.setContentsMargins(8, 8, 8, 8)
        ts_layout.setSpacing(6)

        sort_bar = QHBoxLayout()
        sort_bar.addWidget(QLabel("排序:"))
        self.sort_by_root_radio = QRadioButton("按主音分组 (By Root)")
        self.sort_by_mode_radio = QRadioButton("按调式类型分组 (By Mode)")

        if self.scale_sort_mode == 1:
            self.sort_by_mode_radio.setChecked(True)
        else:
            self.sort_by_root_radio.setChecked(True)

        self.sort_by_root_radio.toggled.connect(self.on_scale_sort_changed)
        self.sort_by_mode_radio.toggled.connect(self.on_scale_sort_changed)

        sort_bar.addWidget(self.sort_by_root_radio)
        sort_bar.addWidget(self.sort_by_mode_radio)
        sort_bar.addStretch()
        ts_layout.addLayout(sort_bar)

        self.scales_tip_label = QLabel("💡 当前未选音，展示全部调式音阶:")
        self.scales_tip_label.setStyleSheet("color: #64748b; font-size: 11px;")
        ts_layout.addWidget(self.scales_tip_label)

        self.scales_list = ZoomableScalesListWidget(self)
        self.scales_list.itemClicked.connect(self.on_scale_item_clicked)
        ts_layout.addWidget(self.scales_list)
        self.left_tabs.addTab(tab_scales, "📋 调式音阶列表")

        left_layout.addWidget(self.left_tabs)
        self.workspace_splitter.addWidget(left_panel)

        # -------------------------------------------------------
        # 👉 右侧主舞台：和弦检索 + 和声矩阵 + 乐器交互区 (大宽屏视野)
        # -------------------------------------------------------
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(8)

        # 右 1：和弦快速检索与加入进行工坊控制栏 (基础原位排列)
        search_card = QFrame()
        search_card.setObjectName("CardPanel")
        sc_layout = QHBoxLayout(search_card)
        sc_layout.setContentsMargins(14, 8, 14, 8)
        sc_layout.setSpacing(12)

        search_box = QHBoxLayout()
        search_box.setSpacing(6)
        search_box.addWidget(QLabel("和弦根音:"))
        self.root_combo = QComboBox()
        self.root_combo.setMaxVisibleItems(25)
        self.root_combo.addItem("— (未指定)", "")
        for n in NOTE_NAMES:
            self.root_combo.addItem(n, n)
        search_box.addWidget(self.root_combo)

        search_box.addWidget(QLabel("和弦类型:"))
        self.type_combo = QComboBox()
        self.type_combo.setMaxVisibleItems(25)
        self.type_combo.addItem("— (未指定)", "")
        for cat_name, chord_items in CHORD_CATEGORIES.items():
            for c_name, _, c_desc in chord_items:
                self.type_combo.addItem(f"{c_name} - {c_desc}", c_name)
        search_box.addWidget(self.type_combo, stretch=2)

        self.apply_preset_btn = QPushButton("🔍 在调式中匹配")
        self.apply_preset_btn.setObjectName("PrimaryButton")
        self.apply_preset_btn.setToolTip("在所有调式音阶中搜索该和弦")
        self.apply_preset_btn.clicked.connect(self.on_search_preset_chord)
        search_box.addWidget(self.apply_preset_btn)
        sc_layout.addLayout(search_box)

        sc_layout.addStretch()

        self.add_to_prog_btn = QPushButton("＋ 加入进行工坊")
        self.add_to_prog_btn.setObjectName("PrimaryButton")
        self.add_to_prog_btn.clicked.connect(self.add_current_to_progression)
        sc_layout.addWidget(self.add_to_prog_btn)

        right_layout.addWidget(search_card)

        # 右 2：调式顺阶和声矩阵 (Modal Harmony Grid)
        matrix_card = QFrame()
        matrix_card.setObjectName("CardPanel")
        matrix_layout = QVBoxLayout(matrix_card)
        matrix_layout.setContentsMargins(14, 8, 14, 8)
        matrix_layout.setSpacing(6)

        m_title_row = QHBoxLayout()
        m_title = QLabel("调式 Modes")
        m_title.setObjectName("SectionTitle")
        m_title_row.addWidget(m_title)
        m_title_row.addStretch()
        matrix_layout.addLayout(m_title_row)

        self.harmonic_matrix = HarmonicMatrixWidget(self)
        self.harmonic_matrix.chord_triggered.connect(self.on_harmonic_matrix_chord_triggered)
        self.harmonic_matrix.scale_changed.connect(self.on_harmonic_matrix_scale_changed)
        matrix_layout.addWidget(self.harmonic_matrix)

        right_layout.addWidget(matrix_card)

        # 右 3：乐器交互演奏区 (大钢琴键盘 + 6 弦吉他指板)
        self.instruments_panel = QFrame()
        self.instruments_panel.setObjectName("InstrumentContainer")
        self.instruments_layout = QVBoxLayout(self.instruments_panel)
        self.instruments_layout.setContentsMargins(12, 8, 12, 8)
        self.instruments_layout.setSpacing(6)

        # 钢琴容器
        self.piano_container = QWidget()
        piano_vbox = QVBoxLayout(self.piano_container)
        piano_vbox.setContentsMargins(0, 0, 0, 0)
        piano_vbox.setSpacing(4)

        piano_header = QHBoxLayout()
        p_title = QLabel("48 键钢琴 (4 Octaves Piano C2-B5)")
        p_title.setObjectName("SectionTitle")
        piano_header.addWidget(p_title)
        piano_header.addStretch()
        piano_vbox.addLayout(piano_header)

        self.piano_view = ZoomablePianoView(self)
        self.piano_view.notes_changed.connect(self.refresh_analysis_from_piano)
        self.piano_view.key_pressed.connect(self.on_single_piano_key_pressed)
        piano_vbox.addWidget(self.piano_view)

        self.instruments_layout.addWidget(self.piano_container)

        # 吉他指板容器
        self.guitar_container = QWidget()
        guitar_vbox = QVBoxLayout(self.guitar_container)
        guitar_vbox.setContentsMargins(0, 0, 0, 0)
        guitar_vbox.setSpacing(4)

        g_title_row = QHBoxLayout()
        g_title = QLabel("6 弦 21 品吉他指板 (21 Frets Fretboard)")
        g_title.setObjectName("SectionTitle")
        g_title_row.addWidget(g_title)
        g_title_row.addStretch()
        guitar_vbox.addLayout(g_title_row)

        self.guitar_view = GuitarFretboardView(self)
        self.guitar_view.fret_clicked.connect(self.on_guitar_fret_clicked)
        guitar_vbox.addWidget(self.guitar_view)

        self.instruments_layout.addWidget(self.guitar_container)
        self.instruments_layout.addStretch()

        right_layout.addWidget(self.instruments_panel, stretch=1)
        self.workspace_splitter.addWidget(right_panel)

        self.workspace_splitter.setSizes([380, 920])
        main_layout.addWidget(self.workspace_splitter, stretch=1)

        # =======================================================
        # 3. 底部发声与控制底栏
        # =======================================================
        bottom_card = QFrame()
        bottom_card.setObjectName("HeaderCard")
        bottom_layout = QHBoxLayout(bottom_card)
        bottom_layout.setContentsMargins(14, 6, 14, 6)
        bottom_layout.setSpacing(12)

        self.play_btn = QPushButton("▶ 🎵 试听当前和弦 (Play - Space)")
        self.play_btn.setObjectName("PlayActionButton")
        self.play_btn.setMinimumHeight(38)
        self.play_btn.clicked.connect(self.play_current_selection)
        bottom_layout.addWidget(self.play_btn, stretch=3)

        self.clear_btn = QPushButton("🗑 清空选音 (Clear)")
        self.clear_btn.setObjectName("DangerButton")
        self.clear_btn.setMinimumHeight(38)
        self.clear_btn.clicked.connect(self.clear_all_selection)
        bottom_layout.addWidget(self.clear_btn, stretch=1)

        bottom_layout.addSpacing(15)

        bottom_layout.addWidget(QLabel("音色:"))
        self.quick_timbre_combo = QComboBox()
        self.quick_timbre_combo.setMaxVisibleItems(10)
        self.quick_timbre_combo.addItems(["Grand Piano", "Electric Piano", "Synth Pad", "Pure Sine"])
        self.quick_timbre_combo.setCurrentText(self.play_settings.get('timbre', 'Grand Piano'))
        self.quick_timbre_combo.currentTextChanged.connect(self.on_quick_timbre_changed)
        bottom_layout.addWidget(self.quick_timbre_combo)

        bottom_layout.addWidget(QLabel("模式:"))
        self.quick_mode_combo = QComboBox()
        self.quick_mode_combo.setMaxVisibleItems(10)
        self.quick_mode_combo.addItems(["Simultaneous", "Pop Strum", "Arpeggio"])
        self.quick_mode_combo.setCurrentText(self.play_settings.get('mode', 'Simultaneous'))
        self.quick_mode_combo.currentTextChanged.connect(self.on_quick_mode_changed)
        bottom_layout.addWidget(self.quick_mode_combo)

        main_layout.addWidget(bottom_card)

        self.refresh_analysis_from_piano()

    def on_scale_sort_changed(self):
        self.scale_sort_mode = 1 if self.sort_by_mode_radio.isChecked() else 0
        self.settings_store.setValue("scale_sort_mode", self.scale_sort_mode)
        self._update_analysis_and_scales_list()

    def cycle_instrument_view_mode(self):
        self.current_view_mode = (self.current_view_mode + 1) % 3
        self.update_instrument_view_mode(self.current_view_mode)

    def update_instrument_view_mode(self, mode):
        self.current_view_mode = mode
        self.settings_store.setValue("instrument_view_mode", mode)

        if mode == self.VIEW_MODE_PIANO_ONLY:
            self.piano_container.setVisible(True)
            self.guitar_container.setVisible(False)
            self.view_mode_btn.setText("🎹 视图: 仅大钢琴")
        elif mode == self.VIEW_MODE_GUITAR_ONLY:
            self.piano_container.setVisible(False)
            self.guitar_container.setVisible(True)
            self.view_mode_btn.setText("🎸 视图: 仅吉他指板")
        else:
            self.piano_container.setVisible(True)
            self.guitar_container.setVisible(True)
            self.view_mode_btn.setText("🎹+🎸 视图: 双乐器对照")

    def toggle_progression_window(self):
        if self.prog_studio.isVisible():
            self.prog_studio.hide()
        else:
            self.prog_studio.apply_theme(self.is_dark_theme)
            self.prog_studio.show()
            self.prog_studio.raise_()
            self.prog_studio.activateWindow()

    def open_audio_settings(self):
        dlg = AudioSettingsDialog(self.play_settings, self, is_dark=self.is_dark_theme)
        if dlg.exec_():
            self.play_settings = dlg.get_settings()
            self.save_audio_settings()

            # 即时应用高亮色彩方案到钢琴与吉他指板（彻底独立分开）
            if 'piano_color_scheme' in self.play_settings:
                self.piano_view.set_color_scheme(self.play_settings['piano_color_scheme'])
            elif 'color_scheme' in self.play_settings:
                self.piano_view.set_color_scheme(self.play_settings['color_scheme'])

            if 'guitar_color_scheme' in self.play_settings:
                self.guitar_view.set_color_scheme(self.play_settings['guitar_color_scheme'])
            elif 'color_scheme' in self.play_settings:
                self.guitar_view.set_color_scheme(self.play_settings['color_scheme'])

            if hasattr(self, 'quick_timbre_combo') and hasattr(self, 'quick_mode_combo'):
                self.quick_timbre_combo.blockSignals(True)
                self.quick_mode_combo.blockSignals(True)
                self.quick_timbre_combo.setCurrentText(self.play_settings.get('timbre', 'Grand Piano'))
                self.quick_mode_combo.setCurrentText(self.play_settings.get('mode', 'Simultaneous'))
                self.quick_timbre_combo.blockSignals(False)
                self.quick_mode_combo.blockSignals(False)

            self.guitar_view.set_highlight_root(self.play_settings.get('highlight_guitar_root', True))
            self.guitar_view.set_octave_fade_opacity(self.play_settings.get('guitar_octave_fade_opacity', 0.38))

            # 即时应用调式音阶列表显示密度
            if hasattr(self, 'scales_list'):
                self.scales_list.apply_density(self.play_settings.get('scales_list_density', 'compact'))

    def on_quick_timbre_changed(self, timbre_name):
        self.play_settings['timbre'] = timbre_name
        self.save_audio_settings()

    def on_quick_mode_changed(self, mode_name):
        self.play_settings['mode'] = mode_name
        self.save_audio_settings()

    def on_single_piano_key_pressed(self, abs_idx):
        self.synth.play_single_key(abs_idx, self.play_settings)

    def on_guitar_fret_clicked(self, abs_idx, note_name):
        self.synth.play_single_key(abs_idx, self.play_settings)

        if 0 <= abs_idx < len(self.piano_view.active_keys):
            self.piano_view.active_keys[abs_idx] = not self.piano_view.active_keys[abs_idx]
            self.piano_view.update()
            self.refresh_analysis_from_piano()

    def on_search_preset_chord(self):
        """右上角下拉菜单检索：保持最基础的严格原位排列"""
        root = self.root_combo.currentData()
        chord_type = self.type_combo.currentData()
        if not root or not chord_type:
            return
        notes = get_chord_notes(root, chord_type)
        if notes:
            self.apply_notes_to_instruments(notes, strategy="Strict Root", play=True)

    def on_circle_key_selected(self, key_name, is_minor):
        mode_name = "Aeolian (自然小调 Minor)" if is_minor else "Ionian (自然大调 Major)"
        self.apply_scale_selection(key_name, mode_name)

    def on_harmonic_matrix_scale_changed(self, root, mode):
        if not root or not mode:
            self.clear_scale_selection()
            return
        self.apply_scale_selection(root, mode, update_matrix=False)

    def on_harmonic_matrix_chord_triggered(self, notes, chord_name, chord_root, chord_type):
        """点击和弦块：应用选定的声部连接策略（如平滑诱导/主和弦最低基准）"""
        self._sync_chord_dropdowns(chord_root, chord_type)
        strategy = self.play_settings.get('voicing_strategy', 'Voice-Leading Guided')
        prev_idx = self.piano_view.get_active_indices()
        self.apply_notes_to_instruments(notes, strategy=strategy, previous_indices=prev_idx, play=True)

    def on_scale_item_clicked(self, item):
        if not item:
            return

        data = item.data(Qt.UserRole)
        if not data or not isinstance(data, dict) or 'root' not in data or not data['root']:
            return

        root = data['root']
        mode = data['mode']
        roman = data.get('degree', '')

        self.apply_scale_selection(root, mode, highlight_roman=roman)

    def apply_scale_selection(self, root_name, mode_name, highlight_roman=None, update_matrix=True):
        self.current_scale_root = root_name
        self.current_scale_mode = mode_name

        scale_key = f"{root_name} {mode_name}"
        if scale_key in self.all_scales:
            scale_notes = self.all_scales[scale_key]
            scale_pcs = set()
            for n in scale_notes:
                pc = note_name_to_pitch_class(normalize_note_name(n))
                if pc is not None:
                    scale_pcs.add(pc)
            self.current_scale_pitch_classes = scale_pcs
        else:
            self.current_scale_pitch_classes = set()

        self.piano_view.set_scale_pitch_classes(self.current_scale_pitch_classes)
        self.guitar_view.set_scale_pitch_classes(self.current_scale_pitch_classes)
        self.circle_widget.set_current_key(root_name, is_minor=('Minor' in mode_name or 'Aeolian' in mode_name))

        if update_matrix:
            self.harmonic_matrix.set_mode(root_name, mode_name, highlight_roman=highlight_roman)

    def clear_scale_selection(self):
        self.current_scale_root = ""
        self.current_scale_mode = ""
        self.current_scale_pitch_classes = set()
        self.piano_view.set_scale_pitch_classes(set())
        self.guitar_view.set_scale_pitch_classes(set())
        self.harmonic_matrix.set_blank()

    def on_progression_chord_preview(self, notes, label):
        strategy = self.play_settings.get('voicing_strategy', 'Voice-Leading Guided')
        prev_idx = self.piano_view.get_active_indices()
        self.apply_notes_to_instruments(notes, strategy=strategy, previous_indices=prev_idx, play=True)

    def add_current_to_progression(self):
        active_notes = self.piano_view.get_active_notes()
        if not active_notes:
            QMessageBox.information(self, "提示", "请先在钢琴键盘或吉他指板上选音。")
            return
        label = self.chord_display_label.text().split('(')[0].strip()
        if label in ["None", "未知和弦 (Unknown)"]:
            label = "Custom Chord"
        self.prog_studio.add_chord(active_notes, label=label, beats=2)
        if not self.prog_studio.isVisible():
            self.prog_studio.apply_theme(self.is_dark_theme)
            self.prog_studio.show()

    def apply_notes_to_instruments(self, notes, strategy=None, previous_indices=None, play=True):
        self._is_updating_ui = True
        try:
            if strategy is None:
                strategy = self.play_settings.get('voicing_strategy', 'Voice-Leading Compact')

            self.voice_leading_step_count += 1
            interval = int(self.play_settings.get('contraction_interval', 4))

            self.piano_view.set_active_notes(
                notes,
                scale_root=self.current_scale_root,
                strategy=strategy,
                previous_indices=previous_indices,
                step_count=self.voice_leading_step_count,
                contraction_interval=interval
            )
            self._update_analysis_and_scales_list()
        finally:
            self._is_updating_ui = False

        if play:
            self.play_current_selection()

    def clear_all_selection(self):
        self.voice_leading_step_count = 0
        self.piano_view.clear_all()
        self.guitar_view.clear()
        self.chord_display_label.setText("None")
        self.chord_notes_label.setText("—")
        self._sync_chord_dropdowns("", "")
        self.clear_scale_selection()
        self.scales_tip_label.setText("💡 当前未选音，展示全部调式音阶:")
        self._populate_all_scales_list()

    def refresh_analysis_from_piano(self):
        if self._is_updating_ui:
            return
        self._update_analysis_and_scales_list()

    def _sync_chord_dropdowns(self, root_name, chord_type_name):
        self.root_combo.blockSignals(True)
        self.type_combo.blockSignals(True)

        if not root_name or not chord_type_name:
            self.root_combo.setCurrentIndex(0)
            self.type_combo.setCurrentIndex(0)
        else:
            clean_root = root_name.split('/')[0]
            found_r = False
            for i in range(1, self.root_combo.count()):
                val = self.root_combo.itemData(i)
                if clean_root in val.split('/'):
                    self.root_combo.setCurrentIndex(i)
                    found_r = True
                    break
            if not found_r:
                self.root_combo.setCurrentIndex(0)

            found_t = False
            for i in range(1, self.type_combo.count()):
                val = self.type_combo.itemData(i)
                if val == chord_type_name:
                    self.type_combo.setCurrentIndex(i)
                    found_t = True
                    break
            if not found_t:
                for i in range(1, self.type_combo.count()):
                    val = self.type_combo.itemData(i)
                    if chord_type_name in val or val in chord_type_name:
                        self.type_combo.setCurrentIndex(i)
                        found_t = True
                        break
            if not found_t:
                self.type_combo.setCurrentIndex(0)

        self.root_combo.blockSignals(False)
        self.type_combo.blockSignals(False)

    def _update_analysis_and_scales_list(self):
        active_indices = self.piano_view.get_active_indices()
        if not active_indices:
            self.chord_display_label.setText("None")
            self.chord_notes_label.setText("—")
            self.guitar_view.set_chord_notes([], exact_indices=[])
            self.scales_tip_label.setText("💡 当前未选音，展示全部调式音阶:")
            self._populate_all_scales_list()
            return

        active_notes = self.piano_view.get_active_notes()
        struct_info = analyze_chord_structure(active_indices)
        chord_name = struct_info['name']

        self.chord_display_label.setText(chord_name)
        self.chord_notes_label.setText(" ".join([n.split('/')[0] for n in active_notes]))

        if struct_info['is_valid'] and struct_info['root']:
            self._sync_chord_dropdowns(struct_info['root'], struct_info['type'])
            self.guitar_view.set_chord_notes(active_notes, root_note=struct_info['root'], exact_indices=active_indices)
        else:
            self._sync_chord_dropdowns("", "")
            self.guitar_view.set_chord_notes(active_notes, root_note=None, exact_indices=active_indices)

        if self.current_scale_pitch_classes:
            chord_pcs = set()
            for idx in active_indices:
                info = self.piano_view.key_info[idx]
                chord_pcs.add(info['pitch_class'])

            if not chord_pcs.issubset(self.current_scale_pitch_classes):
                self.clear_scale_selection()

        self.scales_list.clear()
        unique_notes = list(dict.fromkeys(active_notes))

        matched_scales = []
        for scale_key, scale_notes in self.all_scales.items():
            if all(n in scale_notes for n in unique_notes):
                parts = scale_key.split(" ")
                s_root = parts[0]
                s_mode = " ".join(parts[1:])
                
                roman_list = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII']
                degree_str = ""
                if unique_notes[0] in scale_notes:
                    d_idx = scale_notes.index(unique_notes[0])
                    if d_idx < 7:
                        degree_str = roman_list[d_idx]

                matched_scales.append({
                    'key': scale_key,
                    'root': s_root,
                    'mode': s_mode,
                    'degree': degree_str
                })

        if not matched_scales:
            self.scales_tip_label.setText("⚠️ 未找到包含当前全部选音的调式音阶")
            warn_item = QListWidgetItem("（当前音符组合不存在于任何常规调式中）")
            warn_item.setForeground(QColor("#ef4444"))
            warn_item.setFlags(Qt.NoItemFlags)
            self.scales_list.addItem(warn_item)
            return

        self.scales_tip_label.setText(f"🎯 匹配到 {len(matched_scales)} 个调式音阶:")

        if self.scale_sort_mode == 1:
            mode_groups = {}
            for item_data in matched_scales:
                mode_groups.setdefault(item_data['mode'], []).append(item_data)

            for mode_name, items in mode_groups.items():
                header = QListWidgetItem(f"== 🎼 {mode_name} ==")
                c_hex = MODE_COLORS.get(mode_name, "#f59e0b")
                header.setForeground(QColor(c_hex))
                header.setFont(QFont("Segoe UI", self.scales_list.font_size, QFont.Bold))
                header.setFlags(Qt.NoItemFlags)
                self.scales_list.addItem(header)

                for it in items:
                    display_text = f"   {it['root']:<6} 顺阶级数: {it['degree']:<4}"
                    list_item = QListWidgetItem(display_text)
                    list_item.setData(Qt.UserRole, {'root': it['root'], 'mode': it['mode'], 'degree': it['degree']})
                    list_item.setForeground(QColor(c_hex))
                    list_item.setFont(QFont("Consolas", self.scales_list.font_size, QFont.Bold))
                    self.scales_list.addItem(list_item)
        else:
            # 按主音分组 (Group by Root)
            root_groups = {}
            for item_data in matched_scales:
                root_groups.setdefault(item_data['root'], []).append(item_data)

            for root_name, items in root_groups.items():
                header = QListWidgetItem(f"== 🎵 {root_name} 主音调式 ==")
                root_hdr_color = QColor("#ffffff") if self.is_dark_theme else QColor("#0f172a")
                header.setForeground(root_hdr_color)
                header.setFont(QFont("Segoe UI", self.scales_list.font_size, QFont.Bold))
                header.setFlags(Qt.NoItemFlags)
                self.scales_list.addItem(header)

                for it in items:
                    mode_clean = it['mode'].split('(')[0].strip()
                    display_text = f"   {mode_clean:<18} 顺阶级数: {it['degree']:<4}"
                    list_item = QListWidgetItem(display_text)
                    list_item.setData(Qt.UserRole, {'root': it['root'], 'mode': it['mode'], 'degree': it['degree']})
                    c_hex = MODE_COLORS.get(it['mode'], "#38bdf8")
                    list_item.setForeground(QColor(c_hex))
                    list_item.setFont(QFont("Consolas", self.scales_list.font_size, QFont.Bold))
                    self.scales_list.addItem(list_item)

    def _populate_all_scales_list(self):
        self.scales_list.clear()

        if self.scale_sort_mode == 1:
            for mode_name in MODES.keys():
                header = QListWidgetItem(f"== 🎼 {mode_name} ==")
                c_hex = MODE_COLORS.get(mode_name, "#f59e0b")
                header.setForeground(QColor(c_hex))
                header.setFont(QFont("Segoe UI", self.scales_list.font_size, QFont.Bold))
                header.setFlags(Qt.NoItemFlags)
                self.scales_list.addItem(header)

                for root in NOTE_NAMES:
                    display_text = f"   {root:<6}"
                    list_item = QListWidgetItem(display_text)
                    list_item.setData(Qt.UserRole, {'root': root, 'mode': mode_name, 'degree': ''})
                    list_item.setForeground(QColor(c_hex))
                    list_item.setFont(QFont("Consolas", self.scales_list.font_size, QFont.Bold))
                    self.scales_list.addItem(list_item)
        else:
            # 默认展示：按主音分组
            for root in NOTE_NAMES:
                header = QListWidgetItem(f"== 🎵 {root} 主音调式 ==")
                root_hdr_color = QColor("#ffffff") if self.is_dark_theme else QColor("#0f172a")
                header.setForeground(root_hdr_color)
                header.setFont(QFont("Segoe UI", self.scales_list.font_size, QFont.Bold))
                header.setFlags(Qt.NoItemFlags)
                self.scales_list.addItem(header)

                for mode_name in MODES.keys():
                    mode_clean = mode_name.split(' ')[0]
                    display_text = f"   {mode_clean:<14}"
                    list_item = QListWidgetItem(display_text)
                    list_item.setData(Qt.UserRole, {'root': root, 'mode': mode_name, 'degree': ''})
                    color_hex = MODE_COLORS.get(mode_name, "#94a3b8")
                    list_item.setForeground(QColor(color_hex))
                    list_item.setFont(QFont("Consolas", self.scales_list.font_size, QFont.Bold))
                    self.scales_list.addItem(list_item)

    def play_current_selection(self):
        active_indices = self.piano_view.get_active_indices()
        if not active_indices:
            return
        self.synth.play_chord(active_indices, self.play_settings)

    def save_full_ui_state(self):
        """全面保存用户上一次退出的全部配置与所有下拉菜单状态"""
        try:
            # 1. 窗口几何与布局 (仅在尺寸合法且非最小化时保存，绝不将无头或异常尺寸写入)
            if not self.isMinimized() and self.width() >= 1180 and self.height() >= 700:
                self.settings_store.setValue("main_window_geometry", self.saveGeometry())
            self.settings_store.setValue("workspace_splitter_state", self.workspace_splitter.saveState())
            self.settings_store.setValue("is_dark_theme", self.is_dark_theme)
            self.settings_store.setValue("instrument_view_mode", self.current_view_mode)

            # 2. 左侧面板状态
            self.settings_store.setValue("left_tab_index", self.left_tabs.currentIndex())
            self.settings_store.setValue("scale_sort_mode", self.scale_sort_mode)
            if hasattr(self, 'scales_list'):
                d = getattr(self.scales_list, 'density_mode', 'compact')
                self.play_settings['scales_list_density'] = d
                self.settings_store.setValue("scales_list_density", d)
                self.settings_store.setValue("scales_list_font_size", getattr(self.scales_list, 'font_size', 11))

            # 3. 和弦快速检索下拉框状态 (Search Card)
            self.settings_store.setValue("search_chord_root", self.root_combo.currentText())
            self.settings_store.setValue("search_chord_type_data", self.type_combo.currentData())

            # 4. 调式顺阶和声矩阵下拉框状态 (Harmonic Matrix)
            if hasattr(self, 'harmonic_matrix'):
                self.settings_store.setValue("matrix_root", self.harmonic_matrix.root_combo.currentText())
                self.settings_store.setValue("matrix_mode", self.harmonic_matrix.mode_combo.currentText())
                self.settings_store.setValue("matrix_depth_idx", self.harmonic_matrix.depth_combo.currentIndex())

            # 5. 右下角快捷下拉框与音频配置
            self.play_settings['timbre'] = self.quick_timbre_combo.currentText()
            self.play_settings['mode'] = self.quick_mode_combo.currentText()
            self.save_audio_settings()

            # 6. 当前选中的调式与琴键激活音符
            self.settings_store.setValue("current_scale_root", self.current_scale_root)
            self.settings_store.setValue("current_scale_mode", self.current_scale_mode)
            self.settings_store.setValue("piano_active_indices", list(self.piano_view.get_active_indices()))

            # 7. 和弦进行工坊全部状态与正在编排的数据
            if hasattr(self, 'prog_studio'):
                self.settings_store.setValue("prog_studio_geometry", self.prog_studio.saveGeometry())
                self.settings_store.setValue("prog_studio_bpm", self.prog_studio.bpm_spin.value())
                self.settings_store.setValue("prog_studio_loop", self.prog_studio.loop_check.isChecked())
                self.settings_store.setValue("prog_studio_visible", self.prog_studio.isVisible())
                try:
                    prog_data = self.prog_studio.get_progression_data()
                    self.settings_store.setValue("prog_studio_chords_json", json.dumps(prog_data))
                except Exception as e:
                    print(f"Save progression data error: {e}")
        except Exception as e:
            print(f"Error saving UI state: {e}")

    def restore_full_ui_state(self):
        """启动时全面恢复用户上一次退出的全部配置与所有下拉菜单状态"""
        try:
            # 1. 恢复主窗口尺寸与屏幕位置 (带异常尺寸与左上角挤压兜底防御)
            geom = self.settings_store.value("main_window_geometry")
            restored_ok = False
            if geom:
                restored_ok = bool(self.restoreGeometry(geom))
            if not restored_ok or self.width() < 1180 or self.height() < 700 or (self.x() <= 0 and self.y() <= 0):
                self.center_on_screen()

            # 2. 恢复工作区左右分割器两栏比例
            splitter_state = self.settings_store.value("workspace_splitter_state")
            if splitter_state:
                self.workspace_splitter.restoreState(splitter_state)

            # 3. 恢复左侧选项卡标签分页
            saved_tab = self.settings_store.value("left_tab_index", 0, type=int)
            if 0 <= saved_tab < self.left_tabs.count():
                self.left_tabs.setCurrentIndex(saved_tab)

            # 4. 恢复调式音阶列表字号与密度
            if hasattr(self, 'scales_list'):
                saved_density = self.settings_store.value("scales_list_density", "compact")
                self.play_settings['scales_list_density'] = saved_density
                self.scales_list.apply_density(saved_density)
                saved_font = self.settings_store.value("scales_list_font_size", 0, type=int)
                if saved_font > 0:
                    self.scales_list.font_size = saved_font
                    self.scales_list.apply_font()

            # 5. 恢复调式顺阶和声矩阵中的 3 个下拉框状态
            if hasattr(self, 'harmonic_matrix'):
                saved_m_root = self.settings_store.value("matrix_root", "")
                if saved_m_root:
                    for i in range(self.harmonic_matrix.root_combo.count()):
                        t = self.harmonic_matrix.root_combo.itemText(i)
                        if saved_m_root == t or saved_m_root in t.split('/'):
                            self.harmonic_matrix.root_combo.setCurrentIndex(i)
                            break

                saved_m_mode = self.settings_store.value("matrix_mode", "")
                if saved_m_mode:
                    for i in range(self.harmonic_matrix.mode_combo.count()):
                        t = self.harmonic_matrix.mode_combo.itemText(i)
                        if saved_m_mode == t or saved_m_mode in t or t in saved_m_mode:
                            self.harmonic_matrix.mode_combo.setCurrentIndex(i)
                            break

                saved_m_depth = self.settings_store.value("matrix_depth_idx", 0, type=int)
                if 0 <= saved_m_depth < self.harmonic_matrix.depth_combo.count():
                    self.harmonic_matrix.depth_combo.setCurrentIndex(saved_m_depth)

                if self.harmonic_matrix.root_combo.currentData() and self.harmonic_matrix.mode_combo.currentData():
                    self.harmonic_matrix.refresh_harmonics()

            # 7. 恢复当前选中的调式
            saved_scale_root = self.settings_store.value("current_scale_root", "")
            saved_scale_mode = self.settings_store.value("current_scale_mode", "")
            if saved_scale_root and saved_scale_mode:
                self.apply_scale_selection(saved_scale_root, saved_scale_mode)

            # 8. 恢复钢琴键盘上的选音激活状态（如果有）
            saved_notes = self.settings_store.value("piano_active_indices", [])
            if saved_notes and isinstance(saved_notes, list):
                int_notes = [int(x) for x in saved_notes if str(x).isdigit()]
                if int_notes:
                    self.piano_view.set_active_indices(int_notes)
                    self.refresh_analysis_from_piano()

            # 9. 恢复和弦快速检索栏的两个下拉框状态 (Search Card)
            saved_search_root = self.settings_store.value("search_chord_root", "")
            if saved_search_root:
                idx = self.root_combo.findText(saved_search_root)
                if idx >= 0:
                    self.root_combo.setCurrentIndex(idx)

            saved_search_type = self.settings_store.value("search_chord_type_data", "")
            if saved_search_type:
                idx = self.type_combo.findData(saved_search_type)
                if idx >= 0:
                    self.type_combo.setCurrentIndex(idx)

            # 10. 恢复和弦进行工坊全部状态
            if hasattr(self, 'prog_studio'):
                prog_geom = self.settings_store.value("prog_studio_geometry")
                if prog_geom:
                    self.prog_studio.restoreGeometry(prog_geom)

                saved_bpm = self.settings_store.value("prog_studio_bpm", 120, type=int)
                self.prog_studio.bpm_spin.setValue(saved_bpm)

                saved_loop = self.settings_store.value("prog_studio_loop", True, type=bool)
                self.prog_studio.loop_check.setChecked(saved_loop)

                chords_json = self.settings_store.value("prog_studio_chords_json", "")
                if chords_json:
                    try:
                        data = json.loads(chords_json) if isinstance(chords_json, str) else chords_json
                        if data and isinstance(data, list):
                            self.prog_studio.set_progression_data(data)
                    except Exception as e:
                        print(f"Restore progression error: {e}")

                saved_prog_vis = self.settings_store.value("prog_studio_visible", False, type=bool)
                if saved_prog_vis:
                    self.prog_studio.show()

            # 11. 重新应用并刷新钢琴与吉他的调色方案
            if 'piano_color_scheme' in self.play_settings:
                self.piano_view.set_color_scheme(self.play_settings['piano_color_scheme'])
                self.piano_view.update()
            if 'guitar_color_scheme' in self.play_settings:
                self.guitar_view.set_color_scheme(self.play_settings['guitar_color_scheme'])
                self.guitar_view.set_octave_fade_opacity(self.play_settings.get('guitar_octave_fade_opacity', 0.38))
                self.guitar_view.update()
        except Exception as e:
            print(f"Error restoring UI state: {e}")

    def closeEvent(self, event):
        self.save_full_ui_state()
        self.synth.stop()
        self.synth.close()
        self.prog_studio.close()
        super().closeEvent(event)


def main():
    if sys.platform == 'win32':
        import ctypes
        try:
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("TaketoAudio.Chordior.App")
        except Exception:
            pass

    if hasattr(Qt, 'AA_EnableHighDpiScaling'):
        QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    if hasattr(Qt, 'AA_UseHighDpiPixmaps'):
        QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)

    app = QApplication(sys.argv)
    app.setApplicationName("Chordior")
    app.setStartDragDistance(15)

    # 设置应用全局图标 (任务栏与全部对话框继承)
    for icon_candidate in ["app_icon.ico", "icon_concepts/icon.png", "钢琴.ico"]:
        full_path = resource_path(icon_candidate)
        if os.path.exists(full_path):
            app.setWindowIcon(QIcon(full_path))
            break

    window = ChordStudioMainWindow()
    window.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
