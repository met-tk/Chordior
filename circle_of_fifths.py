"""
Circle of Fifths - 现代大尺寸交互式五度圈调式罗盘组件
外圈为大调 (Major Keys)，内圈为关系小调 (Minor Keys)。点击内外圈精准高亮对应扇区并联动切换主调。
"""

import math
from PyQt5.QtCore import QPointF, QRectF, Qt, pyqtSignal
from PyQt5.QtGui import QBrush, QColor, QFont, QPainter, QPainterPath, QPen
from PyQt5.QtWidgets import QWidget
from theory_engine import CIRCLE_OF_FIFTHS, CIRCLE_RELATIVE_MINORS, NOTE_NAMES, normalize_note_name


class CircleOfFifthsWidget(QWidget):
    """五度圈交互组件 (大尺寸、精准扇区高亮)"""

    key_selected = pyqtSignal(str, bool)  # (根音名称, 是否为小调)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(310, 310)
        self.current_sector = 0  # 扇区索引 0~11
        self.is_minor = False
        self.hover_sector = -1
        self.hover_is_inner = False
        self.setMouseTracking(True)

    def set_current_key(self, root_name, is_minor=False):
        """设置当前选中的主调并精准高亮对应扇区"""
        clean_root = root_name.split('/')[0].replace("m", "").strip()
        self.is_minor = is_minor

        if is_minor:
            # 在关系小调列表中寻找扇区
            found = False
            for idx, r_minor in enumerate(CIRCLE_RELATIVE_MINORS):
                if clean_root in r_minor.split('/'):
                    self.current_sector = idx
                    found = True
                    break
            if not found:
                # 兼容查找
                for idx, r_maj in enumerate(CIRCLE_OF_FIFTHS):
                    if clean_root in r_maj.split('/'):
                        self.current_sector = (idx + 9) % 12
                        break
        else:
            # 在大调列表中寻找扇区
            for idx, r_maj in enumerate(CIRCLE_OF_FIFTHS):
                if clean_root in r_maj.split('/'):
                    self.current_sector = idx
                    break

        self.update()

    def get_related_indices(self, center_idx):
        idx_I = center_idx
        idx_IV = (center_idx - 1) % 12
        idx_V = (center_idx + 1) % 12
        return {idx_I, idx_IV, idx_V}

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        w = self.width()
        h = self.height()
        cx = w / 2.0
        cy = h / 2.0

        # 大尺寸半径
        radius_outer = min(cx, cy) - 10.0
        radius_mid = radius_outer * 0.66
        radius_inner = radius_outer * 0.36

        related_family = self.get_related_indices(self.current_sector)
        angle_step = 360.0 / 12.0

        for i in range(12):
            start_angle = -90.0 + (i - 0.5) * angle_step
            mid_angle = math.radians(-90.0 + i * angle_step)

            is_active_outer = (i == self.current_sector and not self.is_minor)
            is_active_inner = (i == self.current_sector and self.is_minor)
            is_family = (i in related_family)

            # 1. 外圈扇区 (大调)
            path_outer = QPainterPath()
            path_outer.arcMoveTo(cx - radius_outer, cy - radius_outer, radius_outer * 2, radius_outer * 2, -start_angle)
            path_outer.arcTo(cx - radius_outer, cy - radius_outer, radius_outer * 2, radius_outer * 2, -start_angle, -angle_step)
            path_outer.arcTo(cx - radius_mid, cy - radius_mid, radius_mid * 2, radius_mid * 2, -start_angle - angle_step, angle_step)
            path_outer.closeSubpath()

            if is_active_outer:
                bg_outer = QColor("#f97316")
            elif is_family and not self.is_minor:
                bg_outer = QColor("#222c3c")
            elif i == self.hover_sector and not self.hover_is_inner:
                bg_outer = QColor("#2a3548")
            else:
                bg_outer = QColor("#141720")

            painter.setPen(QPen(QColor("#0d0f14"), 1.8))
            painter.setBrush(QBrush(bg_outer))
            painter.drawPath(path_outer)

            # 外圈文字
            major_name = CIRCLE_OF_FIFTHS[i].split('/')[0]
            label_r = (radius_outer + radius_mid) / 2.0
            tx = cx + label_r * math.cos(mid_angle)
            ty = cy + label_r * math.sin(mid_angle)

            painter.setPen(QPen(QColor("#ffffff" if is_active_outer or (is_family and not self.is_minor) else "#cbd5e1")))
            painter.setFont(QFont("Segoe UI", 10, QFont.Bold if is_active_outer else QFont.Normal))
            rect_t = QRectF(tx - 20, ty - 12, 40, 24)
            painter.drawText(rect_t, Qt.AlignCenter, major_name)

            # 2. 内圈扇区 (关系小调)
            path_inner = QPainterPath()
            path_inner.arcMoveTo(cx - radius_mid, cy - radius_mid, radius_mid * 2, radius_mid * 2, -start_angle)
            path_inner.arcTo(cx - radius_mid, cy - radius_mid, radius_mid * 2, radius_mid * 2, -start_angle, -angle_step)
            path_inner.arcTo(cx - radius_inner, cy - radius_inner, radius_inner * 2, radius_inner * 2, -start_angle - angle_step, angle_step)
            path_inner.closeSubpath()

            if is_active_inner:
                bg_inner = QColor("#0ea5e9")
            elif is_family and self.is_minor:
                bg_inner = QColor("#1e293b")
            elif i == self.hover_sector and self.hover_is_inner:
                bg_inner = QColor("#223044")
            else:
                bg_inner = QColor("#0f1218")

            painter.setBrush(QBrush(bg_inner))
            painter.drawPath(path_inner)

            # 内圈文字
            minor_name = f"{CIRCLE_RELATIVE_MINORS[i].split('/')[0]}m"
            label_r_in = (radius_mid + radius_inner) / 2.0
            tx_in = cx + label_r_in * math.cos(mid_angle)
            ty_in = cy + label_r_in * math.sin(mid_angle)

            painter.setPen(QPen(QColor("#ffffff" if is_active_inner or (is_family and self.is_minor) else "#94a3b8")))
            painter.setFont(QFont("Segoe UI", 9, QFont.Bold if is_active_inner else QFont.Normal))
            rect_t_in = QRectF(tx_in - 20, ty_in - 10, 40, 20)
            painter.drawText(rect_t_in, Qt.AlignCenter, minor_name)

        # 3. 中心圆盘
        painter.setPen(QPen(QColor("#090b0e"), 2))
        painter.setBrush(QBrush(QColor("#090b0e")))
        painter.drawEllipse(QPointF(cx, cy), radius_inner, radius_inner)

        # 当前调中心字样
        if self.is_minor:
            cur_name = f"{CIRCLE_RELATIVE_MINORS[self.current_sector].split('/')[0]}m"
            center_color = QColor("#0ea5e9")
        else:
            cur_name = CIRCLE_OF_FIFTHS[self.current_sector].split('/')[0]
            center_color = QColor("#f97316")

        painter.setPen(QPen(center_color))
        painter.setFont(QFont("Segoe UI", 12, QFont.Bold))
        painter.drawText(QRectF(cx - 35, cy - 20, 70, 22), Qt.AlignCenter, cur_name)

        painter.setPen(QPen(QColor("#64748b")))
        painter.setFont(QFont("Microsoft YaHei", 8))
        painter.drawText(QRectF(cx - 35, cy + 4, 70, 16), Qt.AlignCenter, "调式罗盘")

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            cx = self.width() / 2.0
            cy = self.height() / 2.0
            dx = event.pos().x() - cx
            dy = event.pos().y() - cy
            dist = math.sqrt(dx * dx + dy * dy)

            radius_outer = min(cx, cy) - 10.0
            radius_mid = radius_outer * 0.66
            radius_inner = radius_outer * 0.36

            if radius_inner <= dist <= radius_outer:
                angle_deg = math.degrees(math.atan2(dy, dx))
                norm_angle = (angle_deg + 90.0 + 15.0) % 360.0
                sector_idx = int(norm_angle // 30.0) % 12

                is_inner = (dist < radius_mid)
                self.current_sector = sector_idx
                self.is_minor = is_inner
                self.hover_sector = sector_idx
                self.hover_is_inner = is_inner
                self.update()

                if is_inner:
                    selected_key = CIRCLE_RELATIVE_MINORS[sector_idx]
                    self.key_selected.emit(selected_key, True)
                else:
                    selected_key = CIRCLE_OF_FIFTHS[sector_idx]
                    self.key_selected.emit(selected_key, False)
                event.accept()

    def mouseMoveEvent(self, event):
        cx = self.width() / 2.0
        cy = self.height() / 2.0
        dx = event.pos().x() - cx
        dy = event.pos().y() - cy
        dist = math.sqrt(dx * dx + dy * dy)
        radius_outer = min(cx, cy) - 10.0
        radius_mid = radius_outer * 0.66
        radius_inner = radius_outer * 0.36

        if radius_inner <= dist <= radius_outer:
            angle_deg = math.degrees(math.atan2(dy, dx))
            norm_angle = (angle_deg + 90.0 + 15.0) % 360.0
            sector = int(norm_angle // 30.0) % 12
            is_in = (dist < radius_mid)
            if sector != self.hover_sector or is_in != self.hover_is_inner:
                self.hover_sector = sector
                self.hover_is_inner = is_in
                self.update()
        else:
            if self.hover_sector != -1:
                self.hover_sector = -1
                self.update()
        super().mouseMoveEvent(event)

    def leaveEvent(self, event):
        self.hover_sector = -1
        self.update()
        super().leaveEvent(event)
