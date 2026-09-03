"""
Studio Color Picker Dialog - 极简优雅专业色彩选择器 (全主题自适应)
专为 Chord Studio Pro 设计。
1. 极简高雅设计：移除所有冗余长句，界面紧凑清爽 (390 x 430)；
2. 全主题自适应：明亮模式下纯白通透，暗黑模式下同源 Slate 蓝灰，浑然一体；
3. 滑轨视觉修复：手柄尺寸精致适配无截断，重置 sub-page 彻底消除左侧蓝色遮盖层；
4. 杜绝乱码：RGB 通道全面换用 QLineEdit 纯文本数字显示，100% 阿拉伯数字。
"""

from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QColor, QFont, QIntValidator
from PyQt5.QtWidgets import (QDialog, QFrame, QGridLayout, QHBoxLayout,
                             QLabel, QLineEdit, QPushButton, QSlider,
                             QVBoxLayout)

# 24 色精炼音乐高光色谱矩阵 (3行 x 8列)
ELEGANT_SWATCHES = [
    "#ffffff", "#cbd5e1", "#38bdf8", "#0ea5e9", "#0284c7", "#0369a1", "#6ee7b7", "#10b981",
    "#a3e635", "#84cc16", "#fef08a", "#facc15", "#f59e0b", "#f97316", "#fb7185", "#f43f5e",
    "#ef4444", "#dc2626", "#ec4899", "#d946ef", "#8b5cf6", "#6366f1", "#475569", "#1e293b"
]


