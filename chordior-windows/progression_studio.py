"""
Progression Studio - 高级和弦进行编排工坊
支持自定义拍数卡片、平滑动画拖拽排序、框选多选、Ctrl+Z/C/V、BPM 调速、循环试听与 MIDI 导出。
"""

import json
from PyQt5.QtCore import (QByteArray, QEasingCurve, QEvent, QMimeData,
                             QParallelAnimationGroup, QPoint, QPropertyAnimation,
                             QRect, QSettings, QSize, Qt, QTimer, pyqtSignal)
from PyQt5.QtGui import (QBrush, QColor, QCursor, QDrag, QFont, QIntValidator,
                         QKeySequence, QPainter, QPixmap)
from PyQt5.QtWidgets import (QAction, QApplication, QCheckBox, QComboBox,
                             QDialog, QFileDialog, QFormLayout, QFrame,
                             QGraphicsOpacityEffect, QHBoxLayout, QLabel,
                             QLineEdit, QMenu, QMessageBox, QPushButton,
                             QRubberBand, QScrollArea, QSlider, QSpinBox,
                             QTextEdit, QVBoxLayout, QWidget)
from midi_utils import build_progression_midi, export_progression_as_text
from presets_dialog import PresetsDialog
from theory_engine import NOTE_NAMES


