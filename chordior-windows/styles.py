"""
Styles - 专业现代音乐工作站 UI 样式与主题管理 (DAW Studio Theme)
支持 High-DPI 高分屏字号适配，提供优雅高级的 Pro Dark 与 Clean Light 主题，以明亮模式为基准完美对齐组件规范。
"""

DARK_THEME_QSS = """
/* ========== 全局暗黑专业主题 (DAW Studio Pro Dark) ========== */
QWidget {
    background-color: #121316;
    color: #e2e8f0;
    font-family: "Segoe UI", "Microsoft YaHei", "PingFang SC", sans-serif;
    font-size: 13px;
    font-weight: 500;
}

QMainWindow, QDialog {
    background-color: #0d0e11;
}

/* 专业卡片面板 */
QFrame#CardPanel {
    background-color: #181a20;
    border: 1px solid #282c35;
    border-radius: 12px;
}

QFrame#HeaderCard {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #1c1f26, stop:1 #16181e);
    border: 1px solid #2d323e;
    border-radius: 12px;
}

QFrame#InstrumentContainer {
    background-color: #15171d;
    border: 1px solid #282c35;
    border-radius: 12px;
}

/* 分区标题与副标 */
QLabel#SectionTitle {
    color: #f8fafc;
    font-size: 15px;
    font-weight: 700;
    letter-spacing: 0.5px;
}

QLabel#SubtitleLabel {
    color: #8392a5;
    font-size: 12px;
    font-weight: normal;
}

QLabel#ChordDisplay {
    color: #38bdf8;
    font-size: 24px;
    font-weight: 900;
    letter-spacing: 1px;
}

/* 下拉选择框 ComboBox */
QComboBox {
    background-color: #20232c;
    border: 1px solid #333947;
    border-radius: 8px;
    padding: 7px 14px;
    color: #f1f5f9;
    font-size: 13px;
    font-weight: 600;
    min-height: 22px;
}

QComboBox:hover {
    border-color: #38bdf8;
    background-color: #262a35;
}

QComboBox:focus {
    border: 1.5px solid #38bdf8;
}

QComboBox::drop-down {
    subcontrol-origin: padding;
    subcontrol-position: top right;
    width: 24px;
    border: none;
    background: transparent;
}

QComboBox::down-arrow {
    image: none;
    border-left: 3.5px solid transparent;
    border-right: 3.5px solid transparent;
    border-top: 4.5px solid #64748b;
    width: 0;
    height: 0;
    margin-right: 8px;
}

QComboBox::down-arrow:hover {
    border-top-color: #38bdf8;
}

QComboBox QAbstractItemView {
    background-color: #1c1e26;
    border: 1px solid #38bdf8;
    border-radius: 0px;
    selection-background-color: #2563eb;
    selection-color: #ffffff;
    outline: none;
    padding: 4px 0px;
    color: #f8fafc;
    max-height: 480px;
}

QComboBox QAbstractItemView::item {
    min-height: 30px;
    padding: 6px 12px;
    border-radius: 6px;
    margin: 1px 0px;
}

QComboBox QAbstractItemView::item:hover {
    background-color: #2a3140;
}

/* 选项卡 TabWidget - 水平居中排列与圆角 */
QTabWidget::pane {
    border: 1px solid #282d3c;
    border-radius: 12px;
    background-color: #1a1d26;
    top: -1px;
}

QTabBar {
    alignment: center;
    background: transparent;
}

QTabBar::tab {
    background: transparent;
    color: #94a3b8;
    padding: 7px 18px;
    font-weight: 700;
    font-size: 13px;
    border-bottom: 2.5px solid transparent;
    margin: 0px 4px;
}

QTabBar::tab:hover {
    color: #38bdf8;
}

QTabBar::tab:selected {
    color: #38bdf8;
    border-bottom: 2.5px solid #38bdf8;
}

/* 按钮通用风格 */
QPushButton {
    background-color: #20232c;
    border: 1px solid #333947;
    border-radius: 8px;
    color: #f1f5f9;
    font-size: 13px;
    font-weight: 600;
    padding: 8px 16px;
}

QPushButton:hover {
    background-color: #282d39;
    border-color: #38bdf8;
    color: #38bdf8;
}

QPushButton#PrimaryButton {
    background-color: #0284c7;
    border: none;
    color: #ffffff;
    font-weight: 700;
}

QPushButton#PrimaryButton:hover {
    background-color: #0369a1;
}

QPushButton#PlayActionButton {
    background-color: #10b981;
    border: none;
    color: #ffffff;
    font-size: 14px;
    font-weight: 700;
}

QPushButton#PlayActionButton:hover {
    background-color: #059669;
}

QPushButton#DangerButton {
    border: 1px solid #f43f5e;
    color: #fb7185;
    background-color: #1f1418;
}

QPushButton#DangerButton:hover {
    background-color: #e11d48;
    color: #ffffff;
}

QPushButton#ModeSwitchButton {
    background-color: #1e293b;
    border: 1px solid #38bdf8;
    color: #38bdf8;
    font-weight: 700;
    padding: 8px 14px;
}

QPushButton#ModeSwitchButton:hover {
    background-color: #0284c7;
    color: #ffffff;
}

/* 列表控件 */
QListWidget {
    background-color: #14161c;
    border: 1px solid #282c35;
    border-radius: 8px;
    color: #f1f5f9;
    outline: none;
    padding: 6px;
}

QListWidget::item {
    border-radius: 6px;
    padding: 3px 8px;
    margin: 1px 0px;
}

QListWidget::item:hover {
    background-color: #1e222c;
}

QListWidget::item:selected {
    background-color: #1e3a5f;
    border: 1px solid #38bdf8;
    color: #ffffff;
}

/* 文本输入框 */
QTextEdit, QLineEdit {
    background-color: #14161c;
    border: 1px solid #2d323e;
    border-radius: 8px;
    color: #ffffff;
    padding: 6px 10px;
    font-size: 13px;
}

QTextEdit:focus, QLineEdit:focus {
    border: 1.5px solid #38bdf8;
}

/* 滚动条 */
QScrollBar:vertical, QScrollBar:horizontal {
    background: #121316;
    width: 8px;
    height: 8px;
    border-radius: 4px;
    margin: 0px;
}

QScrollBar::handle:vertical, QScrollBar::handle:horizontal {
    background: #333947;
    min-height: 25px;
    min-width: 25px;
    border-radius: 4px;
}

QScrollBar::handle:hover {
    background: #38bdf8;
}

QScrollBar::add-line, QScrollBar::sub-line {
    width: 0px;
    height: 0px;
}

/* 滑块 Slider */
QSlider::groove:horizontal {
    height: 6px;
    background: #20232c;
    border-radius: 3px;
}

QSlider::sub-page:horizontal {
    background: #38bdf8;
    border-radius: 3px;
}

QSlider::handle:horizontal {
    background: #ffffff;
    border: 2px solid #38bdf8;
    width: 14px;
    margin-top: -4px;
    margin-bottom: -4px;
    border-radius: 7px;
}

QSlider::handle:horizontal:hover {
    background: #38bdf8;
}

/* 微调框 SpinBox */
QSpinBox {
    background-color: #20232c;
    border: 1px solid #333947;
    border-radius: 8px;
    color: #ffffff;
    padding: 6px 10px;
    font-weight: 700;
}

/* 复选框 CheckBox */
QCheckBox {
    color: #e2e8f0;
    spacing: 8px;
    font-size: 13px;
}

QCheckBox::indicator {
    width: 18px;
    height: 18px;
    border: 1px solid #475569;
    border-radius: 4px;
    background-color: #20232c;
}

QCheckBox::indicator:checked {
    background-color: #2563eb;
    border-color: #38bdf8;
}

/* 分割线 Splitter */
QSplitter::handle {
    background-color: #20232a;
}

QSplitter::handle:hover {
    background-color: #38bdf8;
}
"""


