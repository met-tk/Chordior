"""
Audio Settings Dialog - 音频合成与演奏高级设置对话框
支持音色、演奏模式、琶音、音量、八度移调、吉他根音高亮、和弦排列策略、
以及【钢琴键盘与吉他指板独立自定义调色方案】。
已彻底剔除失效的“开放声部排列 (Open Voicing)”选项。
"""

from PyQt5.QtCore import Qt
from PyQt5.QtGui import QColor
from PyQt5.QtWidgets import (QCheckBox, QComboBox, QDialog,
                             QFormLayout, QFrame, QHBoxLayout, QLabel,
                             QPushButton, QSlider, QVBoxLayout)
from color_picker_dialog import StudioColorPickerDialog

# 常用精选预设 (一键快速配置协调配色)
COORDINATED_PRESETS = {
    "默认电光蓝与象牙白 (Electric Blue & Ivory)": {
        'piano': {'black_chord_color': '#ffffff', 'white_chord_color': '#38bdf8', 'scale_color': '#0ea5e9', 'both_accent_color': '#f59e0b'},
        'guitar': {'chord_color': '#38bdf8', 'scale_color': '#0ea5e9', 'both_accent_color': '#f59e0b', 'root_color': '#f97316'}
    },
    "璀璨金黄与宝石蓝宝 (Sapphire & Imperial Gold)": {
        'piano': {'black_chord_color': '#facc15', 'white_chord_color': '#0284c7', 'scale_color': '#38bdf8', 'both_accent_color': '#f97316'},
        'guitar': {'chord_color': '#facc15', 'scale_color': '#0284c7', 'both_accent_color': '#f97316', 'root_color': '#ef4444'}
    },
    "赛博霓虹粉与薄荷绿 (Cyberpunk Mint & Neon Pink)": {
        'piano': {'black_chord_color': '#f43f5e', 'white_chord_color': '#10b981', 'scale_color': '#8b5cf6', 'both_accent_color': '#eab308'},
        'guitar': {'chord_color': '#f43f5e', 'scale_color': '#8b5cf6', 'both_accent_color': '#eab308', 'root_color': '#06b6d4'}
    },
    "独立个性化自定义 (Custom Studio Palette)": None
}