class ModernChordBlock(QFrame):
    """时间线上的现代化和弦卡片"""

    clicked = pyqtSignal(list, str)  # (音名, 和弦名)
    delete_requested = pyqtSignal(object)
    data_changed = pyqtSignal()

    def __init__(self, notes, label="Chord", beats=2, scale_factor=1.0, parent=None):
        super().__init__(parent)
        self.notes = list(notes)
        self.beats = int(beats)
        self.base_w = 95
        self.base_h = 80
        self.scale_factor = scale_factor
        self.selected = False
        self.active_playing = False
        self.drag_start_pos = None

        self.setObjectName("ChordBlock")
        self.setCursor(Qt.PointingHandCursor)
        self.setContextMenuPolicy(Qt.CustomContextMenu)
        self.customContextMenuRequested.connect(self.show_context_menu)

        self.init_ui(label)
        self.apply_zoom(scale_factor)
        self.apply_theme(True)

    def apply_theme(self, is_dark):
        self.is_dark = is_dark
        if is_dark:
            self.setStyleSheet("""
                QFrame#ChordBlock {
                    background-color: #1a1c23;
                    border: 1.5px solid #2d323e;
                    border-radius: 8px;
                }
                QFrame#ChordBlock:hover {
                    border-color: #38bdf8;
                    background-color: #20242e;
                }
                QFrame#ChordBlock[selected="true"] {
                    border: 2px solid #38bdf8;
                    background-color: #1e293b;
                }
                QFrame#ChordBlock[active="true"] {
                    border: 2px solid #00f0ff;
                    background-color: #162a3d;
                }
                QPushButton#DeleteBlockBtn {
                    border: none;
                    border-radius: 9px;
                    padding: 0px;
                    margin: 0px;
                    font-size: 13px;
                    font-weight: bold;
                    line-height: 18px;
                    color: #94a3b8;
                    background: transparent;
                }
                QPushButton#DeleteBlockBtn:hover {
                    color: #ffffff;
                    background-color: #ef4444;
                }
            """)
            self.label_edit.setStyleSheet("color: #f8fafc; background: transparent; font-weight: bold;")
            self.note_label.setStyleSheet("color: #94a3b8; background: transparent;")
            self.beats_combo.setStyleSheet("""
                QComboBox {
                    font-size: 10px;
                    padding: 1px 4px;
                    min-width: 42px;
                    border: 1px solid #3d4251;
                    border-radius: 4px;
                    background: #1c1e24;
                    color: #3d84ff;
                }
            """)
        else:
            self.setStyleSheet("""
                QFrame#ChordBlock {
                    background-color: #ffffff;
                    border: 1.5px solid #cbd5e1;
                    border-radius: 8px;
                }
                QFrame#ChordBlock:hover {
                    border-color: #0284c7;
                    background-color: #f0f9ff;
                }
                QFrame#ChordBlock[selected="true"] {
                    border: 2px solid #0284c7;
                    background-color: #e0f2fe;
                }
                QFrame#ChordBlock[active="true"] {
                    border: 2px solid #0ea5e9;
                    background-color: #bae6fd;
                }
                QPushButton#DeleteBlockBtn {
                    border: none;
                    border-radius: 9px;
                    padding: 0px;
                    margin: 0px;
                    font-size: 13px;
                    font-weight: bold;
                    line-height: 18px;
                    color: #94a3b8;
                    background: transparent;
                }
                QPushButton#DeleteBlockBtn:hover {
                    color: #ffffff;
                    background-color: #ef4444;
                }
            """)
            self.label_edit.setStyleSheet("color: #0f172a; background: transparent; font-weight: bold;")
            self.note_label.setStyleSheet("color: #64748b; background: transparent;")
            self.beats_combo.setStyleSheet("""
                QComboBox {
                    font-size: 10px;
                    padding: 1px 4px;
                    min-width: 42px;
                    border: 1px solid #cbd5e1;
                    border-radius: 4px;
                    background: #f8fafc;
                    color: #0284c7;
                }
            """)
        self.setStyle(self.style())
        self.update()

    def init_ui(self, initial_label):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        layout.setSpacing(2)

        # 顶部栏：拍数切换 + 删除按钮
        top_row = QHBoxLayout()
        top_row.setSpacing(2)

        self.beats_combo = QComboBox(self)
        self.beats_combo.addItems(["1拍", "2拍", "3拍", "4拍"])
        self.beats_combo.setCurrentIndex(min(3, max(0, self.beats - 1)))
        self.beats_combo.setStyleSheet("""
            QComboBox {
                font-size: 10px;
                padding: 1px 4px;
                min-width: 42px;
                border: 1px solid #3d4251;
                border-radius: 4px;
                background: #1c1e24;
                color: #3d84ff;
            }
        """)
        self.beats_combo.currentIndexChanged.connect(self.on_beats_changed)
        top_row.addWidget(self.beats_combo)
        top_row.addStretch()

        self.del_btn = QPushButton("×", self)
        self.del_btn.setObjectName("DeleteBlockBtn")
        self.del_btn.setFixedSize(18, 18)
        self.del_btn.setCursor(Qt.PointingHandCursor)
        self.del_btn.clicked.connect(lambda: self.delete_requested.emit(self))
        top_row.addWidget(self.del_btn)
        layout.addLayout(top_row)

        # 中部：和弦名称（改为 QLabel，居中展示并开启鼠标穿透，彻底解决阻碍拖动和误触问题）
        self.label_edit = QLabel(initial_label, self)
        self.label_edit.setObjectName("ChordBlockLabel")
        self.label_edit.setAlignment(Qt.AlignCenter)
        self.label_edit.setFont(QFont("Segoe UI", 12, QFont.Bold))
        self.label_edit.setStyleSheet("color: #f8fafc; background: transparent; font-weight: bold;")
        self.label_edit.setAttribute(Qt.WA_TransparentForMouseEvents, True)
        layout.addWidget(self.label_edit)

        # 底部：构成音符简写
        clean_notes = ' '.join([n.split('/')[0] for n in self.notes])
        self.note_label = QLabel(clean_notes, self)
        self.note_label.setObjectName("ChordBlockNote")
        self.note_label.setAlignment(Qt.AlignCenter)
        self.note_label.setFont(QFont("Consolas", 8))
        self.note_label.setAttribute(Qt.WA_TransparentForMouseEvents, True)
        layout.addWidget(self.note_label)

    def on_beats_changed(self, index):
        self.beats = index + 1
        self.data_changed.emit()

    def get_data(self):
        return {
            'notes': list(self.notes),
            'label': self.label_edit.text().strip(),
            'beats': self.beats
        }

    def set_selected(self, selected):
        if self.selected != selected:
            self.selected = selected
            self.setProperty("selected", "true" if selected else "false")
            self.setStyle(self.style())
            self.update()

    def set_active_playing(self, active):
        if self.active_playing != active:
            self.active_playing = active
            self.setProperty("active", "true" if active else "false")
            self.setStyle(self.style())
            self.update()

    def apply_zoom(self, scale):
        self.scale_factor = scale
        w = int(self.base_w * scale)
        h = int(self.base_h * scale)
        self.setFixedSize(w, h)
        main_font_size = max(9, int(12 * scale))
        sub_font_size = max(7, int(8.5 * scale))
        self.label_edit.setFont(QFont("Segoe UI", main_font_size, QFont.Bold))
        self.note_label.setFont(QFont("Consolas", sub_font_size))

    def show_context_menu(self, pos):
        menu = QMenu(self)
        del_act = menu.addAction("🗑 删除此和弦 (Delete)")
        copy_act = menu.addAction("📋 复制 (Copy)")
        rename_act = menu.addAction("✏️ 重命名和弦 (Rename)")
        menu.addSeparator()
        
        # 移调选项
        up_act = menu.addAction("⬆ 向上移半音 (+1 Semitone)")
        down_act = menu.addAction("⬇ 向下移半音 (-1 Semitone)")

        action = menu.exec_(self.mapToGlobal(pos))
        if action == del_act:
            self.delete_requested.emit(self)
        elif action == copy_act:
            if hasattr(self.parent(), 'copy_selection'):
                self.set_selected(True)
                self.parent().copy_selection()
        elif action == rename_act:
            from PyQt5.QtWidgets import QInputDialog
            new_text, ok = QInputDialog.getText(self, "重命名和弦", "输入新的和弦名称:", text=self.label_edit.text())
            if ok and new_text.strip():
                self.label_edit.setText(new_text.strip())
                self.data_changed.emit()
        elif action in [up_act, down_act]:
            shift = 1 if action == up_act else -1
            from theory_engine import NOTE_NAMES
            new_notes = []
            for n in self.notes:
                idx = (NOTE_NAMES.index(n) + shift) % 12 if n in NOTE_NAMES else 0
                new_notes.append(NOTE_NAMES[idx])
            self.notes = new_notes
            self.note_label.setText(' '.join([n.split('/')[0] for n in new_notes]))
            self.data_changed.emit()

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.drag_start_pos = event.pos()
            is_ctrl = bool(event.modifiers() & Qt.ControlModifier)
            if is_ctrl:
                self.set_selected(not self.selected)
            else:
                if self.parent() and hasattr(self.parent(), 'handle_block_clicked'):
                    self.parent().handle_block_clicked(self)
                self.set_selected(True)
            
            self.clicked.emit(self.notes, self.label_edit.text())
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if not (event.buttons() & Qt.LeftButton) or self.drag_start_pos is None:
            return
        if (event.pos() - self.drag_start_pos).manhattanLength() < QApplication.startDragDistance():
            return

        if self.parent() and hasattr(self.parent(), 'start_reorder_drag'):
            self.parent().start_reorder_drag(self)
            self.drag_start_pos = None


