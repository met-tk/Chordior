"""
Guitar Widget - 纯原生 QWidget 现代极速 6 弦 21 品专业吉他指板
支持 21 品全品位单双品记点、和弦组成音与调式组成音双层同心双环光晕体系渲染、根音高亮设置与精确品位点击触发。
"""

from PyQt5.QtCore import QPointF, QRectF, Qt, pyqtSignal
from PyQt5.QtGui import QBrush, QColor, QFont, QLinearGradient, QPainter, QPen
from PyQt5.QtWidgets import QWidget
from theory_engine import NOTE_NAMES, normalize_note_name, note_name_to_pitch_class


DEFAULT_GUITAR_SCHEME = {
    'chord_color': '#38bdf8',
    'scale_color': '#0ea5e9',
    'both_accent_color': '#f59e0b',
    'root_color': '#f97316'
}


class GuitarFretboardView(QWidget):
    """
    6 弦 21 品吉他指板交互视图 (覆盖 3~21 品全记点与 48 键钢琴绝对音高对齐)
    支持触控/点击交互、和弦音明亮发光、调式音阶弱光提示、根音特殊高亮、定制立体珍珠贝母品记与自定义调色盘方案。
    """

    fret_clicked = pyqtSignal(int, str)  # (abs_idx, note_name)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(800, 160)
        self.setFixedHeight(175)

        # 调色盘方案配置
        self.color_scheme = dict(DEFAULT_GUITAR_SCHEME)

        # 琴弦空弦绝对音高索引 (对照 48 键钢琴体系: E2=4, A2=9, D3=14, G3=19, B3=23, E4=28)
        self.string_open_pitches = [28, 23, 19, 14, 9, 4]

        self.num_frets = 21

        # 1. 当前和弦组成音 pitch class 集合 (0~11)
        self.chord_pitch_classes = set()
        self.chord_root_pitch_class = None

        # 2. 当前调式组成音 pitch class 集合 (0~11)
        self.scale_pitch_classes = set()

        # 4. 当前选音精准八度绝对音高集合 (0~47)
        self.exact_active_indices = set()

        # 5. 设置项：是否区分当前八度 (高亮所选八度，淡化其他八度) 与淡化透光比
        self.distinguish_octaves = True
        self.octave_fade_opacity = 0.38

        self.hover_string = -1
        self.hover_fret = -1
        self.setMouseTracking(True)

        self._build_fret_matrix()

    def set_color_scheme(self, scheme):
        if scheme:
            self.color_scheme.update(scheme)
            self.update()

    def _build_fret_matrix(self):
        """构建 6x22 指板音高矩阵 (0品空弦 + 1~21品)"""
        self.fret_matrix = []
        for s_idx in range(6):
            string_frets = []
            base_p = self.string_open_pitches[s_idx]
            for f_idx in range(22):
                abs_p = base_p + f_idx
                norm_p = abs_p % 12
                clamped_idx = max(0, min(47, abs_p))
                note_name = NOTE_NAMES[norm_p].split('/')[0]
                string_frets.append({
                    'string': s_idx,
                    'fret': f_idx,
                    'abs_idx': clamped_idx,
                    'pitch_class': norm_p,
                    'note_name': note_name,
                    'full_name': NOTE_NAMES[norm_p]
                })
            self.fret_matrix.append(string_frets)

    def set_chord_notes(self, notes, root_note=None, exact_indices=None):
        """设置和弦组成音及可选的精准八度绝对音高集合"""
        self.chord_pitch_classes = set()
        for n in notes:
            pc = note_name_to_pitch_class(normalize_note_name(n))
            if pc is not None:
                self.chord_pitch_classes.add(pc)

        if root_note:
            self.chord_root_pitch_class = note_name_to_pitch_class(normalize_note_name(root_note))
        else:
            self.chord_root_pitch_class = None

        if exact_indices is not None:
            self.exact_active_indices = set(exact_indices)
        else:
            self.exact_active_indices = set()

        self.update()

    def set_distinguish_octaves(self, enable):
        """控制是否区分当前八度高亮"""
        self.distinguish_octaves = bool(enable)
        self.update()

    def set_octave_fade_opacity(self, opacity):
        """控制其他八度淡化透光率 (0.15~1.0，达100%时自动视为全量不淡化)"""
        self.octave_fade_opacity = max(0.1, min(1.0, float(opacity)))
        self.distinguish_octaves = (self.octave_fade_opacity < 0.98)
        self.update()

    def set_scale_pitch_classes(self, pitch_classes):
        """设置调式组成音"""
        self.scale_pitch_classes = set(pitch_classes) if pitch_classes else set()
        self.update()

    def set_highlight_root(self, enable):
        """控制是否特殊高亮根音"""
        self.highlight_root = enable
        self.update()

    def highlight_notes(self, notes, root_note=None):
        """兼容旧接口"""
        self.set_chord_notes(notes, root_note)

    def clear(self):
        self.chord_pitch_classes = set()
        self.chord_root_pitch_class = None
        self.scale_pitch_classes = set()
        self.exact_active_indices = set()
        self.update()

    def _get_geometry(self):
        w = self.width()
        h = self.height()

        nut_w = 36.0
        fret_area_w = w - nut_w - 20.0
        fret_w = fret_area_w / 21.0
        string_spacing = (h - 40.0) / 5.0
        top_margin = 20.0

        return nut_w, fret_w, string_spacing, top_margin

    def _hit_test(self, pos):
        nut_w, fret_w, string_spacing, top_margin = self._get_geometry()
        px = pos.x()
        py = pos.y()

        if px < 8.0 or px > self.width() - 8.0:
            return -1, -1
        if py < top_margin - 12.0 or py > top_margin + 5 * string_spacing + 12.0:
            return -1, -1

        s_idx = int(round((py - top_margin) / string_spacing))
        s_idx = max(0, min(5, s_idx))

        if px < nut_w + 6.0:
            f_idx = 0
        else:
            f_idx = int((px - nut_w) / fret_w) + 1
            f_idx = max(0, min(21, f_idx))

        return s_idx, f_idx

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        w = self.width()
        h = self.height()
        nut_w, fret_w, string_spacing, top_margin = self._get_geometry()

        # 1. 指板深色背景
        board_rect = QRectF(nut_w, top_margin - 8, w - nut_w - 15, string_spacing * 5 + 16)
        painter.setPen(QPen(QColor("#0f1218"), 2))
        painter.setBrush(QBrush(QColor("#151821")))
        painter.drawRoundedRect(board_rect, 6, 6)

        # 2. 琴枕 (Nut)
        nut_rect = QRectF(nut_w - 6, top_margin - 8, 6, string_spacing * 5 + 16)
        painter.setPen(Qt.NoPen)
        painter.setBrush(QBrush(QColor("#cbd5e1")))
        painter.drawRoundedRect(nut_rect, 2, 2)

        # 3. 品柱与品记 (Frets & Inlays: 3, 5, 7, 9, 12双点, 15, 17, 19, 21)
        marker_frets = [3, 5, 7, 9, 12, 15, 17, 19, 21]
        for f in range(1, 22):
            fx = nut_w + f * fret_w
            painter.setPen(QPen(QColor("#475569"), 1.8))
            painter.drawLine(QPointF(fx, top_margin - 8), QPointF(fx, top_margin + string_spacing * 5 + 8))

            # 品位数字
            painter.setPen(QPen(QColor("#64748b")))
            painter.setFont(QFont("Consolas", 8, QFont.Bold))
            num_rect = QRectF(fx - fret_w, top_margin + string_spacing * 5 + 9, fret_w, 14)
            painter.drawText(num_rect, Qt.AlignCenter, str(f))

            # 品记：高端定制立体珍珠贝母菱形徽标 (Pearl Diamond Inlay)
            if f in marker_frets:
                dot_cx = fx - (fret_w / 2.0)
                dot_cy = top_margin + 2.5 * string_spacing

                def draw_diamond(cx, cy, hw=4.2, hh=6.8):
                    from PyQt5.QtGui import QPolygonF
                    poly = QPolygonF([
                        QPointF(cx, cy - hh),
                        QPointF(cx + hw, cy),
                        QPointF(cx, cy + hh),
                        QPointF(cx - hw, cy)
                    ])
                    # 珍珠贝母立体光泽渐变
                    grad = QLinearGradient(QPointF(cx - hw, cy - hh), QPointF(cx + hw, cy + hh))
                    grad.setColorAt(0.0, QColor("#ffffff"))
                    grad.setColorAt(0.45, QColor("#f1f5f9"))
                    grad.setColorAt(1.0, QColor("#94a3b8"))
                    painter.setPen(QPen(QColor(226, 232, 240, 220), 0.9))
                    painter.setBrush(QBrush(grad))
                    painter.drawPolygon(poly)

                if f == 12:
                    draw_diamond(dot_cx, dot_cy - 14, hw=3.8, hh=6.2)
                    draw_diamond(dot_cx, dot_cy + 14, hw=3.8, hh=6.2)
                else:
                    draw_diamond(dot_cx, dot_cy, hw=4.2, hh=6.8)

        # 4. 琴弦
        for s in range(6):
            sy = top_margin + s * string_spacing
            string_thickness = 1.0 + (s * 0.42)
            painter.setPen(QPen(QColor("#94a3b8"), string_thickness))
            painter.drawLine(QPointF(15, sy), QPointF(w - 15, sy))

            painter.setPen(QPen(QColor("#64748b")))
            painter.setFont(QFont("Segoe UI", 8, QFont.Bold))
            painter.drawText(QRectF(2, sy - 8, 12, 16), Qt.AlignCenter, str(s + 1))

        # 5. 音符标记绘制 (同心双环光晕体系)
        for s in range(6):
            sy = top_margin + s * string_spacing
            for f in range(22):
                info = self.fret_matrix[s][f]
                pc = info['pitch_class']
                note_name = info['note_name']

                if f == 0:
                    cx = nut_w - 18.0
                else:
                    cx = nut_w + f * fret_w - (fret_w / 2.0)
                cy = sy

                is_chord_note = (pc in self.chord_pitch_classes)
                is_scale_note = (pc in self.scale_pitch_classes)
                is_both = (is_chord_note and is_scale_note)
                is_root = (self.highlight_root and pc == self.chord_root_pitch_class)
                is_hover = (s == self.hover_string and f == self.hover_fret)

                # 判断是否为当前键盘选中的精准八度 (或全量模式)
                if not self.distinguish_octaves or not self.exact_active_indices:
                    is_exact_octave = True
                else:
                    is_exact_octave = (info['abs_idx'] in self.exact_active_indices)

                chord_col = QColor(self.color_scheme.get('chord_color', self.color_scheme.get('white_chord_color', '#38bdf8')))
                both_accent_col = QColor(self.color_scheme.get('both_accent_color', '#f59e0b'))
                scale_col = QColor(self.color_scheme.get('scale_color', '#0ea5e9'))
                root_col = QColor(self.color_scheme.get('root_color', '#f97316'))

                # 双集合融合展示：既属于和弦又属于调式 -> 外层同心发光调式光环 (Halo Ring)
                if is_both:
                    if is_exact_octave:
                        painter.setPen(QPen(QColor(both_accent_col.red(), both_accent_col.green(), both_accent_col.blue(), 190), 1.8))
                        painter.setBrush(QBrush(QColor(both_accent_col.red(), both_accent_col.green(), both_accent_col.blue(), 45)))
                        painter.drawEllipse(QPointF(cx, cy), 13.5, 13.5)
                    else:
                        painter.setPen(QPen(QColor(both_accent_col.red(), both_accent_col.green(), both_accent_col.blue(), 75), 1.2))
                        painter.setBrush(QBrush(QColor(both_accent_col.red(), both_accent_col.green(), both_accent_col.blue(), 18)))
                        painter.drawEllipse(QPointF(cx, cy), 12.0, 12.0)

                # 内层圆点绘制
                if is_chord_note:
                    if is_root:
                        base_color = root_col
                        border_color = root_col.lighter(135)
                    elif is_both:
                        base_color = chord_col
                        border_color = both_accent_col
                    else:
                        base_color = chord_col
                        border_color = chord_col.lighter(130)

                    if is_exact_octave:
                        # 1. 🌟 当前所选精准八度：高饱和 100% 实体高亮
                        dot_r = 10.5
                        painter.setPen(QPen(border_color, 1.6))
                        painter.setBrush(QBrush(base_color))
                        painter.drawEllipse(QPointF(cx, cy), dot_r, dot_r)

                        # 文本对比色亮度自适应
                        bg_lum = (base_color.red() * 299 + base_color.green() * 587 + base_color.blue() * 114) / 1000
                        text_color = QColor("#0f172a") if bg_lum > 135 else QColor("#ffffff")
                        painter.setPen(QPen(text_color))
                        painter.setFont(QFont("Segoe UI", 8, QFont.Bold))
                        painter.drawText(QRectF(cx - dot_r, cy - dot_r, dot_r * 2, dot_r * 2), Qt.AlignCenter, note_name)
                    else:
                        # 2. 🌫️ 其他八度同名参考音：自动同色系柔和淡化 (Ghost Octave)
                        dot_r = 9.2
                        alpha_fill = int(255 * self.octave_fade_opacity)
                        alpha_border = min(255, int(255 * (self.octave_fade_opacity + 0.22)))
                        fade_fill = QColor(base_color.red(), base_color.green(), base_color.blue(), alpha_fill)
                        fade_border = QColor(border_color.red(), border_color.green(), border_color.blue(), alpha_border)

                        painter.setPen(QPen(fade_border, 1.2))
                        painter.setBrush(QBrush(fade_fill))
                        painter.drawEllipse(QPointF(cx, cy), dot_r, dot_r)

                        # 柔和淡雅音名文字
                        painter.setPen(QPen(QColor(241, 245, 249, 175)))
                        painter.setFont(QFont("Segoe UI", 7, QFont.Bold))
                        painter.drawText(QRectF(cx - dot_r, cy - dot_r, dot_r * 2, dot_r * 2), Qt.AlignCenter, note_name)

                elif is_scale_note:
                    dot_r = 8.5
                    painter.setPen(QPen(scale_col, 1.2))
                    painter.setBrush(QBrush(QColor(scale_col.red(), scale_col.green(), scale_col.blue(), 55)))
                    painter.drawEllipse(QPointF(cx, cy), dot_r, dot_r)

                    painter.setPen(QPen(scale_col.lighter(135)))
                    painter.setFont(QFont("Segoe UI", 7, QFont.Bold))
                    painter.drawText(QRectF(cx - dot_r, cy - dot_r, dot_r * 2, dot_r * 2), Qt.AlignCenter, note_name)

                elif is_hover:
                    dot_r = 7.0
                    painter.setPen(QPen(QColor("#38bdf8"), 1))
                    painter.setBrush(QBrush(QColor(56, 189, 248, 60)))
                    painter.drawEllipse(QPointF(cx, cy), dot_r, dot_r)

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            s_idx, f_idx = self._hit_test(event.pos())
            if s_idx != -1 and f_idx != -1:
                info = self.fret_matrix[s_idx][f_idx]
                self.fret_clicked.emit(info['abs_idx'], info['full_name'])
                event.accept()

    def mouseMoveEvent(self, event):
        s_idx, f_idx = self._hit_test(event.pos())
        if s_idx != self.hover_string or f_idx != self.hover_fret:
            self.hover_string = s_idx
            self.hover_fret = f_idx
            self.update()
        super().mouseMoveEvent(event)

    def leaveEvent(self, event):
        self.hover_string = -1
        self.hover_fret = -1
        self.update()
        super().leaveEvent(event)