LIGHT_THEME_QSS = """
/* ========== 全局明亮清爽主题 (DAW Clean Light) ========== */
QWidget {
    background-color: #f8fafc;
    color: #1e293b;
    font-family: "Segoe UI", "Microsoft YaHei", "PingFang SC", sans-serif;
    font-size: 13px;
    font-weight: 500;
}

QMainWindow, QDialog {
    background-color: #f1f5f9;
}

QFrame#CardPanel {
    background-color: #ffffff;
    border: 1.5px solid #e2e8f0;
    border-radius: 12px;
}

QFrame#HeaderCard {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #ffffff, stop:1 #f8fafc);
    border: 1.5px solid #e2e8f0;
    border-radius: 12px;
}

QFrame#InstrumentContainer {
    background-color: #ffffff;
    border: 1.5px solid #e2e8f0;
    border-radius: 12px;
}

QLabel#SectionTitle {
    color: #0f172a;
    font-size: 15px;
    font-weight: 700;
    letter-spacing: 0.5px;
}

QLabel#SubtitleLabel {
    color: #64748b;
    font-size: 12px;
    font-weight: normal;
}

QLabel#ChordDisplay {
    color: #0284c7;
    font-size: 24px;
    font-weight: 900;
    letter-spacing: 1px;
}

QComboBox {
    background-color: #ffffff;
    border: 1.5px solid #cbd5e1;
    border-radius: 8px;
    padding: 7px 14px;
    color: #0f172a;
    font-size: 13px;
    font-weight: 600;
    min-height: 22px;
}

QComboBox:hover {
    border-color: #0284c7;
    background-color: #f8fafc;
}

QComboBox:focus {
    border: 1.5px solid #0284c7;
}

QComboBox::drop-down {
    subcontrol-origin: padding;
    subcontrol-position: top right;
    width: 24px;
    border: none;
    background: transparent;
}

QComboBox::down-arrow {
    image: none;
    border-left: 3.5px solid transparent;
    border-right: 3.5px solid transparent;
    border-top: 4.5px solid #94a3b8;
    width: 0;
    height: 0;
    margin-right: 8px;
}

QComboBox::down-arrow:hover {
    border-top-color: #0284c7;
}

QComboBox QAbstractItemView {
    background-color: #ffffff;
    border: 1.5px solid #0284c7;
    border-radius: 0px;
    selection-background-color: #0284c7;
    selection-color: #ffffff;
    outline: none;
    padding: 4px 0px;
    color: #0f172a;
    max-height: 480px;
}

QComboBox QAbstractItemView::item {
    min-height: 30px;
    padding: 6px 12px;
    border-radius: 6px;
    margin: 1px 0px;
}

QComboBox QAbstractItemView::item:hover {
    background-color: #f1f5f9;
}

/* 选项卡 TabWidget - 水平居中排列与圆角 */
QTabWidget::pane {
    border: 1.5px solid #e2e8f0;
    border-radius: 12px;
    background-color: #ffffff;
    top: -1px;
}

QTabBar {
    alignment: center;
    background: transparent;
}

QTabBar::tab {
    background: transparent;
    color: #64748b;
    padding: 7px 18px;
    font-weight: 700;
    font-size: 13px;
    border-bottom: 2.5px solid transparent;
    margin: 0px 4px;
}

QTabBar::tab:hover {
    color: #0284c7;
}

QTabBar::tab:selected {
    color: #0284c7;
    border-bottom: 2.5px solid #0284c7;
}

QPushButton {
    background-color: #ffffff;
    border: 1.5px solid #cbd5e1;
    border-radius: 8px;
    color: #1e293b;
    font-size: 13px;
    font-weight: 600;
    padding: 8px 16px;
}

QPushButton:hover {
    background-color: #f1f5f9;
    border-color: #0284c7;
    color: #0284c7;
}

QPushButton#PrimaryButton {
    background-color: #0284c7;
    border: none;
    color: #ffffff;
    font-weight: 700;
}

QPushButton#PrimaryButton:hover {
    background-color: #0369a1;
}

QPushButton#PlayActionButton {
    background-color: #10b981;
    border: none;
    color: #ffffff;
    font-size: 14px;
    font-weight: 700;
}

QPushButton#PlayActionButton:hover {
    background-color: #059669;
}

QPushButton#DangerButton {
    border: 1.5px solid #f87171;
    color: #ef4444;
    background-color: #ffffff;
}

QPushButton#DangerButton:hover {
    background-color: #ef4444;
    color: #ffffff;
}

QPushButton#ModeSwitchButton {
    background-color: #f0f9ff;
    border: 1.5px solid #0284c7;
    color: #0284c7;
    font-weight: 700;
    padding: 8px 14px;
}

QPushButton#ModeSwitchButton:hover {
    background-color: #e0f2fe;
}

/* 列表控件 */
QListWidget {
    background-color: #ffffff;
    border: 1.5px solid #e2e8f0;
    border-radius: 8px;
    color: #0f172a;
    outline: none;
    padding: 6px;
}

QListWidget::item {
    border-radius: 6px;
    padding: 3px 8px;
    margin: 1px 0px;
}

QListWidget::item:hover {
    background-color: #f1f5f9;
}

QListWidget::item:selected {
    background-color: #e0f2fe;
    border: 1px solid #0284c7;
    color: #0284c7;
}

/* 文本输入框 */
QTextEdit, QLineEdit {
    background-color: #ffffff;
    border: 1.5px solid #cbd5e1;
    border-radius: 8px;
    color: #0f172a;
    padding: 6px 10px;
    font-size: 13px;
}

QTextEdit:focus, QLineEdit:focus {
    border: 1.5px solid #0284c7;
}

/* 滚动条 */
QScrollBar:vertical, QScrollBar:horizontal {
    background: #f1f5f9;
    width: 8px;
    height: 8px;
    border-radius: 4px;
    margin: 0px;
}

QScrollBar::handle:vertical, QScrollBar::handle:horizontal {
    background: #cbd5e1;
    min-height: 25px;
    min-width: 25px;
    border-radius: 4px;
}

QScrollBar::handle:hover {
    background: #0284c7;
}

QScrollBar::add-line, QScrollBar::sub-line {
    width: 0px;
    height: 0px;
}

/* 滑块 Slider */
QSlider::groove:horizontal {
    height: 6px;
    background: #e2e8f0;
    border-radius: 3px;
}

QSlider::sub-page:horizontal {
    background: #0284c7;
    border-radius: 3px;
}

QSlider::handle:horizontal {
    background: #ffffff;
    border: 2px solid #0284c7;
    width: 14px;
    margin-top: -4px;
    margin-bottom: -4px;
    border-radius: 7px;
}

QSlider::handle:horizontal:hover {
    background: #0284c7;
}

/* 微调框 SpinBox */
QSpinBox {
    background-color: #ffffff;
    border: 1.5px solid #cbd5e1;
    border-radius: 8px;
    color: #0f172a;
    padding: 6px 10px;
    font-weight: 700;
}

/* 复选框 CheckBox */
QCheckBox {
    color: #1e293b;
    spacing: 8px;
    font-size: 13px;
}

QCheckBox::indicator {
    width: 18px;
    height: 18px;
    border: 1.5px solid #94a3b8;
    border-radius: 4px;
    background-color: #ffffff;
}

QCheckBox::indicator:checked {
    background-color: #0284c7;
    border-color: #0284c7;
}

/* 分割线 Splitter */
QSplitter::handle {
    background-color: #e2e8f0;
}

QSplitter::handle:hover {
    background-color: #0284c7;
}
"""