class StudioColorPickerDialog(QDialog):
    """极简优雅全主题自适应取色器"""

    color_selected = pyqtSignal(QColor)

    def __init__(self, initial_color=QColor("#ffffff"), parent=None, title="选择高亮颜色", is_dark=False):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.setFixedSize(390, 440)
        self.setWindowFlags(self.windowFlags() & ~Qt.WindowContextHelpButtonHint)

        self.is_dark = is_dark

        if isinstance(initial_color, str):
            self.current_color = QColor(initial_color)
        else:
            self.current_color = QColor(initial_color)

        self.initial_color = QColor(self.current_color)
        self._updating = False

        self.init_ui()
        self.apply_theme(self.is_dark)
        self._sync_all_from_color()

    def apply_theme(self, is_dark):
        self.is_dark = is_dark
        if is_dark:
            # 暗黑模式
            self.setStyleSheet("""
                StudioColorPickerDialog {
                    background-color: #1e222b;
                }
                QLabel {
                    color: #cbd5e1;
                    font-family: "Segoe UI", "Microsoft YaHei", sans-serif;
                    font-size: 11px;
                }
                QFrame#PanelCard {
                    background-color: #262a35;
                    border: 1px solid #363b4a;
                    border-radius: 8px;
                }
                QSlider::sub-page:horizontal {
                    background: transparent;
                }
                QSlider::add-page:horizontal {
                    background: transparent;
                }
                QSlider::groove:horizontal {
                    height: 8px;
                    border-radius: 4px;
                }
                QSlider::handle:horizontal {
                    width: 14px;
                    height: 14px;
                    margin: -3px 0;
                    border-radius: 7px;
                    background-color: #ffffff;
                    border: 2px solid #0284c7;
                }
                QLineEdit {
                    background-color: #16181f;
                    color: #f8fafc;
                    border: 1px solid #3b4254;
                    border-radius: 6px;
                    padding: 3px 6px;
                    font-family: "Consolas", monospace;
                    font-size: 11px;
                    font-weight: bold;
                }
                QLineEdit:focus {
                    border: 1.5px solid #38bdf8;
                }
                QPushButton#PrimaryBtn {
                    background-color: #0284c7;
                    color: #ffffff;
                    border: none;
                    border-radius: 6px;
                    padding: 6px 18px;
                    font-weight: bold;
                    font-size: 12px;
                }
                QPushButton#PrimaryBtn:hover {
                    background-color: #0369a1;
                }
                QPushButton#CancelBtn {
                    background-color: #282d3b;
                    color: #cbd5e1;
                    border: 1px solid #3e465a;
                    border-radius: 6px;
                    padding: 6px 14px;
                    font-weight: bold;
                    font-size: 12px;
                }
                QPushButton#CancelBtn:hover {
                    background-color: #343b4d;
                    color: #ffffff;
                }
            """)
            self.orig_lbl.setStyleSheet("color: #94a3b8; font-size: 11px;")
            self.new_lbl.setStyleSheet("color: #38bdf8; font-size: 11px; font-weight: bold;")
            self.arrow_lbl.setStyleSheet("color: #64748b; font-size: 16px;")
        else:
            # 明亮模式：高雅通透白与板岩灰
            self.setStyleSheet("""
                StudioColorPickerDialog {
                    background-color: #ffffff;
                }
                QLabel {
                    color: #334155;
                    font-family: "Segoe UI", "Microsoft YaHei", sans-serif;
                    font-size: 11px;
                }
                QFrame#PanelCard {
                    background-color: #f8fafc;
                    border: 1px solid #e2e8f0;
                    border-radius: 8px;
                }
                QSlider::sub-page:horizontal {
                    background: transparent;
                }
                QSlider::add-page:horizontal {
                    background: transparent;
                }
                QSlider::groove:horizontal {
                    height: 8px;
                    border-radius: 4px;
                }
                QSlider::handle:horizontal {
                    width: 14px;
                    height: 14px;
                    margin: -3px 0;
                    border-radius: 7px;
                    background-color: #ffffff;
                    border: 2px solid #0284c7;
                }
                QLineEdit {
                    background-color: #ffffff;
                    color: #0f172a;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                    padding: 3px 6px;
                    font-family: "Consolas", monospace;
                    font-size: 11px;
                    font-weight: bold;
                }
                QLineEdit:focus {
                    border: 1.5px solid #0284c7;
                }
                QPushButton#PrimaryBtn {
                    background-color: #0284c7;
                    color: #ffffff;
                    border: none;
                    border-radius: 6px;
                    padding: 6px 18px;
                    font-weight: bold;
                    font-size: 12px;
                }
                QPushButton#PrimaryBtn:hover {
                    background-color: #0369a1;
                }
                QPushButton#CancelBtn {
                    background-color: #f1f5f9;
                    color: #475569;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                    padding: 6px 14px;
                    font-weight: bold;
                    font-size: 12px;
                }
                QPushButton#CancelBtn:hover {
                    background-color: #e2e8f0;
                    color: #0f172a;
                }
            """)
            self.orig_lbl.setStyleSheet("color: #64748b; font-size: 11px;")
            self.new_lbl.setStyleSheet("color: #0284c7; font-size: 11px; font-weight: bold;")
            self.arrow_lbl.setStyleSheet("color: #94a3b8; font-size: 16px;")

    def init_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(16, 14, 16, 14)
        main_layout.setSpacing(10)

        # 1. 顶部：原色与新色极简对比卡片
        compare_box = QHBoxLayout()
        compare_box.setSpacing(10)

        orig_box = QVBoxLayout()
        orig_box.setSpacing(2)
        self.orig_lbl = QLabel("原色")
        self.orig_lbl.setAlignment(Qt.AlignCenter)
        self.orig_block = QFrame()
        self.orig_block.setFixedHeight(36)
        self.orig_block.setStyleSheet(f"background-color: {self.initial_color.name()}; border: 1.5px solid #94a3b8; border-radius: 6px;")
        orig_box.addWidget(self.orig_lbl)
        orig_box.addWidget(self.orig_block)
        compare_box.addLayout(orig_box)

        self.arrow_lbl = QLabel("➜")
        self.arrow_lbl.setAlignment(Qt.AlignCenter)
        compare_box.addWidget(self.arrow_lbl)

        new_box = QVBoxLayout()
        new_box.setSpacing(2)
        self.new_lbl = QLabel("当前")
        self.new_lbl.setAlignment(Qt.AlignCenter)
        self.new_block = QFrame()
        self.new_block.setFixedHeight(36)
        self.new_block.setStyleSheet(f"background-color: {self.current_color.name()}; border: 2px solid #0284c7; border-radius: 6px;")
        new_box.addWidget(self.new_lbl)
        new_box.addWidget(self.new_block)
        compare_box.addLayout(new_box)

        main_layout.addLayout(compare_box)

        # 2. 直观滑块卡片：色相 (Hue) 与 明暗 (Value)
        slider_card = QFrame()
        slider_card.setObjectName("PanelCard")
        slider_layout = QVBoxLayout(slider_card)
        slider_layout.setContentsMargins(10, 8, 10, 8)
        slider_layout.setSpacing(8)

        # 2.1 色相
        hue_row = QHBoxLayout()
        self.hue_title = QLabel("色相")
        self.hue_title.setFixedWidth(32)
        self.hue_slider = QSlider(Qt.Horizontal)
        self.hue_slider.setRange(0, 359)
        self.hue_slider.setFixedHeight(22)
        self.hue_slider.setStyleSheet("""
            QSlider::groove:horizontal {
                height: 8px;
                border-radius: 4px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0.00 #ff0000,
                    stop:0.17 #ffff00,
                    stop:0.33 #00ff00,
                    stop:0.50 #00ffff,
                    stop:0.67 #0000ff,
                    stop:0.83 #ff00ff,
                    stop:1.00 #ff0000
                );
            }
        """)
        self.hue_slider.valueChanged.connect(self._on_hue_slider_changed)
        hue_row.addWidget(self.hue_title)
        hue_row.addWidget(self.hue_slider)
        slider_layout.addLayout(hue_row)

        # 2.2 明暗
        val_row = QHBoxLayout()
        self.val_title = QLabel("明暗")
        self.val_title.setFixedWidth(32)
        self.val_slider = QSlider(Qt.Horizontal)
        self.val_slider.setRange(0, 255)
        self.val_slider.setFixedHeight(22)
        self.val_slider.setStyleSheet("""
            QSlider::groove:horizontal {
                height: 8px;
                border-radius: 4px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #000000,
                    stop:1 #ffffff
                );
            }
        """)
        self.val_slider.valueChanged.connect(self._on_val_slider_changed)
        val_row.addWidget(self.val_title)
        val_row.addWidget(self.val_slider)
        slider_layout.addLayout(val_row)

        main_layout.addWidget(slider_card)

        # 3. 24 色精炼常用色谱矩阵 (3x8)
        palette_card = QFrame()
        palette_card.setObjectName("PanelCard")
        palette_layout = QVBoxLayout(palette_card)
        palette_layout.setContentsMargins(10, 8, 10, 8)
        palette_layout.setSpacing(6)

        grid = QGridLayout()
        grid.setSpacing(5)
        for idx, hex_code in enumerate(ELEGANT_SWATCHES):
            btn = QPushButton()
            btn.setFixedSize(36, 20)
            btn.setCursor(Qt.PointingHandCursor)
            border = "2px solid #0284c7" if hex_code.lower() == "#ffffff" else "1px solid #94a3b8"
            btn.setStyleSheet(f"background-color: {hex_code}; border: {border}; border-radius: 3px;")
            btn.setToolTip(hex_code)
            btn.clicked.connect(lambda checked, h=hex_code: self._apply_preset_color(h))
            row = idx // 8
            col = idx % 8
            grid.addWidget(btn, row, col)
        palette_layout.addLayout(grid)
        main_layout.addWidget(palette_card)

        # 4. 纯数字输入排 (HEX + 纯数字 R G B，彻底消灭任何乱码)
        input_card = QFrame()
        input_card.setObjectName("PanelCard")
        input_layout = QHBoxLayout(input_card)
        input_layout.setContentsMargins(10, 8, 10, 8)
        input_layout.setSpacing(8)

        # HEX
        hex_lbl = QLabel("HEX:")
        hex_lbl.setStyleSheet("font-weight: bold;")
        self.hex_edit = QLineEdit()
        self.hex_edit.setMaxLength(9)
        self.hex_edit.setFixedWidth(75)
        self.hex_edit.textEdited.connect(self._on_hex_text_edited)
        input_layout.addWidget(hex_lbl)
        input_layout.addWidget(self.hex_edit)

        input_layout.addSpacing(6)

        int_val = QIntValidator(0, 255, self)

        # R
        r_lbl = QLabel("R:")
        r_lbl.setStyleSheet("color: #ef4444; font-weight: bold;")
        self.r_edit = QLineEdit()
        self.r_edit.setValidator(int_val)
        self.r_edit.setAlignment(Qt.AlignCenter)
        self.r_edit.setFixedWidth(40)
        self.r_edit.textEdited.connect(self._on_rgb_edited)
        input_layout.addWidget(r_lbl)
        input_layout.addWidget(self.r_edit)

        # G
        g_lbl = QLabel("G:")
        g_lbl.setStyleSheet("color: #10b981; font-weight: bold;")
        self.g_edit = QLineEdit()
        self.g_edit.setValidator(int_val)
        self.g_edit.setAlignment(Qt.AlignCenter)
        self.g_edit.setFixedWidth(40)
        self.g_edit.textEdited.connect(self._on_rgb_edited)
        input_layout.addWidget(g_lbl)
        input_layout.addWidget(self.g_edit)

        # B
        b_lbl = QLabel("B:")
        b_lbl.setStyleSheet("color: #0284c7; font-weight: bold;")
        self.b_edit = QLineEdit()
        self.b_edit.setValidator(int_val)
        self.b_edit.setAlignment(Qt.AlignCenter)
        self.b_edit.setFixedWidth(40)
        self.b_edit.textEdited.connect(self._on_rgb_edited)
        input_layout.addWidget(b_lbl)
        input_layout.addWidget(self.b_edit)

        main_layout.addWidget(input_card)

        # 5. 底部按钮
        btn_row = QHBoxLayout()
        btn_row.addStretch()

        cancel_btn = QPushButton("取消")
        cancel_btn.setObjectName("CancelBtn")
        cancel_btn.clicked.connect(self.reject)
        btn_row.addWidget(cancel_btn)

        ok_btn = QPushButton("确定")
        ok_btn.setObjectName("PrimaryBtn")
        ok_btn.clicked.connect(self.accept)
        btn_row.addWidget(ok_btn)

        main_layout.addLayout(btn_row)

    def _sync_all_from_color(self):
        self._updating = True
        r = self.current_color.red()
        g = self.current_color.green()
        b = self.current_color.blue()

        # 纯正 ASCII 阿拉伯数字字符串，绝无任何乱码
        self.r_edit.setText(str(r))
        self.g_edit.setText(str(g))
        self.b_edit.setText(str(b))

        # 同步 HSV
        h, s, v, _ = self.current_color.getHsv()
        if h >= 0:
            self.hue_slider.setValue(h)
        self.val_slider.setValue(v)

        hex_str = self.current_color.name().upper()
        self.hex_edit.setText(hex_str)
        self.new_block.setStyleSheet(f"background-color: {hex_str}; border: 2px solid #0284c7; border-radius: 6px;")
        self._updating = False

    def _apply_preset_color(self, hex_str):
        self.current_color = QColor(hex_str)
        self._sync_all_from_color()

    def _on_hue_slider_changed(self):
        if self._updating:
            return
        h = self.hue_slider.value()
        _, s, v, _ = self.current_color.getHsv()
        if s < 40:
            s = 200
        if v < 40:
            v = 220
        self.current_color = QColor.fromHsv(h, s, v)
        self._sync_all_from_color()

    def _on_val_slider_changed(self):
        if self._updating:
            return
        v = self.val_slider.value()
        h, s, _, _ = self.current_color.getHsv()
        if h < 0:
            h = self.hue_slider.value()
        self.current_color = QColor.fromHsv(h, s, v)
        self._sync_all_from_color()

    def _on_rgb_edited(self):
        if self._updating:
            return
        try:
            r = int(self.r_edit.text()) if self.r_edit.text() else 0
            g = int(self.g_edit.text()) if self.g_edit.text() else 0
            b = int(self.b_edit.text()) if self.b_edit.text() else 0
            r = max(0, min(255, r))
            g = max(0, min(255, g))
            b = max(0, min(255, b))
            self.current_color = QColor(r, g, b)
            self._updating = True
            hex_str = self.current_color.name().upper()
            self.hex_edit.setText(hex_str)
            self.new_block.setStyleSheet(f"background-color: {hex_str}; border: 2px solid #0284c7; border-radius: 6px;")
            h, _, v, _ = self.current_color.getHsv()
            if h >= 0:
                self.hue_slider.setValue(h)
            self.val_slider.setValue(v)
            self._updating = False
        except ValueError:
            pass

    def _on_hex_text_edited(self, text):
        if self._updating:
            return
        text = text.strip()
        if not text.startswith("#"):
            text = "#" + text
        if QColor.isValidColor(text):
            self.current_color = QColor(text)
            self._updating = True
            r = self.current_color.red()
            g = self.current_color.green()
            b = self.current_color.blue()
            self.r_edit.setText(str(r))
            self.g_edit.setText(str(g))
            self.b_edit.setText(str(b))
            h, _, v, _ = self.current_color.getHsv()
            if h >= 0:
                self.hue_slider.setValue(h)
            self.val_slider.setValue(v)
            self.new_block.setStyleSheet(f"background-color: {self.current_color.name()}; border: 2px solid #0284c7; border-radius: 6px;")
            self._updating = False

    def get_color(self):
        return self.current_color

    @staticmethod
    def getColor(initial_color=QColor("#ffffff"), parent=None, title="选择高亮颜色", is_dark=False):
        dlg = StudioColorPickerDialog(initial_color, parent, title=title, is_dark=is_dark)
        if dlg.exec_():
            return dlg.get_color()
        return QColor()
