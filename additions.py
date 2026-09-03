import json
from PyQt5.QtWidgets import *
from PyQt5.QtCore import *
from PyQt5.QtGui import *


class DraggableHarmonicBtn(QPushButton):
    def __init__(self, text, notes, parent=None):
        super().__init__(text, parent)
        self.notes = notes
        self.drag_start_pos = None

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton: self.drag_start_pos = event.pos()
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if not (event.buttons() & Qt.LeftButton) or self.drag_start_pos is None: return
        if (event.pos() - self.drag_start_pos).manhattanLength() < QApplication.startDragDistance(): return
        drag = QDrag(self)
        mime = QMimeData()
        data_dict = {"notes": self.notes, "label": self.text().split('\n')[-1]}
        mime.setData("application/x-chord-data", json.dumps(data_dict).encode())
        drag.setMimeData(mime)
        drag.setPixmap(self.grab())
        drag.exec_(Qt.CopyAction)


class ProgressionExtension(QObject):
    def __init__(self, window):
        super().__init__(window)
        self.window = window
        self.flow = window.flow_widget
        self.flow.setAcceptDrops(True)
        self.clipboard = []
        self.selection_rect = QRubberBand(QRubberBand.Rectangle, self.flow)
        self.origin = QPoint()
        self.is_moving_blocks = False  # 标记是否正在执行“拖动块排序”逻辑

        self.window.installEventFilter(self)
        self.flow.installEventFilter(self)

    def eventFilter(self, obj, event):
        try:
            # --- 快捷键 ---
            if obj == self.window and event.type() == QEvent.KeyPress:
                ctrl = event.modifiers() & Qt.ControlModifier
                if ctrl and event.key() == Qt.Key_X: self.cut_selected(); return True
                if ctrl and event.key() == Qt.Key_C: self.copy_selected(); return True
                if ctrl and event.key() == Qt.Key_V: self.paste_blocks(); return True
                if event.key() == Qt.Key_Delete: self.delete_selected(); return True

            # --- 鼠标逻辑 (FlowLayout) ---
            if obj == self.flow:
                if event.type() == QEvent.MouseButtonPress and event.button() == Qt.LeftButton:
                    self.origin = event.pos()
                    child = self.flow.childAt(self.origin)
                    block = self._get_chord_block(child)

                    if block:
                        # 如果点击了一个块
                        if not block.selected:
                            if not (event.modifiers() & Qt.ControlModifier):
                                for b in self.flow.blocks: b.set_selected(False)
                            block.set_selected(True)
                            block.clicked.emit(block.notes)

                        # 准备“排序拖拽”
                        self.is_moving_blocks = True
                        return False  # 必须返回 False 以允许后续 MouseMove 捕捉
                    else:
                        # 点击空白处：准备框选
                        self.is_moving_blocks = False
                        if not (event.modifiers() & Qt.ControlModifier):
                            for b in self.flow.blocks: b.set_selected(False)
                        self.selection_rect.setGeometry(QRect(self.origin, QSize()))
                        self.selection_rect.show()
                        return True

                elif event.type() == QEvent.MouseMove:
                    # 1. 框选行为
                    if self.selection_rect.isVisible():
                        rect = QRect(self.origin, event.pos()).normalized()
                        self.selection_rect.setGeometry(rect)
                        for b in self.flow.blocks:
                            b.set_selected(rect.intersects(b.geometry()))
                        return True

                    # 2. 多选排序行为
                    elif self.is_moving_blocks:
                        if (event.pos() - self.origin).manhattanLength() >= QApplication.startDragDistance():
                            self._start_reorder_drag()
                            self.is_moving_blocks = False
                            return True

                elif event.type() == QEvent.MouseButtonRelease:
                    self.selection_rect.hide()
                    self.is_moving_blocks = False

                # --- 拖拽处理 ---
                elif event.type() == QEvent.DragEnter:
                    mime = event.mimeData()
                    if mime.hasFormat("application/x-chord-data") or mime.hasFormat("application/x-reorder"):
                        event.acceptProposedAction()
                        return True


                elif event.type() == QEvent.DragMove:

                    if event.mimeData().hasFormat("application/x-reorder"):

                        # 核心：实时通知 FlowLayout 目标位置

                        pos = event.pos()

                        idx = self.flow._calculate_target_index(pos)

                        # 只有当索引变化时才更新，防止动画抖动

                        if idx != self.flow.target_index:
                            self.flow.target_index = idx

                            # 触发原有的布局刷新动画

                            self.flow.update_layout(animated=True)

                        event.acceptProposedAction()

                        return True

                elif event.type() == QEvent.Drop:
                    self.flow.target_index = -1
                    mime = event.mimeData()
                    idx = self.flow._calculate_target_index(event.pos())

                    if mime.hasFormat("application/x-reorder"):
                        # 处理多选排序
                        sel_blocks = [b for b in self.flow.blocks if b.selected]
                        for b in sel_blocks:
                            self.flow.blocks.remove(b)
                            b.show()  # 恢复显示

                        for i, b in enumerate(sel_blocks):
                            self.flow.blocks.insert(min(idx + i, len(self.flow.blocks)), b)

                        self.flow.update_layout(animated=True)
                        self.window.save_state()
                        event.acceptProposedAction()

                    elif mime.hasFormat("application/x-chord-data"):
                        data = json.loads(mime.data("application/x-chord-data").data().decode())
                        self.window.add_custom_block(data['notes'], data['label'], index=idx)
                        event.acceptProposedAction()

                    self.flow.target_index = -1
                    return True

        except Exception as e:
            print(f"Extension Error: {e}")
        return super().eventFilter(obj, event)

    def _get_chord_block(self, widget):
        curr = widget
        while curr:
            if curr.objectName() == "ChordBlock": return curr
            curr = curr.parent()
        return None

    def _start_reorder_drag(self):
        sel_blocks = [b for b in self.flow.blocks if b.selected]
        if not sel_blocks: return

        drag = QDrag(self.flow)
        mime = QMimeData()
        mime.setData("application/x-reorder", b"move")
        drag.setMimeData(mime)

        # 不要 hide()，否则 FlowLayout 会丢失占位
        # 我们可以给选中的块加一个临时标志或降低亮度
        for b in sel_blocks:
            b.setGraphicsEffect(QGraphicsOpacityEffect(opacity=0.4))

        pixmap = sel_blocks[0].grab()
        drag.setPixmap(pixmap)

        # 这里的 exec_ 是阻塞的，直到放下
        result = drag.exec_(Qt.MoveAction)

        # 结束后清除透明效果
        for b in sel_blocks:
            b.setGraphicsEffect(None)
        self.flow.update_layout(animated=True)
    def copy_selected(self):
        sel = [b for b in self.flow.blocks if getattr(b, 'selected', False)]
        if sel: self.clipboard = [{"notes": list(b.notes), "label": b.label_edit.text()} for b in sel]

    def cut_selected(self):
        self.copy_selected()
        self.delete_selected()

    def paste_blocks(self):
        if not self.clipboard or not hasattr(self.window, 'add_custom_block'): return
        for item in self.clipboard:
            self.window.add_custom_block(item['notes'], item['label'], save=False)
        self.window.save_state()

    def delete_selected(self):
        sel = [b for b in self.flow.blocks if getattr(b, 'selected', False)]
        for b in sel: self.flow.remove_block(b)
        self.window.save_state()