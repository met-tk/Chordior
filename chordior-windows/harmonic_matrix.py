"""
Harmonic Matrix - 调式顺阶和声矩阵组件
展示指定调式下 I-VII 级的顺阶和弦，支持三和弦/七和弦/九和弦切换、卡片高亮选中联动、拖拽到和弦进行编排器与下拉框双向独立安全响应。
"""

import json
from PyQt5.QtCore import QEvent, QMimeData, QPoint, QRect, QSize, Qt, pyqtSignal
from PyQt5.QtGui import QColor, QCursor, QDrag, QFont, QPainter
from PyQt5.QtWidgets import (QApplication, QComboBox, QFrame, QGraphicsDropShadowEffect,
                             QHBoxLayout, QLabel, QPushButton, QScrollArea,
                             QVBoxLayout, QWidget)
from theory_engine import (DEGREE_FUNCTIONS, MODE_COLORS, MODES, NOTE_NAMES,
                           get_mode_harmonics, identify_chord_name)
from harmonic_advice import get_chord_advice_data


class ChordAdvicePopup(QFrame):
    """现代 DAW 风格和弦实战使用建议浮窗卡片 (鼠标右键触发与开关)"""

    closed = pyqtSignal()

    def __init__(self, advice_data, chord_name, roman, mode_name, target_block, is_dark=True, parent=None):
        super().__init__(None)  # 顶层无父级浮窗，避免被父控件裁剪
        self.setWindowFlags(Qt.ToolTip | Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_ShowWithoutActivating)
        # 绝不设置 WA_DeleteOnClose，由 Python 和统一槽函数安全管理生命周期
        self.target_block = target_block
        self.is_dark = is_dark
        self._filter_installed = False

        self.init_ui(advice_data, chord_name, roman, mode_name)

    def init_ui(self, data, chord_name, roman, mode_name):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 12, 14, 12)
        layout.setSpacing(8)

        # 头部标题栏
        top_box = QHBoxLayout()
        top_box.setSpacing(6)

        title_lbl = QLabel(f"🎹 {roman} · {chord_name}", self)
        title_lbl.setFont(QFont("Segoe UI", 11, QFont.Bold))
        
        hint_lbl = QLabel("再次右键关闭 ✕", self)
        hint_lbl.setFont(QFont("Segoe UI", 8))

        top_box.addWidget(title_lbl)
        top_box.addStretch()
        top_box.addWidget(hint_lbl)
        layout.addLayout(top_box)

        # 调式与功能标签
        clean_mode = mode_name.split(' ')[0] if mode_name else ""
        func_tag = data.get('func', '')
        mode_func_lbl = QLabel(f"<b>调式定位</b>: <span style='color: #38bdf8;'>{clean_mode}</span> · {func_tag}", self)
        mode_func_lbl.setFont(QFont("Segoe UI", 9))
        mode_func_lbl.setWordWrap(True)
        layout.addWidget(mode_func_lbl)

        # 分割线
        sep = QFrame(self)
        sep.setFrameShape(QFrame.HLine)
        sep.setFrameShadow(QFrame.Plain)
        layout.addWidget(sep)

        proto = data.get('prototype', '')
        common = data.get('common_form', '')
        theory = data.get('theory', '')
        prog = data.get('progressions', '').replace('\n', '<br/>')

        if self.is_dark:
            self.setStyleSheet("""
                QFrame#AdvicePopupRoot {
                    background-color: #141820;
                    border: 1px solid #38bdf8;
                    border-radius: 0px;
                }
                QScrollBar:vertical {
                    background: transparent;
                    width: 5px;
                    margin: 0px;
                }
                QScrollBar::handle:vertical {
                    background: #475569;
                    min-height: 24px;
                    border-radius: 0px;
                }
                QScrollBar::handle:vertical:hover {
                    background: #64748b;
                }
                QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                    height: 0px;
                }
            """)
            self.setObjectName("AdvicePopupRoot")
            title_lbl.setStyleSheet("color: #f8fafc; background: transparent;")
            hint_lbl.setStyleSheet("color: #64748b; background: transparent;")
            mode_func_lbl.setStyleSheet("color: #94a3b8; background: transparent;")
            sep.setStyleSheet("color: #1e293b; background-color: #1e293b;")
            
            html_text = f"""
            <div style="line-height: 1.5; color: #e2e8f0;">
                <div style="margin-bottom: 6px;">
                    <span style="color: #94a3b8; font-weight: bold;">【顺阶原型】:</span> 
                    <span style="color: #cbd5e1;">{proto}</span>
                </div>
                <div style="margin-bottom: 6px;">
                    <span style="color: #38bdf8; font-weight: bold;">【常用选型】:</span> 
                    <span style="color: #f59e0b; font-weight: bold; background-color: rgba(245, 158, 11, 0.15); padding: 1px 6px; border-radius: 0px;">{common}</span>
                </div>
                <div style="margin-bottom: 8px;">
                    <span style="color: #38bdf8; font-weight: bold;">【声部说明】:</span><br/>
                    <span style="color: #cbd5e1; font-size: 11px;">{theory}</span>
                </div>
                <div>
                    <span style="color: #c084fc; font-weight: bold;">【规范连接】:</span><br/>
                    <span style="color: #e2e8f0; font-size: 11px; font-family: 'Consolas', monospace;">{prog}</span>
                </div>
            </div>
            """
        else:
            self.setStyleSheet("""
                QFrame#AdvicePopupRoot {
                    background-color: #ffffff;
                    border: 1px solid #0284c7;
                    border-radius: 0px;
                }
                QScrollBar:vertical {
                    background: transparent;
                    width: 5px;
                    margin: 0px;
                }
                QScrollBar::handle:vertical {
                    background: #cbd5e1;
                    min-height: 24px;
                    border-radius: 0px;
                }
                QScrollBar::handle:vertical:hover {
                    background: #94a3b8;
                }
                QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                    height: 0px;
                }
            """)
            self.setObjectName("AdvicePopupRoot")
            title_lbl.setStyleSheet("color: #0f172a; background: transparent;")
            hint_lbl.setStyleSheet("color: #94a3b8; background: transparent;")
            mode_func_lbl.setStyleSheet("color: #475569; background: transparent;")
            sep.setStyleSheet("color: #e2e8f0; background-color: #e2e8f0;")
            
            html_text = f"""
            <div style="line-height: 1.5; color: #1e293b;">
                <div style="margin-bottom: 6px;">
                    <span style="color: #64748b; font-weight: bold;">【顺阶原型】:</span> 
                    <span style="color: #334155;">{proto}</span>
                </div>
                <div style="margin-bottom: 6px;">
                    <span style="color: #0284c7; font-weight: bold;">【常用选型】:</span> 
                    <span style="color: #b45309; font-weight: bold; background-color: rgba(245, 158, 11, 0.15); padding: 1px 6px; border-radius: 0px;">{common}</span>
                </div>
                <div style="margin-bottom: 8px;">
                    <span style="color: #0284c7; font-weight: bold;">【声部说明】:</span><br/>
                    <span style="color: #334155; font-size: 11px;">{theory}</span>
                </div>
                <div>
                    <span style="color: #7e22ce; font-weight: bold;">【规范连接】:</span><br/>
                    <span style="color: #0f172a; font-size: 11px; font-family: 'Consolas', monospace;">{prog}</span>
                </div>
            </div>
            """

        # 内部可自适应滚动容器
        self.scroll_area = QScrollArea(self)
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setFrameShape(QFrame.NoFrame)
        self.scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        self.scroll_area.setStyleSheet("background: transparent; border: none;")

        scroll_widget = QWidget()
        scroll_layout = QVBoxLayout(scroll_widget)
        scroll_layout.setContentsMargins(0, 0, 4, 0)
        scroll_layout.setSpacing(0)

        self.content_lbl = QLabel(scroll_widget)
        self.content_lbl.setWordWrap(True)
        self.content_lbl.setFont(QFont("Segoe UI", 9))
        self.content_lbl.setText(html_text)
        self.content_lbl.setStyleSheet("background: transparent;")
        scroll_layout.addWidget(self.content_lbl)

        scroll_widget.setStyleSheet("background: transparent;")
        self.scroll_area.setWidget(scroll_widget)
        layout.addWidget(self.scroll_area, 1)

        # 阴影效果
        shadow = QGraphicsDropShadowEffect(self)
        shadow.setBlurRadius(16)
        shadow.setColor(QColor(0, 0, 0, 160 if self.is_dark else 60))
        shadow.setOffset(0, 4)
        self.setGraphicsEffect(shadow)

    def show_near_block(self, block):
        """智能计算屏幕位置并在卡片正上方或下方展示，完美适配窗口大小与边界"""
        screen = QApplication.desktop().screenGeometry(block)
        block_pos = block.mapToGlobal(QPoint(0, 0))
        bw = block.width()
        bh = block.height()

        # 1. 适度加宽至舒适阅读宽度 (430px)，不超过屏幕安全宽度
        pw = min(430, screen.width() - 30)
        self.setFixedWidth(pw)

        # 2. 精算内容自然理想高度 (无滚动条时的天然展开高度)
        content_h = self.content_lbl.sizeHint().height()
        ideal_h = content_h + 85  # 包含头部标题、定位标签、分割线及内边距

        # 3. 计算卡片上方与下方的真实可用纵向空间
        margin_y = 8
        space_above = block_pos.y() - screen.top() - margin_y - 15
        space_below = screen.bottom() - (block_pos.y() + bh) - margin_y - 15

        # 4. 判断放置方位：优先选择能够完全展示理想高度的一侧，否则选空间更大的一侧
        if space_above >= ideal_h:
            place_above = True
            available_h = space_above
        elif space_below >= ideal_h:
            place_above = False
            available_h = space_below
        elif space_above >= space_below:
            place_above = True
            available_h = space_above
        else:
            place_above = False
            available_h = space_below

        # 5. 动态自适应设定高度：
        # 如果理想高度在可用范围内，直接贴合理想高度（无滚动条，完全展开）；
        # 若内容超长或屏幕较小，则安全限制在可用高度内，并允许平滑滚动
        max_limit = min(560, available_h)
        final_h = max(260, min(ideal_h, max_limit))
        self.setFixedHeight(final_h)

        # 6. 计算最终 X/Y 坐标并做严格的屏幕贴边安全保护
        x = block_pos.x() + (bw - pw) // 2
        x = max(screen.left() + 10, min(x, screen.right() - pw - 10))

        if place_above:
            y = block_pos.y() - final_h - margin_y
        else:
            y = block_pos.y() + bh + margin_y

        y = max(screen.top() + 10, min(y, screen.bottom() - final_h - 10))

        self.move(x, y)
        self.show()

        # 安装全局点击监听，点击窗口外部任意位置自动平滑关闭
        if not self._filter_installed:
            app_inst = QApplication.instance()
            if app_inst:
                app_inst.installEventFilter(self)
                self._filter_installed = True

    def eventFilter(self, obj, event):
        if event.type() in (QEvent.MouseButtonPress, QEvent.MouseButtonDblClick):
            if hasattr(event, 'globalPos'):
                click_pos = event.globalPos()
                # 若点击不在本浮窗内
                if not self.geometry().contains(click_pos):
                    # 若点击也不在目标卡片上，则关闭自身
                    if self.target_block:
                        target_rect = QRect(self.target_block.mapToGlobal(QPoint(0, 0)), self.target_block.size())
                        if not target_rect.contains(click_pos):
                            self.close()
                    else:
                        self.close()
        return super().eventFilter(obj, event)

    def mousePressEvent(self, event):
        # 点击弹窗自身任意位置即可平滑关闭
        self.close()

    def closeEvent(self, event):
        if self._filter_installed:
            app_inst = QApplication.instance()
            if app_inst:
                app_inst.removeEventFilter(self)
            self._filter_installed = False
        self.closed.emit()
        super().closeEvent(event)