class FlowLayoutWidget(QWidget):
    """支持平滑动画拖拽、框选、撤销重做与缩放的流式和弦容器"""

    order_changed = pyqtSignal()
    size_changed = pyqtSignal(int, int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setAcceptDrops(True)
        self.blocks = []
        self.zoom_level = 1.0
        self.base_w = 95
        self.base_h = 80
        self.margin = 10
        self.target_index = -1
        self.dragging_blocks = []
        self.anim_group = QParallelAnimationGroup(self)
        self.selection_rect = QRubberBand(QRubberBand.Rectangle, self)
        self.rubberband_origin = QPoint()
        self.is_dark = True

    def apply_theme(self, is_dark):
        self.is_dark = is_dark
        if is_dark:
            self.selection_rect.setStyleSheet("border: 1.5px dashed #00f0ff; background: rgba(0, 240, 255, 35);")
        else:
            self.selection_rect.setStyleSheet("border: 1.5px dashed #0284c7; background: rgba(2, 132, 199, 35);")
        for b in self.blocks:
            b.apply_theme(is_dark)

    def handle_block_clicked(self, clicked_block):
        self.setFocus()
        for b in self.blocks:
            if b != clicked_block:
                b.set_selected(False)

    def mousePressEvent(self, event):
        self.setFocus()
        if event.button() == Qt.LeftButton:
            child = self.childAt(event.pos())
            if not child:
                # 点击空白处：取消所有选中并启动框选
                for b in self.blocks:
                    b.set_selected(False)
                self.rubberband_origin = event.pos()
                self.selection_rect.setGeometry(QRect(self.rubberband_origin, QSize()))
                self.selection_rect.show()
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if self.selection_rect.isVisible():
            rect = QRect(self.rubberband_origin, event.pos()).normalized()
            self.selection_rect.setGeometry(rect)
            for b in self.blocks:
                b.set_selected(rect.intersects(b.geometry()))
        super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event):
        if self.selection_rect.isVisible():
            self.selection_rect.hide()
        super().mouseReleaseEvent(event)

    def add_block(self, block, index=None):
        self.add_blocks_batch([block], index=index, animated=True)

    def add_blocks_batch(self, blocks, index=None, animated=True):
        if not blocks:
            return
        for i, block in enumerate(blocks):
            block.setParent(self)
            block.apply_theme(self.is_dark)
            target_idx = (index + i) if (index is not None and 0 <= index <= len(self.blocks)) else len(self.blocks)
            self.blocks.insert(target_idx, block)
            block.show()
            block.delete_requested.connect(self.remove_block)
            block.data_changed.connect(lambda: self.order_changed.emit())

        self.update_layout(animated=animated)
        self.order_changed.emit()

    def remove_block(self, block):
        if block in self.blocks:
            self.blocks.remove(block)
            block.deleteLater()
            self.update_layout(animated=True)
            self.order_changed.emit()

    def update_layout(self, animated=False):
        if not self.parent():
            return

        bw = int(self.base_w * self.zoom_level)
        bh = int(self.base_h * self.zoom_level)
        available_w = max(200, self.parent().width() - 24)
        cols = max(1, available_w // (bw + self.margin))

        self.anim_group.stop()
        self.anim_group.clear()

        static_blocks = [b for b in self.blocks if b not in self.dragging_blocks]
        layout_list = list(static_blocks)

        if self.dragging_blocks and self.target_index != -1:
            insert_pos = min(self.target_index, len(layout_list))
            for i, b in enumerate(self.dragging_blocks):
                layout_list.insert(insert_pos + i, b)

        for i, block in enumerate(layout_list):
            new_x = self.margin + (i % cols) * (bw + self.margin)
            new_y = self.margin + (i // cols) * (bh + self.margin)
            if animated:
                anim = QPropertyAnimation(block, b"pos")
                anim.setDuration(180)
                anim.setEndValue(QPoint(new_x, new_y))
                anim.setEasingCurve(QEasingCurve.OutQuad)
                self.anim_group.addAnimation(anim)
            else:
                block.move(new_x, new_y)

        if animated and self.anim_group.animationCount() > 0:
            self.anim_group.start()

        rows = (len(layout_list) - 1) // cols + 1 if layout_list else 1
        req_h = self.margin + rows * (bh + self.margin) + self.margin
        self.setMinimumHeight(req_h)
        self.size_changed.emit(self.width(), req_h)

    def _calculate_target_index(self, pos):
        bw_total = int(self.base_w * self.zoom_level) + self.margin
        bh_total = int(self.base_h * self.zoom_level) + self.margin
        available_w = max(200, self.parent().width() - 24)
        cols = max(1, available_w // bw_total)

        col = max(0, (pos.x() - self.margin) // bw_total)
        row = max(0, (pos.y() - self.margin) // bh_total)
        if col >= cols:
            col = cols - 1
        
        idx = row * cols + col
        rel_x = (pos.x() - self.margin) % bw_total
        if rel_x > bw_total / 2:
            idx += 1
        
        non_drag_count = len(self.blocks) - len(self.dragging_blocks)
        return max(0, min(non_drag_count, idx))

    def start_reorder_drag(self, source_block):
        sel_blocks = [b for b in self.blocks if b.selected]
        if not sel_blocks or source_block not in sel_blocks:
            sel_blocks = [source_block]

        self.dragging_blocks = sel_blocks
        for b in sel_blocks:
            b.setGraphicsEffect(QGraphicsOpacityEffect(opacity=0.35))

        drag = QDrag(self)
        mime = QMimeData()
        mime.setData("application/x-reorder-blocks", b"reorder")
        drag.setMimeData(mime)
        drag.setPixmap(source_block.grab())
        drag.setHotSpot(QPoint(20, 20))

        drag.exec_(Qt.MoveAction)

        for b in sel_blocks:
            b.setGraphicsEffect(None)
        self.dragging_blocks = []
        self.target_index = -1
        self.update_layout(animated=True)
        self.order_changed.emit()

    def dragEnterEvent(self, event):
        mime = event.mimeData()
        if (mime.hasFormat("application/x-chord-item") or 
            mime.hasFormat("application/x-reorder-blocks") or
            mime.hasFormat("application/x-chord-data")):
            event.acceptProposedAction()

    def dragMoveEvent(self, event):
        new_idx = self._calculate_target_index(event.pos())
        if new_idx != self.target_index:
            self.target_index = new_idx
            self.update_layout(animated=True)
        event.acceptProposedAction()

    def dropEvent(self, event):
        mime = event.mimeData()
        idx = self._calculate_target_index(event.pos())

        if mime.hasFormat("application/x-reorder-blocks"):
            sel_blocks = [b for b in self.blocks if b.selected]
            for b in sel_blocks:
                self.blocks.remove(b)
            for i, b in enumerate(sel_blocks):
                self.blocks.insert(min(idx + i, len(self.blocks)), b)
            event.acceptProposedAction()

        elif mime.hasFormat("application/x-chord-item"):
            data = json.loads(mime.data("application/x-chord-item").data().decode('utf-8'))
            new_block = ModernChordBlock(
                notes=data['notes'],
                label=data.get('label', 'Chord'),
                beats=data.get('beats', 2),
                scale_factor=self.zoom_level
            )
            self.add_block(new_block, index=idx)
            event.acceptProposedAction()

        elif mime.hasFormat("application/x-chord-data"):
            data = json.loads(mime.data("application/x-chord-data").data().decode('utf-8'))
            new_block = ModernChordBlock(
                notes=data['notes'],
                label=data.get('label', 'Chord'),
                beats=2,
                scale_factor=self.zoom_level
            )
            self.add_block(new_block, index=idx)
            event.acceptProposedAction()

        self.target_index = -1
        self.update_layout(animated=True)
        self.order_changed.emit()

    def set_zoom(self, level):
        self.zoom_level = max(0.6, min(2.5, level))
        for b in self.blocks:
            b.apply_zoom(self.zoom_level)
        self.update_layout(animated=False)

    def get_selected_blocks(self):
        return [b for b in self.blocks if b.selected]

    def copy_selection(self):
        sel = self.get_selected_blocks()
        if not sel:
            return
        data = [b.get_data() for b in sel]
        clipboard = QApplication.clipboard()
        mime = QMimeData()
        mime.setData("application/x-copied-chords", json.dumps(data).encode('utf-8'))
        clipboard.setMimeData(mime)

    def paste_selection(self):
        clipboard = QApplication.clipboard()
        mime = clipboard.mimeData()
        if mime.hasFormat("application/x-copied-chords"):
            try:
                data = json.loads(mime.data("application/x-copied-chords").data().decode('utf-8'))
                new_blocks = []
                for item in data:
                    block = ModernChordBlock(item['notes'], item.get('label', 'Chord'), item.get('beats', 2), self.zoom_level)
                    new_blocks.append(block)
                self.add_blocks_batch(new_blocks, animated=True)
            except Exception as e:
                print(f"Paste Error: {e}")

    def delete_selection(self):
        sel = self.get_selected_blocks()
        for b in sel:
            self.remove_block(b)




class BpmSpinControl(QWidget):
    """基于纯数字 QLineEdit + 步进微调按钮的极速 BPM 控制器 (参考拾色器 RGB 方案，彻底杜绝系统箭头乱码，100% 纯正阿拉伯数字)"""
    valueChanged = pyqtSignal(int)

    def __init__(self, value=120, min_val=20, max_val=300, parent=None):
        super().__init__(parent)
        self.min_val = min_val
        self.max_val = max_val
        self._val = int(value)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(2)

        # 减速按钮
        self.dec_btn = QPushButton("－", self)
        self.dec_btn.setFixedSize(22, 26)
        self.dec_btn.setCursor(Qt.PointingHandCursor)
        self.dec_btn.setFocusPolicy(Qt.NoFocus)
        self.dec_btn.clicked.connect(self.step_down)

        # 纯数字文本框 (参考拾色器 RGB 杜绝任何乱码)
        self.edit = QLineEdit(str(self._val), self)
        self.edit.setAlignment(Qt.AlignCenter)
        self.edit.setFixedSize(46, 26)
        self.edit.setValidator(QIntValidator(self.min_val, self.max_val, self))
        self.edit.setFont(QFont("Consolas", 11, QFont.Bold))
        self.edit.textEdited.connect(self._on_text_edited)
        self.edit.editingFinished.connect(self._on_editing_finished)

        # 加速按钮
        self.inc_btn = QPushButton("＋", self)
        self.inc_btn.setFixedSize(22, 26)
        self.inc_btn.setCursor(Qt.PointingHandCursor)
        self.inc_btn.setFocusPolicy(Qt.NoFocus)
        self.inc_btn.clicked.connect(self.step_up)

        # 单位标签
        self.unit_lbl = QLabel("BPM", self)
        self.unit_lbl.setFont(QFont("Segoe UI", 10, QFont.Bold))

        layout.addWidget(self.dec_btn)
        layout.addWidget(self.edit)
        layout.addWidget(self.inc_btn)
        layout.addWidget(self.unit_lbl)

        self.apply_theme(True)

    def step_down(self):
        self.setValue(self.value() - 1)

    def step_up(self):
        self.setValue(self.value() + 1)

    def value(self):
        try:
            return max(self.min_val, min(self.max_val, int(self.edit.text() or self._val)))
        except ValueError:
            return self._val

    def setValue(self, val):
        val = max(self.min_val, min(self.max_val, int(val)))
        if self._val != val or self.edit.text() != str(val):
            self._val = val
            self.edit.setText(str(val))
            self.valueChanged.emit(val)

    def setRange(self, min_val, max_val):
        self.min_val = min_val
        self.max_val = max_val
        self.edit.setValidator(QIntValidator(self.min_val, self.max_val, self))

    def setSuffix(self, suffix):
        self.unit_lbl.setText(suffix.strip())

    def _on_text_edited(self, text):
        if text.isdigit():
            v = int(text)
            if self.min_val <= v <= self.max_val:
                self._val = v
                self.valueChanged.emit(v)

    def _on_editing_finished(self):
        text = self.edit.text()
        if not text.isdigit() or int(text) < self.min_val:
            self.setValue(self.min_val)
        elif int(text) > self.max_val:
            self.setValue(self.max_val)
        else:
            self.setValue(int(text))

    def wheelEvent(self, event):
        delta = 1 if event.angleDelta().y() > 0 else -1
        self.setValue(self.value() + delta)
        event.accept()

    def apply_theme(self, is_dark):
        if is_dark:
            btn_style = """
                QPushButton {
                    background-color: #20232c;
                    color: #cbd5e1;
                    border: 1px solid #363b4a;
                    border-radius: 4px;
                    font-weight: bold;
                    font-size: 13px;
                }
                QPushButton:hover {
                    background-color: #38bdf8;
                    color: #0f172a;
                    border-color: #38bdf8;
                }
            """
            self.dec_btn.setStyleSheet(btn_style)
            self.inc_btn.setStyleSheet(btn_style)
            self.edit.setStyleSheet("""
                QLineEdit {
                    background-color: #16181f;
                    color: #38bdf8;
                    border: 1px solid #3b4254;
                    border-radius: 4px;
                    font-family: "Consolas", monospace;
                    font-size: 12px;
                    font-weight: bold;
                }
                QLineEdit:focus {
                    border: 1.5px solid #38bdf8;
                }
            """)
            self.unit_lbl.setStyleSheet("color: #94a3b8; font-weight: bold; margin-left: 2px;")
        else:
            btn_style = """
                QPushButton {
                    background-color: #f1f5f9;
                    color: #334155;
                    border: 1px solid #cbd5e1;
                    border-radius: 4px;
                    font-weight: bold;
                    font-size: 13px;
                }
                QPushButton:hover {
                    background-color: #0284c7;
                    color: #ffffff;
                    border-color: #0284c7;
                }
            """
            self.dec_btn.setStyleSheet(btn_style)
            self.inc_btn.setStyleSheet(btn_style)
            self.edit.setStyleSheet("""
                QLineEdit {
                    background-color: #ffffff;
                    color: #0284c7;
                    border: 1px solid #cbd5e1;
                    border-radius: 4px;
                    font-family: "Consolas", monospace;
                    font-size: 12px;
                    font-weight: bold;
                }
                QLineEdit:focus {
                    border: 1.5px solid #0284c7;
                }
            """)
            self.unit_lbl.setStyleSheet("color: #475569; font-weight: bold; margin-left: 2px;")


class SavePresetDialog(QDialog):
    """保存和弦进行为预设的对话框"""
    def __init__(self, chords_data, current_bpm=120, parent=None):
        super().__init__(parent)
        self.chords_data = chords_data
        self.current_bpm = current_bpm
        self.setWindowTitle("💾 存为预设 (Save as Preset)")
        self.resize(430, 320)
        self.init_ui()
        is_dark = parent.is_dark if parent and hasattr(parent, 'is_dark') else True
        self.apply_theme(is_dark)

    def apply_theme(self, is_dark):
        if is_dark:
            self.setStyleSheet("""
                SavePresetDialog {
                    background-color: #1e222b;
                    color: #f8fafc;
                }
                QLabel {
                    color: #cbd5e1;
                }
                QLineEdit, QTextEdit {
                    background-color: #16181f;
                    color: #f8fafc;
                    border: 1px solid #3b4254;
                    border-radius: 6px;
                    padding: 4px 8px;
                }
            """)
        else:
            self.setStyleSheet("""
                SavePresetDialog {
                    background-color: #ffffff;
                    color: #0f172a;
                }
                QLabel {
                    color: #334155;
                }
                QLineEdit, QTextEdit {
                    background-color: #f8fafc;
                    color: #0f172a;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                    padding: 4px 8px;
                }
            """)

    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(16, 16, 16, 16)
        layout.setSpacing(10)

        form = QFormLayout()
        form.setSpacing(8)

        self.name_edit = QLineEdit(f"我的进行 ({len(self.chords_data)}和弦)")
        form.addRow("预设名称:", self.name_edit)

        self.cat_edit = QLineEdit("📁 我的自定义预设 (My Presets)")
        form.addRow("预设分类:", self.cat_edit)

        bpm_label = QLabel(f"{self.current_bpm} BPM")
        form.addRow("进行速度:", bpm_label)

        layout.addLayout(form)

        layout.addWidget(QLabel("📝 个人标注 / 心得备忘 (Note & Desc):"))
        self.desc_edit = QTextEdit()
        self.desc_edit.setPlaceholderText("在此记录该进行的风格定位、配器心得、调式情绪或参考曲目...")
        layout.addWidget(self.desc_edit)

        btn_row = QHBoxLayout()
        btn_row.addStretch()
        cancel_btn = QPushButton("取消")
        cancel_btn.clicked.connect(self.reject)
        save_btn = QPushButton("✔ 保存到预设库")
        save_btn.setObjectName("PrimaryButton")
        save_btn.clicked.connect(self.on_save)
        btn_row.addWidget(cancel_btn)
        btn_row.addWidget(save_btn)
        layout.addLayout(btn_row)

    def on_save(self):
        name = self.name_edit.text().strip()
        if not name:
            QMessageBox.warning(self, "提示", "请输入预设名称！")
            return
        
        category = self.cat_edit.text().strip() or "📁 我的自定义预设 (My Presets)"
        desc = self.desc_edit.toPlainText().strip()
        
        preset_item = {
            'name': name,
            'category': category,
            'desc': desc,
            'bpm': self.current_bpm,
            'chords': self.chords_data,
            'is_user': True
        }

        # 保存到 QSettings (统一主程序配置域并兼容读取)
        store = QSettings("TaketoAudio", "ChordStudioPro")
        raw = store.value("user_progression_presets", "")
        if not raw:
            raw = QSettings("ChordStudio", "ChordStudioApp").value("user_progression_presets", "[]")
        try:
            user_presets = json.loads(raw)
            if not isinstance(user_presets, list):
                user_presets = []
        except Exception:
            user_presets = []

        user_presets.append(preset_item)
        store.setValue("user_progression_presets", json.dumps(user_presets, ensure_ascii=False))

        QMessageBox.information(self, "成功", f"和弦进行【{name}】已成功保存至预设库！\n随时可在预设库中载入或查阅标注。")
        self.accept()


class ProgressionStudioWidget(QWidget):
    """和弦进行编排工坊主窗口组件"""

    preview_chord_requested = pyqtSignal(list, str)  # (音名列表, 和弦名)

    def __init__(self, synth_engine=None, parent=None):
        super().__init__(parent, Qt.Window)
        self.synth = synth_engine
        self.setWindowTitle("Chord Progression Studio - 和弦进行编排工坊")
        self.resize(960, 520)

        self.settings = {'bpm': 120, 'loop': True, 'open_voicing': False}
        self.is_playing = False
        self.play_idx = -1
        self.undo_stack = []
        self.redo_stack = []
        self.max_history = 20

        self.play_timer = QTimer(self)
        self.play_timer.timeout.connect(self.play_step)

        # 读取置顶偏好
        store = QSettings("TaketoAudio", "ChordStudioPro")
        self.is_pinned = bool(store.value("prog_studio_pinned", False, type=bool))
        if self.is_pinned:
            self.setWindowFlag(Qt.WindowStaysOnTopHint, True)

        # 检测主程序当前主题并自适应 (优先从父窗口拿实时状态，次选 QSettings 记录)
        is_dark = True
        if parent and hasattr(parent, 'is_dark_theme'):
            is_dark = parent.is_dark_theme
        elif store.contains("is_dark_theme"):
            is_dark = store.value("is_dark_theme", True, type=bool)
        self.is_dark = is_dark

        self.init_ui()
        self.apply_theme(self.is_dark)
        self.flow_widget.order_changed.connect(self.save_state)

    def init_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(15, 15, 15, 15)
        main_layout.setSpacing(12)

        # 1. 顶部专业工具栏
        toolbar = QHBoxLayout()
        toolbar.setSpacing(8)

        self.add_curr_btn = QPushButton("＋ 添加当前和弦 (Add Current)")
        self.add_curr_btn.setObjectName("PrimaryButton")

        # 单键播放/暂停按钮 (已删除多余的 Stop 按钮)
        self.play_btn = QPushButton("▶ 播放进行 (Play)")
        self.play_btn.setObjectName("PlayActionButton")
        self.play_btn.clicked.connect(self.toggle_play)

        self.loop_check = QCheckBox("循环 (Loop)")
        self.loop_check.setChecked(True)
        self.loop_check.stateChanged.connect(lambda s: self.settings.update({'loop': s == Qt.Checked}))

        # 速度控制栏 (采用拾色器同款纯文本 QLineEdit + 步进微调按钮方案，彻底杜绝系统字体乱码)
        toolbar.addWidget(self.add_curr_btn)
        toolbar.addWidget(self.play_btn)
        toolbar.addWidget(self.loop_check)
        
        toolbar.addSpacing(6)
        self.bpm_label = QLabel("速度:")
        toolbar.addWidget(self.bpm_label)
        self.bpm_spin = BpmSpinControl(value=120, min_val=20, max_val=300, parent=self)
        self.bpm_spin.valueChanged.connect(lambda v: self.settings.update({'bpm': v}))
        toolbar.addWidget(self.bpm_spin)

        toolbar.addStretch()

        # 窗口置顶控制按钮
        self.pin_btn = QPushButton("📌 已置顶" if self.is_pinned else "📌 置顶")
        self.pin_btn.setCheckable(True)
        self.pin_btn.setChecked(self.is_pinned)
        if self.is_pinned:
            self.pin_btn.setStyleSheet("background-color: #0284c7; color: #ffffff; font-weight: bold;")
        self.pin_btn.clicked.connect(self.toggle_pin)
        toolbar.addWidget(self.pin_btn)

        # 存为预设、预设库、导出与清空
        self.save_preset_btn = QPushButton("💾 存为预设")
        self.save_preset_btn.clicked.connect(self.save_as_preset)
        toolbar.addWidget(self.save_preset_btn)

        self.presets_btn = QPushButton("📚 预设库 (Presets)")
        self.presets_btn.clicked.connect(self.open_presets_dialog)
        toolbar.addWidget(self.presets_btn)

        self.export_midi_btn = QPushButton("💾 导出 MIDI")
        self.export_midi_btn.setObjectName("PrimaryButton")
        self.export_midi_btn.clicked.connect(self.export_to_midi)
        toolbar.addWidget(self.export_midi_btn)

        self.export_text_btn = QPushButton("📋 导出文本谱")
        self.export_text_btn.clicked.connect(self.export_to_text)
        toolbar.addWidget(self.export_text_btn)

        self.clear_btn = QPushButton("🗑 清空 (Clear)")
        self.clear_btn.setObjectName("DangerButton")
        self.clear_btn.clicked.connect(self.clear_all)
        toolbar.addWidget(self.clear_btn)

        main_layout.addLayout(toolbar)

        # 2. 中部时间线可滚动区域
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setStyleSheet("QScrollArea { border: 1px solid #313540; border-radius: 10px; background-color: #17181e; }")

        self.flow_widget = FlowLayoutWidget(self)
        self.scroll_area.setWidget(self.flow_widget)
        main_layout.addWidget(self.scroll_area, stretch=1)

        # 3. 底部状态提示
        status_bar = QHBoxLayout()
        self.tip_label = QLabel("💡 提示: 支持拖拽排序、框选多选、Ctrl+Z撤销、Ctrl+C/V复制粘贴、Ctrl+滚轮缩放")
        self.tip_label.setStyleSheet("color: #718093; font-size: 11px;")
        status_bar.addWidget(self.tip_label)
        status_bar.addStretch()

        self.chord_count_label = QLabel("共 0 个和弦")
        self.chord_count_label.setStyleSheet("color: #3d84ff; font-weight: bold;")
        status_bar.addWidget(self.chord_count_label)
        main_layout.addLayout(status_bar)

        QTimer.singleShot(50, self.save_state)

    def apply_theme(self, is_dark):
        self.is_dark = is_dark
        if is_dark:
            self.setStyleSheet("""
                ProgressionStudioWidget {
                    background-color: #1e222b;
                    color: #f8fafc;
                }
                QLabel {
                    color: #cbd5e1;
                }
                QCheckBox {
                    color: #cbd5e1;
                }
                QPushButton {
                    background-color: #262a35;
                    color: #cbd5e1;
                    border: 1px solid #363b4a;
                    border-radius: 6px;
                    padding: 5px 12px;
                    font-size: 12px;
                }
                QPushButton:hover {
                    background-color: #343b4d;
                    color: #ffffff;
                }
                QPushButton#PrimaryButton {
                    background-color: #0284c7;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#PrimaryButton:hover {
                    background-color: #0369a1;
                }
                QPushButton#PlayActionButton {
                    background-color: #10b981;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#PlayActionButton:hover {
                    background-color: #059669;
                }
                QPushButton#DangerButton {
                    background-color: #ef4444;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#DangerButton:hover {
                    background-color: #dc2626;
                }
            """)
            self.scroll_area.setStyleSheet("QScrollArea { border: 1px solid #313540; border-radius: 10px; background-color: #17181e; }")
            self.tip_label.setStyleSheet("color: #718093; font-size: 11px;")
            self.chord_count_label.setStyleSheet("color: #38bdf8; font-weight: bold;")
        else:
            self.setStyleSheet("""
                ProgressionStudioWidget {
                    background-color: #f8fafc;
                    color: #0f172a;
                }
                QLabel {
                    color: #334155;
                }
                QCheckBox {
                    color: #334155;
                }
                QPushButton {
                    background-color: #ffffff;
                    color: #334155;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                    padding: 5px 12px;
                    font-size: 12px;
                }
                QPushButton:hover {
                    background-color: #f1f5f9;
                    color: #0f172a;
                }
                QPushButton#PrimaryButton {
                    background-color: #0284c7;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#PrimaryButton:hover {
                    background-color: #0369a1;
                }
                QPushButton#PlayActionButton {
                    background-color: #10b981;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#PlayActionButton:hover {
                    background-color: #059669;
                }
                QPushButton#DangerButton {
                    background-color: #ef4444;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#DangerButton:hover {
                    background-color: #dc2626;
                }
            """)
            self.scroll_area.setStyleSheet("QScrollArea { border: 1.5px solid #cbd5e1; border-radius: 10px; background-color: #f1f5f9; }")
            self.tip_label.setStyleSheet("color: #64748b; font-size: 11px;")
            self.chord_count_label.setStyleSheet("color: #0284c7; font-weight: bold;")

        if hasattr(self, 'bpm_spin'):
            self.bpm_spin.apply_theme(is_dark)
        if hasattr(self, 'flow_widget'):
            self.flow_widget.apply_theme(is_dark)

    def showEvent(self, event):
        super().showEvent(event)
        is_dark = True
        if self.parent() and hasattr(self.parent(), 'is_dark_theme'):
            is_dark = self.parent().is_dark_theme
        else:
            store = QSettings("TaketoAudio", "ChordStudioPro")
            if store.contains("is_dark_theme"):
                is_dark = store.value("is_dark_theme", True, type=bool)
        self.apply_theme(is_dark)

    def add_chord(self, notes, label="Chord", beats=2):
        block = ModernChordBlock(notes, label, beats=beats, scale_factor=self.flow_widget.zoom_level)
        block.clicked.connect(lambda n, name: self.preview_chord_requested.emit(n, name))
        self.flow_widget.add_block(block)
        self.save_state()

    def save_state(self):
        """保存当前时间线数据到撤销栈"""
        current_data = [b.get_data() for b in self.flow_widget.blocks]
        if not self.undo_stack or self.undo_stack[-1] != current_data:
            self.undo_stack.append(current_data)
            if len(self.undo_stack) > self.max_history:
                self.undo_stack.pop(0)
            self.redo_stack.clear()
        self.chord_count_label.setText(f"共 {len(self.flow_widget.blocks)} 个和弦")

    def undo(self):
        if len(self.undo_stack) > 1:
            self.redo_stack.append(self.undo_stack.pop())
            self.restore_state(self.undo_stack[-1])

    def redo(self):
        if self.redo_stack:
            state = self.redo_stack.pop()
            self.undo_stack.append(state)
            self.restore_state(state)

    def restore_state(self, state_data):
        self.stop_play()
        self.flow_widget.blockSignals(True)
        while self.flow_widget.blocks:
            b = self.flow_widget.blocks[0]
            self.flow_widget.blocks.remove(b)
            b.deleteLater()

        new_blocks = []
        for item in state_data:
            block = ModernChordBlock(item['notes'], item.get('label', 'Chord'), item.get('beats', 2), self.flow_widget.zoom_level)
            block.clicked.connect(lambda n, name: self.preview_chord_requested.emit(n, name))
            new_blocks.append(block)

        self.flow_widget.add_blocks_batch(new_blocks, animated=False)
        self.flow_widget.blockSignals(False)
        self.chord_count_label.setText(f"共 {len(self.flow_widget.blocks)} 个和弦")

    def get_progression_data(self):
        return [b.get_data() for b in self.flow_widget.blocks]

    def set_progression_data(self, state_data):
        if state_data is not None:
            self.restore_state(state_data)

    def keyPressEvent(self, event):
        ctrl = event.modifiers() & Qt.ControlModifier
        shift = event.modifiers() & Qt.ShiftModifier

        if ctrl and not shift and event.key() == Qt.Key_Z:
            self.undo()
        elif (ctrl and shift and event.key() == Qt.Key_Z) or (ctrl and event.key() == Qt.Key_Y):
            self.redo()
        elif ctrl and event.key() == Qt.Key_C:
            self.flow_widget.copy_selection()
        elif ctrl and event.key() == Qt.Key_V:
            self.flow_widget.paste_selection()
            self.save_state()
        elif event.key() in [Qt.Key_Delete, Qt.Key_Backspace]:
            self.flow_widget.delete_selection()
            self.save_state()
        elif event.key() == Qt.Key_Space:
            self.toggle_play()
        else:
            super().keyPressEvent(event)

    def wheelEvent(self, event):
        if event.modifiers() & Qt.ControlModifier:
            delta = event.angleDelta().y()
            factor = 1.1 if delta > 0 else 0.9
            new_zoom = self.flow_widget.zoom_level * factor
            self.flow_widget.set_zoom(new_zoom)
            event.accept()
        else:
            super().wheelEvent(event)

    def toggle_play(self):
        if not self.flow_widget.blocks:
            return
        if self.is_playing:
            self.stop_play()
        else:
            self.is_playing = True
            self.play_btn.setText("⏸ 暂停 (Pause)")
            self.play_idx = -1
            self.play_step()

    def stop_play(self):
        self.is_playing = False
        self.play_timer.stop()
        self.play_btn.setText("▶ 播放进行 (Play)")
        for b in self.flow_widget.blocks:
            b.set_active_playing(False)

    def play_step(self):
        if not self.is_playing or not self.flow_widget.blocks:
            return

        # 取消前一个高亮
        if 0 <= self.play_idx < len(self.flow_widget.blocks):
            self.flow_widget.blocks[self.play_idx].set_active_playing(False)

        self.play_idx += 1
        if self.play_idx >= len(self.flow_widget.blocks):
            if self.settings.get('loop', True):
                self.play_idx = 0
            else:
                self.stop_play()
                return

        curr_block = self.flow_widget.blocks[self.play_idx]
        curr_block.set_active_playing(True)
        self.scroll_area.ensureWidgetVisible(curr_block)

        # 触发试听与同步钢琴键盘
        self.preview_chord_requested.emit(curr_block.notes, curr_block.label_edit.text())

        # 计算该和弦当前节拍时长 (ms)
        bpm = max(20, self.settings.get('bpm', 120))
        beats = curr_block.beats
        duration_ms = round((60000.0 / bpm) * beats)
        self.play_timer.start(duration_ms)

    def clear_all(self):
        if not self.flow_widget.blocks:
            return
        self.stop_play()
        while self.flow_widget.blocks:
            b = self.flow_widget.blocks[0]
            self.flow_widget.blocks.remove(b)
            b.deleteLater()
        self.save_state()

    def open_presets_dialog(self):
        dlg = PresetsDialog(synth_engine=self.synth, parent=self)
        dlg.apply_theme(self.is_dark)
        dlg.load_preset_requested.connect(self.load_preset_data)
        dlg.exec_()

    def load_preset_data(self, preset):
        self.stop_play()
        self.clear_all()
        if 'bpm' in preset:
            self.bpm_spin.setValue(int(preset['bpm']))
        for c in preset.get('chords', []):
            self.add_chord(c['notes'], label=c.get('label', 'Chord'), beats=c.get('beats', 2))
        self.save_state()

    def export_to_midi(self):
        if not self.flow_widget.blocks:
            QMessageBox.warning(self, "提示", "时间线上没有可导出的和弦。")
            return
        path, _ = QFileDialog.getSaveFileName(self, "导出 MIDI 文件", "progression.mid", "MIDI Files (*.mid)")
        if not path:
            return
        
        data = [b.get_data() for b in self.flow_widget.blocks]
        midi_bytes = build_progression_midi(data, bpm=self.bpm_spin.value())
        try:
            with open(path, 'wb') as f:
                f.write(midi_bytes)
            QMessageBox.information(self, "成功", f"MIDI 文件已成功导出至：\n{path}")
        except Exception as e:
            QMessageBox.critical(self, "错误", f"导出 MIDI 失败: {e}")

    def export_to_text(self):
        if not self.flow_widget.blocks:
            QMessageBox.warning(self, "提示", "时间线上没有和弦。")
            return
        data = [b.get_data() for b in self.flow_widget.blocks]
        text_str = export_progression_as_text(data, bpm=self.bpm_spin.value())
        
        clipboard = QApplication.clipboard()
        clipboard.setText(text_str)
        QMessageBox.information(self, "成功", "和弦进行谱已成功复制到系统剪贴板！\n可直接粘贴至歌词谱或 Markdown 中。")

    def toggle_pin(self):
        self.is_pinned = self.pin_btn.isChecked()
        QSettings("TaketoAudio", "ChordStudioPro").setValue("prog_studio_pinned", self.is_pinned)
        self.setWindowFlag(Qt.WindowStaysOnTopHint, self.is_pinned)
        if self.is_pinned:
            self.pin_btn.setText("📌 已置顶")
            self.pin_btn.setStyleSheet("background-color: #0284c7; color: #ffffff; font-weight: bold;")
        else:
            self.pin_btn.setText("📌 置顶")
            self.pin_btn.setStyleSheet("")
        self.show()

    def save_as_preset(self):
        if not self.flow_widget.blocks:
            QMessageBox.warning(self, "提示", "时间线上没有和弦，无法存为预设！")
            return
        data = [b.get_data() for b in self.flow_widget.blocks]
        dlg = SavePresetDialog(data, current_bpm=self.bpm_spin.value(), parent=self)
        dlg.exec_()