class AudioSettingsDialog(QDialog):
    """高级设置中心对话框 (支持钢琴与吉他独立自定义调色)"""

    def __init__(self, settings, parent=None, is_dark=False):
        super().__init__(parent)
        self.setWindowTitle("⚙ 高级设置中心 (Audio & Color Settings)")
        self.setFixedSize(540, 650)
        self.settings = dict(settings)
        if parent and hasattr(parent, 'is_dark_theme'):
            self.is_dark = parent.is_dark_theme
        else:
            self.is_dark = is_dark
        self._init_colors()
        self.init_ui()

    def _init_colors(self):
        # 1. 钢琴键盘配色
        p_scheme = self.settings.get('piano_color_scheme') or self.settings.get('color_scheme', {})
        self.curr_piano_black = p_scheme.get('black_chord_color', '#ffffff')
        self.curr_piano_white = p_scheme.get('white_chord_color', '#38bdf8')
        self.curr_piano_scale = p_scheme.get('scale_color', '#0ea5e9')
        self.curr_piano_both = p_scheme.get('both_accent_color', '#f59e0b')

        # 2. 吉他指板配色
        g_scheme = self.settings.get('guitar_color_scheme') or self.settings.get('color_scheme', {})
        self.curr_guitar_chord = g_scheme.get('chord_color', g_scheme.get('white_chord_color', '#38bdf8'))
        self.curr_guitar_scale = g_scheme.get('scale_color', '#0ea5e9')
        self.curr_guitar_both = g_scheme.get('both_accent_color', '#f59e0b')
        self.curr_guitar_root = g_scheme.get('root_color', '#f97316')

        self.curr_preset = self.settings.get('color_preset_name', "默认电光蓝与象牙白 (Electric Blue & Ivory)")

    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 14, 20, 14)
        layout.setSpacing(8)

        form = QFormLayout()
        form.setSpacing(6)

        # 1. 和弦排列与声部连接策略 (新增 Voice-Leading Compact 紧凑周期收缩策略)
        self.voicing_combo = QComboBox()
        self.voicing_combo.setMaxVisibleItems(15)
        self.voicing_combo.addItems([
            "Voice-Leading Compact (平滑紧凑+周期收缩回归 - 推荐)",
            "Voice-Leading Guided (上一和弦平滑诱导)",
            "Tonic-Root Base (主和弦最低基准 - I级最沉稳)",
            "Key-Anchored (调式主音锚定阶梯排列)",
            "Strict Root (严格原位基础排列)"
        ])
        curr_voicing = self.settings.get('voicing_strategy', 'Voice-Leading Compact')
        for i in range(self.voicing_combo.count()):
            if curr_voicing in self.voicing_combo.itemText(i):
                self.voicing_combo.setCurrentIndex(i)
                break
        form.addRow("🎼 声部连接策略 (Voicing):", self.voicing_combo)

        # 1.1 声部向心收缩周期 (仅在 Voice-Leading Compact 时联动显示)
        self.interval_label = QLabel("🌀 声部收缩周期:")
        self.interval_combo = QComboBox()
        self.interval_combo.setMaxVisibleItems(10)
        self.interval_options = [
            ("每 4 次和弦 (4 Chords - 流行黄金律动 / 推荐)", 4),
            ("每 3 次和弦 (3 Chords - 快速向心收缩)", 3),
            ("每 6 次和弦 (6 Chords - 扩展过渡进行)", 6),
            ("每 8 次和弦 (8 Chords - 长乐句自然回归)", 8)
        ]
        for text, val in self.interval_options:
            self.interval_combo.addItem(text, val)
        curr_interval = int(self.settings.get('contraction_interval', 4))
        for i in range(self.interval_combo.count()):
            if self.interval_combo.itemData(i) == curr_interval:
                self.interval_combo.setCurrentIndex(i)
                break
        form.addRow(self.interval_label, self.interval_combo)

        self.voicing_combo.currentIndexChanged.connect(self._update_interval_visibility)

        # 2. 音色选择
        self.timbre_combo = QComboBox()
        self.timbre_combo.setMaxVisibleItems(15)
        self.timbre_combo.addItems([
            "Grand Piano (三角大钢琴)",
            "Electric Piano (温暖电钢琴 Rhodes)",
            "Synth Pad (梦幻氛围合成器)",
            "Pure Sine (纯正弦波)"
        ])
        curr_timbre = self.settings.get('timbre', 'Grand Piano')
        for i in range(self.timbre_combo.count()):
            if curr_timbre in self.timbre_combo.itemText(i):
                self.timbre_combo.setCurrentIndex(i)
                break
        form.addRow("🎹 发声音色 (Timbre):", self.timbre_combo)

        # 3. 演奏模式
        self.mode_combo = QComboBox()
        self.mode_combo.setMaxVisibleItems(15)
        self.mode_combo.addItems([
            "Simultaneous (柱式齐奏)",
            "Pop Strum (流行轻扫弦)",
            "Arpeggio (分解琶音)"
        ])
        curr_mode = self.settings.get('mode', 'Simultaneous')
        for i in range(self.mode_combo.count()):
            if curr_mode in self.mode_combo.itemText(i):
                self.mode_combo.setCurrentIndex(i)
                break
        form.addRow("🎵 演奏模式 (Mode):", self.mode_combo)

        # 4. 琶音方向
        self.pattern_combo = QComboBox()
        self.pattern_combo.setMaxVisibleItems(15)
        self.pattern_combo.addItems(["Up (上行)", "Down (下行)", "Up-Down (上下往复)"])
        curr_pattern = self.settings.get('pattern', 'Up')
        for i in range(self.pattern_combo.count()):
            if curr_pattern in self.pattern_combo.itemText(i):
                self.pattern_combo.setCurrentIndex(i)
                break
        form.addRow("🔄 琶音方向 (Arp Pattern):", self.pattern_combo)

        # 5. 琶音速度
        self.speed_slider = QSlider(Qt.Horizontal)
        self.speed_slider.setRange(5, 40)
        self.speed_slider.setValue(int(self.settings.get('speed', 0.12) * 100))
        self.speed_label = QLabel(f"{self.speed_slider.value() * 10} ms")
        self.speed_slider.valueChanged.connect(lambda v: self.speed_label.setText(f"{v * 10} ms"))
        speed_box = QHBoxLayout()
        speed_box.addWidget(self.speed_slider)
        speed_box.addWidget(self.speed_label)
        form.addRow("⚡ 琶音间隔 (Arp Speed):", speed_box)

        # 6. 主音量
        self.vol_slider = QSlider(Qt.Horizontal)
        self.vol_slider.setRange(0, 100)
        self.vol_slider.setValue(int(self.settings.get('volume', 0.85) * 100))
        self.vol_label = QLabel(f"{self.vol_slider.value()}%")
        self.vol_slider.valueChanged.connect(lambda v: self.vol_label.setText(f"{v}%"))
        vol_box = QHBoxLayout()
        vol_box.addWidget(self.vol_slider)
        vol_box.addWidget(self.vol_label)
        form.addRow("🔊 主音量 (Master Vol):", vol_box)

        # 7. 八度移调
        self.octave_combo = QComboBox()
        self.octave_combo.setMaxVisibleItems(15)
        self.octave_options = [
            ("+2 (高两个八度 / +2 Octaves)", 2),
            ("+1 (高一个八度 / +1 Octave)", 1),
            ("0 (标准基准 / 原调中央八度)", 0),
            ("-1 (低一个八度 / -1 Octave)", -1),
            ("-2 (低两个八度 / -2 Octaves)", -2)
        ]
        for text, val in self.octave_options:
            self.octave_combo.addItem(text, val)

        curr_oct = int(self.settings.get('octave_shift', 0))
        for i in range(self.octave_combo.count()):
            if self.octave_combo.itemData(i) == curr_oct:
                self.octave_combo.setCurrentIndex(i)
                break
        form.addRow("🌐 八度移调 (Pitch Shift):", self.octave_combo)

        # 8. 调式列表行高与显示密度
        self.density_combo = QComboBox()
        self.density_combo.setMaxVisibleItems(10)
        self.density_options = [
            ("紧凑高密 (Compact - 默认推荐，同屏容纳更多)", "compact"),
            ("极度极密 (Ultra-Dense - 显示行数最多)", "ultra"),
            ("舒适宽松 (Comfortable - 字体稍大间隔宽)", "comfortable")
        ]
        for text, val in self.density_options:
            self.density_combo.addItem(text, val)
        curr_density = self.settings.get('scales_list_density', 'compact')
        for i in range(self.density_combo.count()):
            if self.density_combo.itemData(i) == curr_density:
                self.density_combo.setCurrentIndex(i)
                break
        form.addRow("📋 列表行高与密度 (Density):", self.density_combo)

        # 8. 吉他指板设置
        self.highlight_root_check = QCheckBox("吉他指板特殊高亮和弦根音 (Highlight Root Note)")
        self.highlight_root_check.setChecked(bool(self.settings.get('highlight_guitar_root', True)))
        form.addRow("", self.highlight_root_check)

        # 8.1 吉他指板其他八度淡化透光率滑块 (15% ~ 100%，100%为全量不淡化)
        self.octave_fade_slider = QSlider(Qt.Horizontal)
        self.octave_fade_slider.setRange(15, 100)
        curr_fade_val = int(round(float(self.settings.get('guitar_octave_fade_opacity', 0.38)) * 100))
        self.octave_fade_slider.setValue(curr_fade_val)

        def format_fade_label(v):
            return "100% (全亮)" if v >= 98 else f"{v}%"

        self.octave_fade_label = QLabel(format_fade_label(curr_fade_val))
        self.octave_fade_label.setFixedWidth(75)
        self.octave_fade_slider.valueChanged.connect(lambda v: self.octave_fade_label.setText(format_fade_label(v)))

        fade_box = QHBoxLayout()
        fade_box.addWidget(self.octave_fade_slider)
        fade_box.addWidget(self.octave_fade_label)
        form.addRow("🎸 指板音符非八度透明度:", fade_box)

        layout.addLayout(form)

        # 9. 配色预设快速套用下拉
        preset_row = QHBoxLayout()
        preset_lbl = QLabel("🎨 颜色预设:")
        preset_lbl.setStyleSheet("font-weight: bold;")
        self.preset_combo = QComboBox()
        for p_name in COORDINATED_PRESETS.keys():
            self.preset_combo.addItem(p_name)
        found_p = False
        for i in range(self.preset_combo.count()):
            if self.curr_preset in self.preset_combo.itemText(i):
                self.preset_combo.setCurrentIndex(i)
                found_p = True
                break
        if not found_p:
            self.preset_combo.setCurrentIndex(0)
        self.preset_combo.currentIndexChanged.connect(self._on_preset_changed)
        preset_row.addWidget(preset_lbl)
        preset_row.addWidget(self.preset_combo)
        layout.addLayout(preset_row)

        # 10. 独立配色组卡片 (钢琴与吉他彻底分开)
        self.color_card = QFrame()
        if self.is_dark:
            self.color_card.setStyleSheet("background-color: #282c37; border: 1px solid #383d4c; border-radius: 8px; padding: 6px;")
            p_style = "color: #38bdf8; font-weight: bold; font-size: 11px;"
            g_style = "color: #f59e0b; font-weight: bold; font-size: 11px;"
        else:
            self.color_card.setStyleSheet("background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px;")
            p_style = "color: #0369a1; font-weight: bold; font-size: 11px;"
            g_style = "color: #b45309; font-weight: bold; font-size: 11px;"

        color_card_layout = QVBoxLayout(self.color_card)
        color_card_layout.setSpacing(6)

        # 10.1 🎹 钢琴键盘配色行
        p_row = QHBoxLayout()
        p_lbl = QLabel("🎹 钢琴配色:")
        p_lbl.setFixedWidth(78)
        p_lbl.setStyleSheet(p_style)
        p_row.addWidget(p_lbl)

        self.btn_piano_black = QPushButton("黑键高光")
        self.btn_piano_black.clicked.connect(self._pick_piano_black)
        p_row.addWidget(self.btn_piano_black)

        self.btn_piano_white = QPushButton("白键和弦")
        self.btn_piano_white.clicked.connect(self._pick_piano_white)
        p_row.addWidget(self.btn_piano_white)

        self.btn_piano_scale = QPushButton("调式背景音")
        self.btn_piano_scale.clicked.connect(self._pick_piano_scale)
        p_row.addWidget(self.btn_piano_scale)

        self.btn_piano_both = QPushButton("双集合重合")
        self.btn_piano_both.clicked.connect(self._pick_piano_both)
        p_row.addWidget(self.btn_piano_both)

        color_card_layout.addLayout(p_row)

        # 10.2 🎸 吉他指板配色行
        g_row = QHBoxLayout()
        g_lbl = QLabel("🎸 吉他配色:")
        g_lbl.setFixedWidth(78)
        g_lbl.setStyleSheet(g_style)
        g_row.addWidget(g_lbl)

        self.btn_guitar_chord = QPushButton("和弦圆点")
        self.btn_guitar_chord.clicked.connect(self._pick_guitar_chord)
        g_row.addWidget(self.btn_guitar_chord)

        self.btn_guitar_scale = QPushButton("调式圆点")
        self.btn_guitar_scale.clicked.connect(self._pick_guitar_scale)
        g_row.addWidget(self.btn_guitar_scale)

        self.btn_guitar_both = QPushButton("顺阶光环")
        self.btn_guitar_both.clicked.connect(self._pick_guitar_both)
        g_row.addWidget(self.btn_guitar_both)

        self.btn_guitar_root = QPushButton("根音高亮")
        self.btn_guitar_root.clicked.connect(self._pick_guitar_root)
        g_row.addWidget(self.btn_guitar_root)

        color_card_layout.addLayout(g_row)

        layout.addWidget(self.color_card)
        self._update_all_color_buttons()

        # 底部确定/取消按钮与左下角作者来源超链接
        btn_box = QHBoxLayout()

        # 左下角作者来源可点击蓝字链接 (by: taketo)
        link_color = "#38bdf8" if self.is_dark else "#0284c7"
        self.author_link = QLabel(f'<a href="https://space.bilibili.com/24340298" style="color: {link_color}; text-decoration: none; font-size: 12px; font-weight: bold;">AI-driven by: taketo</a>')
        self.author_link.setOpenExternalLinks(True)
        self.author_link.setCursor(Qt.PointingHandCursor)
        self.author_link.setToolTip("访问 Bilibili 空间: https://space.bilibili.com/24340298")
        btn_box.addWidget(self.author_link)

        btn_box.addStretch()

        cancel_btn = QPushButton("取消")
        cancel_btn.clicked.connect(self.reject)
        btn_box.addWidget(cancel_btn)

        save_btn = QPushButton("保存设置")
        save_btn.setObjectName("PrimaryButton")
        save_btn.setStyleSheet("background-color: #0284c7; color: #ffffff; font-weight: bold; padding: 6px 18px; border-radius: 6px;")
        save_btn.clicked.connect(self.accept)
        btn_box.addWidget(save_btn)

        layout.addLayout(btn_box)

        self._update_interval_visibility()

    def _update_interval_visibility(self):
        is_compact = "Voice-Leading Compact" in self.voicing_combo.currentText()
        self.interval_label.setVisible(is_compact)
        self.interval_combo.setVisible(is_compact)

    def _update_all_color_buttons(self):
        def style_btn(btn, hex_code):
            c = QColor(hex_code)
            lum = (c.red() * 299 + c.green() * 587 + c.blue() * 114) / 1000
            fg = "#0f172a" if lum > 135 else "#ffffff"
            btn.setStyleSheet(f"background-color: {hex_code}; color: {fg}; font-weight: bold; border: 1.5px solid #64748b; border-radius: 6px; padding: 5px;")

        # 钢琴
        style_btn(self.btn_piano_black, self.curr_piano_black)
        style_btn(self.btn_piano_white, self.curr_piano_white)
        style_btn(self.btn_piano_scale, self.curr_piano_scale)
        style_btn(self.btn_piano_both, self.curr_piano_both)

        # 吉他
        style_btn(self.btn_guitar_chord, self.curr_guitar_chord)
        style_btn(self.btn_guitar_scale, self.curr_guitar_scale)
        style_btn(self.btn_guitar_both, self.curr_guitar_both)
        style_btn(self.btn_guitar_root, self.curr_guitar_root)

    def _on_preset_changed(self):
        p_text = self.preset_combo.currentText()
        preset_data = COORDINATED_PRESETS.get(p_text)
        if preset_data:
            p_data = preset_data['piano']
            self.curr_piano_black = p_data['black_chord_color']
            self.curr_piano_white = p_data['white_chord_color']
            self.curr_piano_scale = p_data['scale_color']
            self.curr_piano_both = p_data.get('both_accent_color', '#f59e0b')

            g_data = preset_data['guitar']
            self.curr_guitar_chord = g_data['chord_color']
            self.curr_guitar_scale = g_data['scale_color']
            self.curr_guitar_both = g_data['both_accent_color']
            self.curr_guitar_root = g_data['root_color']

            self._update_all_color_buttons()

    def _set_to_custom(self):
        self.preset_combo.blockSignals(True)
        self.preset_combo.setCurrentText("独立个性化自定义 (Custom Studio Palette)")
        self.preset_combo.blockSignals(False)

    # 钢琴取色槽
    def _pick_piano_black(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_piano_black), self, "选择钢琴黑键和弦高亮色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_piano_black = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def _pick_piano_white(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_piano_white), self, "选择钢琴白键和弦高亮色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_piano_white = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def _pick_piano_scale(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_piano_scale), self, "选择钢琴调式背景音高亮色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_piano_scale = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def _pick_piano_both(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_piano_both), self, "选择钢琴调内顺阶双集合发光环颜色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_piano_both = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    # 吉他取色槽
    def _pick_guitar_chord(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_guitar_chord), self, "选择吉他和弦音圆点颜色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_guitar_chord = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def _pick_guitar_scale(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_guitar_scale), self, "选择吉他调式音圆点颜色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_guitar_scale = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def _pick_guitar_both(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_guitar_both), self, "选择吉他调内顺阶双集合发光环颜色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_guitar_both = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def _pick_guitar_root(self):
        col = StudioColorPickerDialog.getColor(QColor(self.curr_guitar_root), self, "选择吉他根音专属高亮颜色", is_dark=self.is_dark)
        if col.isValid():
            self.curr_guitar_root = col.name()
            self._set_to_custom()
            self._update_all_color_buttons()

    def get_settings(self):
        voicing_text = self.voicing_combo.currentText().split('(')[0].strip()
        timbre_text = self.timbre_combo.currentText().split('(')[0].strip()
        mode_text = self.mode_combo.currentText().split('(')[0].strip()
        pattern_text = self.pattern_combo.currentText().split('(')[0].strip()

        piano_scheme = {
            'black_chord_color': self.curr_piano_black,
            'white_chord_color': self.curr_piano_white,
            'scale_color': self.curr_piano_scale,
            'both_accent_color': self.curr_piano_both
        }

        guitar_scheme = {
            'chord_color': self.curr_guitar_chord,
            'scale_color': self.curr_guitar_scale,
            'both_accent_color': self.curr_guitar_both,
            'root_color': self.curr_guitar_root
        }

        return {
            'voicing_strategy': voicing_text,
            'contraction_interval': int(self.interval_combo.currentData() if self.interval_combo.currentData() is not None else 4),
            'timbre': timbre_text,
            'mode': mode_text,
            'pattern': pattern_text,
            'speed': self.speed_slider.value() / 100.0,
            'volume': self.vol_slider.value() / 100.0,
            'octave_shift': int(self.octave_combo.currentData() if self.octave_combo.currentData() is not None else 0),
            'highlight_guitar_root': self.highlight_root_check.isChecked(),
            'guitar_octave_fade_opacity': self.octave_fade_slider.value() / 100.0,
            'distinguish_guitar_octaves': (self.octave_fade_slider.value() < 98),
            'scales_list_density': self.density_combo.currentData() if self.density_combo.currentData() else 'compact',
            'color_preset_name': self.preset_combo.currentText(),
            'piano_color_scheme': piano_scheme,
            'guitar_color_scheme': guitar_scheme,
            # 向下兼容
            'color_scheme': piano_scheme
        }