class DraggableHarmonicBlock(QFrame):
    """调式级数和弦卡片"""

    clicked = pyqtSignal(object)
    right_clicked = pyqtSignal(object)

    def __init__(self, roman, chord_name, notes, function_tag, degree_idx=0, mode_name="", parent=None):
        super().__init__(parent)
        self.roman = roman
        self.chord_name = chord_name
        self.notes = notes
        self.function_tag = function_tag
        self.degree_idx = degree_idx
        self.mode_name = mode_name
        self.is_highlighted = False
        self.drag_start_pos = None

        self.setCursor(Qt.PointingHandCursor)
        self.setMinimumSize(85, 80)
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)
        layout.setSpacing(2)

        top_row = QHBoxLayout()
        self.roman_label = QLabel(self.roman, self)
        self.roman_label.setFont(QFont("Segoe UI", 11, QFont.Bold))
        self.roman_label.setStyleSheet("color: #f8fafc; background: transparent;")

        func_short = self.function_tag.split(' ')[0].replace("和弦", "") if self.function_tag else ""
        self.func_label = QLabel(func_short, self)
        self.func_label.setFont(QFont("Segoe UI", 8, QFont.Bold))
        if func_short:
            self.func_label.setStyleSheet("""
                QLabel {
                    background-color: rgba(56, 189, 248, 0.15);
                    color: #38bdf8;
                    border-radius: 4px;
                    padding: 1px 5px;
                }
            """)
        else:
            self.func_label.setStyleSheet("background: transparent;")
        self.func_label.setAlignment(Qt.AlignRight | Qt.AlignVCenter)

        top_row.addWidget(self.roman_label)
        top_row.addStretch()
        top_row.addWidget(self.func_label)
        layout.addLayout(top_row)

        self.name_label = QLabel(self.chord_name, self)
        # 根据字符长度自适应字号
        font_size = 13
        if len(self.chord_name) > 8:
            font_size = 10
        elif len(self.chord_name) > 6:
            font_size = 11
        self.name_label.setFont(QFont("Segoe UI", font_size, QFont.Bold))
        self.name_label.setStyleSheet("color: #38bdf8; background: transparent;")
        self.name_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.name_label)

        clean_notes = ' '.join([n.split('/')[0] for n in self.notes])
        self.notes_label = QLabel(clean_notes, self)
        self.notes_label.setFont(QFont("Consolas", 8))
        self.notes_label.setStyleSheet("color: #94a3b8; background: transparent;")
        self.notes_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.notes_label)

        self.is_dark_theme = True
        self.update_card_style()

    def apply_theme(self, is_dark):
        self.is_dark_theme = is_dark
        self.update_card_style()

    def set_highlighted(self, highlighted):
        self.is_highlighted = highlighted
        self.update_card_style()

    def update_card_style(self):
        if self.is_dark_theme:
            # 暗黑主题
            self.roman_label.setStyleSheet("color: #f8fafc; background: transparent;")
            self.notes_label.setStyleSheet("color: #94a3b8; background: transparent;")
            self.name_label.setStyleSheet("color: #38bdf8; background: transparent;")
            if self.is_highlighted:
                self.setStyleSheet("""
                    QFrame {
                        background-color: #2e2617;
                        border: 2px solid #f59e0b;
                        border-radius: 10px;
                    }
                """)
            else:
                self.setStyleSheet("""
                    QFrame {
                        background-color: #1e222b;
                        border: 1px solid #2d3442;
                        border-radius: 10px;
                    }
                    QFrame:hover {
                        background-color: #272d3b;
                        border-color: #38bdf8;
                    }
                """)
        else:
            # 明亮主题 (以明亮模式为基准)
            self.roman_label.setStyleSheet("color: #0f172a; background: transparent;")
            self.notes_label.setStyleSheet("color: #64748b; background: transparent;")
            self.name_label.setStyleSheet("color: #0284c7; background: transparent;")
            if self.is_highlighted:
                self.setStyleSheet("""
                    QFrame {
                        background-color: #fffbeb;
                        border: 2px solid #f59e0b;
                        border-radius: 10px;
                    }
                """)
            else:
                self.setStyleSheet("""
                    QFrame {
                        background-color: #ffffff;
                        border: 1.5px solid #e2e8f0;
                        border-radius: 10px;
                    }
                    QFrame:hover {
                        background-color: #f0f9ff;
                        border-color: #0284c7;
                    }
                """)

    def mousePressEvent(self, event):
        if event.button() == Qt.RightButton:
            self.right_clicked.emit(self)
            event.accept()
            return
        elif event.button() == Qt.LeftButton:
            self.drag_start_pos = event.pos()
            self.clicked.emit(self)
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if not (event.buttons() & Qt.LeftButton) or self.drag_start_pos is None:
            return
        if (event.pos() - self.drag_start_pos).manhattanLength() < QApplication.startDragDistance():
            return

        drag = QDrag(self)
        mime = QMimeData()
        chord_data = {
            'notes': self.notes,
            'label': self.chord_name,
            'roman': self.roman,
            'beats': 2
        }
        mime.setData('application/x-chord-item', json.dumps(chord_data).encode('utf-8'))
        drag.setMimeData(mime)
        drag.setPixmap(self.grab())
        drag.setHotSpot(event.pos())
        drag.exec_(Qt.CopyAction)
        self.drag_start_pos = None


class HarmonicMatrixWidget(QWidget):
    """调式和声矩阵控制与展示主容器"""

    chord_triggered = pyqtSignal(list, str, str, str)  # (notes, chord_name, root, chord_type)
    scale_changed = pyqtSignal(str, str)               # (root, mode)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.blocks = []
        self._is_internal_updating = False
        self.is_dark_theme = True
        self.active_advice_popup = None
        self.init_ui()

    def apply_theme(self, is_dark):
        self.is_dark_theme = is_dark
        self.close_advice_popup()
        for b in self.blocks:
            b.apply_theme(is_dark)

    def init_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(8)

        # 1. 顶部控制栏
        ctrl_layout = QHBoxLayout()
        ctrl_layout.setSpacing(10)

        self.root_combo = QComboBox()
        self.root_combo.setMaxVisibleItems(25)
        self.root_combo.addItem("— (未选择)", "")
        for n in NOTE_NAMES:
            self.root_combo.addItem(n, n)

        self.mode_combo = QComboBox()
        self.mode_combo.setMaxVisibleItems(25)
        self.mode_combo.addItem("— (未选择)", "")
        for m in MODES.keys():
            self.mode_combo.addItem(m, m)

        self.depth_combo = QComboBox()
        self.depth_combo.setMaxVisibleItems(25)
        self.depth_combo.addItems(['Triad (三和弦)', '7th (七和弦)', '9th (九和弦)'])

        self.root_combo.currentIndexChanged.connect(self._on_user_selection_changed)
        self.mode_combo.currentIndexChanged.connect(self._on_user_selection_changed)
        self.depth_combo.currentIndexChanged.connect(self._on_user_selection_changed)

        ctrl_layout.addWidget(QLabel("调根音:"))
        ctrl_layout.addWidget(self.root_combo)
        ctrl_layout.addWidget(QLabel("调式音阶:"))
        ctrl_layout.addWidget(self.mode_combo, stretch=2)
        ctrl_layout.addWidget(QLabel("和弦深度:"))
        ctrl_layout.addWidget(self.depth_combo, stretch=1)
        ctrl_layout.addStretch()

        main_layout.addLayout(ctrl_layout)

        # 2. 顺阶级数卡片网格
        self.blocks_layout = QHBoxLayout()
        self.blocks_layout.setSpacing(8)
        main_layout.addLayout(self.blocks_layout)

        self.set_blank()

    def _on_user_selection_changed(self):
        if self._is_internal_updating:
            return

        root_data = self.root_combo.currentData()
        mode_data = self.mode_combo.currentData()

        # 如果两者都是空选项，则清空
        if not root_data and not mode_data:
            self.set_blank()
            self.scale_changed.emit("", "")
            return

        # 如果选了根音但没选调式，自动默认自然大调
        if root_data and not mode_data:
            self._is_internal_updating = True
            self.mode_combo.setCurrentIndex(1)  # Ionian
            mode_data = self.mode_combo.currentData()
            self._is_internal_updating = False

        # 如果选了调式但没选根音，自动默认 C
        if mode_data and not root_data:
            self._is_internal_updating = True
            self.root_combo.setCurrentIndex(1)  # C
            root_data = self.root_combo.currentData()
            self._is_internal_updating = False

        self.refresh_harmonics()
        self.scale_changed.emit(root_data, mode_data)

    def set_blank(self):
        """设置为空白未选择状态"""
        self._is_internal_updating = True
        self.root_combo.setCurrentIndex(0)
        self.mode_combo.setCurrentIndex(0)
        self._is_internal_updating = False

    def close_advice_popup(self):
        """平滑关闭当前活动的建议浮窗"""
        if self.active_advice_popup is not None:
            popup = self.active_advice_popup
            self.active_advice_popup = None
            try:
                popup.close()
            except Exception:
                pass

    def set_blank(self):
        """设置为空白未选择状态"""
        self.close_advice_popup()
        self._is_internal_updating = True
        self.root_combo.setCurrentIndex(0)
        self.mode_combo.setCurrentIndex(0)
        self._is_internal_updating = False

        while self.blocks_layout.count():
            item = self.blocks_layout.takeAt(0)
            widget = item.widget()
            if widget:
                widget.deleteLater()
        self.blocks = []

        placeholder = QLabel("💡 当前未选调式（请在左侧音阶列表、五度圈或上方选择调式与主音）")
        placeholder.setStyleSheet("color: #64748b; font-size: 11px; padding: 20px 0;")
        placeholder.setAlignment(Qt.AlignCenter)
        self.blocks_layout.addWidget(placeholder)

    def set_mode(self, root_name, mode_name, highlight_roman=None):
        """外部（如左侧列表/五度圈）设定调式"""
        if not root_name or not mode_name:
            self.set_blank()
            return

        self._is_internal_updating = True

        clean_root = root_name.split('/')[0]
        found_root = False
        for i in range(1, self.root_combo.count()):
            r_val = self.root_combo.itemData(i)
            if clean_root in r_val.split('/'):
                self.root_combo.setCurrentIndex(i)
                found_root = True
                break

        found_mode = False
        for i in range(1, self.mode_combo.count()):
            m_val = self.mode_combo.itemData(i)
            if mode_name in m_val or m_val in mode_name:
                self.mode_combo.setCurrentIndex(i)
                found_mode = True
                break

        self._is_internal_updating = False

        if found_root and found_mode:
            self.refresh_harmonics(highlight_roman=highlight_roman)
        else:
            self.set_blank()

    def refresh_harmonics(self, highlight_roman=None):
        self.close_advice_popup()
        while self.blocks_layout.count():
            item = self.blocks_layout.takeAt(0)
            widget = item.widget()
            if widget:
                widget.deleteLater()
        self.blocks = []

        root = self.root_combo.currentData()
        mode_full = self.mode_combo.currentData()

        if not root or not mode_full:
            self.set_blank()
            return

        depth_str = 'Triad'
        if '7th' in self.depth_combo.currentText():
            depth_str = '7th'
        elif '9th' in self.depth_combo.currentText():
            depth_str = '9th'

        harmonics = get_mode_harmonics(root, mode_full, depth=depth_str)

        for idx, h in enumerate(harmonics):
            block = DraggableHarmonicBlock(
                roman=h['roman'],
                chord_name=h['name'],
                notes=h['notes'],
                function_tag=h['function'],
                degree_idx=idx,
                mode_name=mode_full,
                parent=self
            )
            block.apply_theme(self.is_dark_theme)
            if highlight_roman and h['roman'] == highlight_roman:
                block.set_highlighted(True)

            block.clicked.connect(self._on_block_clicked)
            block.right_clicked.connect(self._on_block_right_clicked)
            self.blocks.append(block)
            self.blocks_layout.addWidget(block)

    def _on_block_clicked(self, clicked_block):
        self.close_advice_popup()
        for b in self.blocks:
            b.set_highlighted(b is clicked_block)

        # 提取和弦名称中的 root 与 type
        parts = clicked_block.chord_name.split(' ')
        chord_root = parts[0]
        chord_type = ' '.join(parts[1:]) if len(parts) > 1 else 'Maj'

        self.chord_triggered.emit(clicked_block.notes, clicked_block.chord_name, chord_root, chord_type)

    def _on_block_right_clicked(self, clicked_block):
        # 1. 检查当前是否已有打开的浮窗，并判断是否右键了同一个卡片 (Toggle 交互)
        is_same_target = False
        if self.active_advice_popup is not None:
            try:
                target = getattr(self.active_advice_popup, 'target_block', None)
                is_vis = self.active_advice_popup.isVisible()
                if is_vis and target is clicked_block:
                    is_same_target = True
            except Exception:
                is_same_target = False
            self.close_advice_popup()

        if is_same_target:
            return

        # 2. 获取该调式该级数的深度理论与实战和声建议
        advice_data = get_chord_advice_data(clicked_block.mode_name, clicked_block.degree_idx)
        if not advice_data:
            return

        # 3. 弹出新浮窗卡片并精确定位在卡片周围
        popup = ChordAdvicePopup(
            advice_data=advice_data,
            chord_name=clicked_block.chord_name,
            roman=clicked_block.roman,
            mode_name=clicked_block.mode_name,
            target_block=clicked_block,
            is_dark=self.is_dark_theme,
            parent=self
        )
        popup.closed.connect(self._on_popup_closed)
        self.active_advice_popup = popup
        popup.show_near_block(clicked_block)

    def _on_popup_closed(self):
        """浮窗关闭时自动置空引用，防止悬垂指针"""
        if self.active_advice_popup is self.sender() or self.sender() is None:
            self.active_advice_popup = None
