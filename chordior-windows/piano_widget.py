"""
Piano Widget - 纯原生 QWidget 现代拟真触感 48 键专业大钢琴键盘
支持 4 个八度 (C2 ~ B5)、【和弦组成音】与【调式组成音】双层集合立体光感融合渲染体系、声部平滑诱导与主和弦最低基准。
"""

from PyQt5.QtCore import QPointF, QRectF, QSize, Qt, pyqtSignal
from PyQt5.QtGui import QBrush, QColor, QFont, QLinearGradient, QPainter, QPen
from PyQt5.QtWidgets import QWidget
from theory_engine import NOTE_NAMES, normalize_note_name, note_name_to_pitch_class
from audio_synth import notes_to_piano_indices


DEFAULT_COLOR_SCHEME = {
    'preset_name': 'Pure White & Electric Blue',
    'white_chord_color': '#38bdf8',
    'black_chord_color': '#ffffff',
    'scale_color': '#0ea5e9',
    'both_accent_color': '#f59e0b'
}


class ZoomablePianoView(QWidget):
    """
    拟真触感 48 键大钢琴 (4 个完整八度, C2 ~ B5, 28 白键 + 20 黑键)
    支持触控/点击交互、和弦音明亮发光、调式音阶弱光提示、双集合重叠高亮微轮廓与自定义色彩方案。
    """

    notes_changed = pyqtSignal()
    key_pressed = pyqtSignal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(800, 145)
        self.setFixedHeight(160)

        # 高亮调色盘配置
        self.color_scheme = dict(DEFAULT_COLOR_SCHEME)

        # 48 键配置 (C2 ~ B5, 4 个完整八度)
        self.num_white_keys = 28
        self.white_note_offsets = [0, 2, 4, 5, 7, 9, 11]
        self.black_note_offsets = [1, 3, 6, 8, 10]
        self.black_positions = [0, 1, 3, 4, 5]

        # 1. 和弦组成音状态 (0~47 琴键布尔列表)
        self.active_keys = [False] * 48

        # 2. 调式组成音状态 (0~11 pitch class set)
        self.scale_pitch_classes = set()

        self.hover_key = -1
        self.is_mouse_down = False
        self.setMouseTracking(True)

        self._build_key_geometry()

    def set_color_scheme(self, scheme):
        if scheme:
            self.color_scheme.update(scheme)
            self.update()

    def _build_key_geometry(self):
        """构建 48 键的乐理与绝对音高映射表 (C2 ~ B5)"""
        self.key_info = []
        for octave in range(4):
            base_pitch = octave * 12
            for i, name in enumerate(NOTE_NAMES):
                abs_idx = base_pitch + i
                is_black = ('#' in name or '/' in name)
                self.key_info.append({
                    'index': abs_idx,
                    'name': name.split('/')[0],
                    'full_name': name,
                    'pitch_class': i,
                    'octave': octave + 2,  # C2, C3, C4, C5
                    'is_black': is_black
                })

    def set_scale_pitch_classes(self, pitch_classes):
        """设置当前调式组成音集合"""
        self.scale_pitch_classes = set(pitch_classes) if pitch_classes else set()
        self.update()

    def set_active_notes(self, notes, scale_root=None, strategy="Voice-Leading Compact", previous_indices=None, step_count=0, contraction_interval=4):
        """
        设置当前和弦组成音，根据声部连接策略进行声部排列。
        """
        self.active_keys = [False] * 48
        if not notes:
            self.update()
            self.notes_changed.emit()
            return

        indices = notes_to_piano_indices(
            notes,
            scale_root=scale_root,
            strategy=strategy,
            previous_indices=previous_indices,
            step_count=step_count,
            contraction_interval=contraction_interval
        )
        for idx in indices:
            if 0 <= idx < 48:
                self.active_keys[idx] = True

        self.update()
        self.notes_changed.emit()

    def get_active_indices(self):
        return [i for i, v in enumerate(self.active_keys) if v]

    def set_active_indices(self, indices):
        """直接根据琴键物理序号列表激活琴键"""
        self.active_keys = [False] * 48
        if indices:
            for idx in indices:
                if 0 <= idx < 48:
                    self.active_keys[idx] = True
        self.update()
        self.notes_changed.emit()

    def get_active_notes(self):
        return [self.key_info[i]['full_name'] for i in self.get_active_indices()]

    def clear_all(self):
        self.active_keys = [False] * 48
        self.scale_pitch_classes = set()
        self.update()
        self.notes_changed.emit()

    def _get_key_rects(self):
        w = self.width()
        h = self.height()
        white_w = w / float(self.num_white_keys)
        black_w = white_w * 0.62
        black_h = h * 0.60

        white_rects = []
        black_rects = []

        w_idx = 0
        for octave in range(4):
            for i in range(7):
                rx = w_idx * white_w
                rect = QRectF(rx, 0, white_w, h)
                abs_idx = octave * 12 + self.white_note_offsets[i]
                white_rects.append((abs_idx, rect))
                w_idx += 1

            for pos, semi in zip(self.black_positions, self.black_note_offsets):
                rel_w_idx = octave * 7 + pos
                rx = (rel_w_idx + 1) * white_w - (black_w / 2.0)
                rect = QRectF(rx, 0, black_w, black_h)
                abs_idx = octave * 12 + semi
                black_rects.append((abs_idx, rect))

        return white_rects, black_rects

    def _hit_test(self, pos):
        white_rects, black_rects = self._get_key_rects()
        for abs_idx, rect in black_rects:
            if rect.contains(pos):
                return abs_idx
        for abs_idx, rect in white_rects:
            if rect.contains(pos):
                return abs_idx
        return -1

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        white_rects, black_rects = self._get_key_rects()

        w_chord_col = QColor(self.color_scheme.get('white_chord_color', '#38bdf8'))
        b_chord_col = QColor(self.color_scheme.get('black_chord_color', '#ffffff'))
        scale_col = QColor(self.color_scheme.get('scale_color', '#0ea5e9'))
        both_accent_col = QColor(self.color_scheme.get('both_accent_color', '#f59e0b'))

        # 判断黑键高亮色明亮度（用于自适应切换文字为纯黑或纯白）
        b_lum = (b_chord_col.red() * 299 + b_chord_col.green() * 587 + b_chord_col.blue() * 114) / 1000
        is_light_b = (b_lum > 130)

        # 1. 绘制白键
        for abs_idx, rect in white_rects:
            is_chord = self.active_keys[abs_idx]
            info = self.key_info[abs_idx]
            is_scale = (info['pitch_class'] in self.scale_pitch_classes)
            is_both = (is_chord and is_scale)
            is_hover = (abs_idx == self.hover_key)

            grad = QLinearGradient(rect.topLeft(), rect.bottomLeft())
            if is_both:
                # 调内核心和弦音：高亮渐变 + 优雅香槟金微轮廓
                grad.setColorAt(0.0, w_chord_col)
                grad.setColorAt(0.85, w_chord_col.darker(115))
                grad.setColorAt(1.0, w_chord_col.darker(130))
                pen_color = both_accent_col
                pen_width = 1.6
            elif is_chord:
                # 离调和弦外音
                grad.setColorAt(0.0, w_chord_col)
                grad.setColorAt(1.0, w_chord_col.darker(115))
                pen_color = w_chord_col.darker(110)
                pen_width = 1.0
            elif is_hover:
                grad.setColorAt(0.0, QColor("#f1f5f9"))
                grad.setColorAt(1.0, QColor("#cbd5e1"))
                pen_color = QColor("#94a3b8")
                pen_width = 1.0
            else:
                grad.setColorAt(0.0, QColor("#ffffff"))
                grad.setColorAt(0.9, QColor("#f8fafc"))
                grad.setColorAt(1.0, QColor("#e2e8f0"))
                pen_color = QColor("#94a3b8")
                pen_width = 1.0

            painter.setPen(QPen(pen_color, pen_width))
            painter.setBrush(QBrush(grad))
            painter.drawRoundedRect(rect.adjusted(0.5, 0, -0.5, -1), 0, 0)

            # 仅调式音标记：柔和半透明浅色弱光底衬
            if is_scale and not is_chord:
                painter.setPen(Qt.NoPen)
                painter.setBrush(QBrush(QColor(scale_col.red(), scale_col.green(), scale_col.blue(), 35)))
                painter.drawRect(rect.adjusted(1, rect.height() * 0.70, -1, -2))

            # 音名标注
            text_rect = QRectF(rect.x(), rect.height() - 30, rect.width(), 26)
            if is_chord:
                painter.setPen(QPen(QColor("#ffffff")))
                painter.setFont(QFont("Segoe UI", 9, QFont.Bold))
            elif is_scale:
                painter.setPen(QPen(scale_col.darker(110)))
                painter.setFont(QFont("Segoe UI", 8, QFont.Bold))
            else:
                painter.setPen(QPen(QColor("#64748b")))
                painter.setFont(QFont("Segoe UI", 8))

            note_text = info['name']
            if info['name'] == 'C':
                note_text = f"C{info['octave']}"
            painter.drawText(text_rect, Qt.AlignCenter, note_text)

        # 2. 绘制黑键
        for abs_idx, rect in black_rects:
            is_chord = self.active_keys[abs_idx]
            info = self.key_info[abs_idx]
            is_scale = (info['pitch_class'] in self.scale_pitch_classes)
            is_both = (is_chord and is_scale)
            is_hover = (abs_idx == self.hover_key)

            grad = QLinearGradient(rect.topLeft(), rect.bottomLeft())
            if is_both:
                # 调内核心和弦音 (黑键)：高对比度高光发光 + 香槟金微轮廓
                if is_light_b:
                    grad.setColorAt(0.0, b_chord_col)
                    grad.setColorAt(1.0, b_chord_col.darker(112))
                else:
                    grad.setColorAt(0.0, b_chord_col.lighter(120))
                    grad.setColorAt(1.0, b_chord_col)
                pen_color = both_accent_col
                pen_width = 1.8
            elif is_chord:
                # 离调和弦外音 (黑键)
                if is_light_b:
                    grad.setColorAt(0.0, b_chord_col)
                    grad.setColorAt(1.0, b_chord_col.darker(115))
                    pen_color = b_chord_col.darker(130)
                else:
                    grad.setColorAt(0.0, b_chord_col.lighter(120))
                    grad.setColorAt(1.0, b_chord_col)
                    pen_color = b_chord_col.lighter(140)
                pen_width = 1.2
            elif is_scale:
                # 调式背景音 (黑键)：深色底 + 鲜明调式微光边框与弱光底衬
                grad.setColorAt(0.0, QColor("#1e293b"))
                grad.setColorAt(1.0, QColor("#0f172a"))
                pen_color = scale_col
                pen_width = 1.6
            elif is_hover:
                grad.setColorAt(0.0, QColor("#334155"))
                grad.setColorAt(1.0, QColor("#1e293b"))
                pen_color = QColor("#0f172a")
                pen_width = 1.0
            else:
                grad.setColorAt(0.0, QColor("#1e293b"))
                grad.setColorAt(1.0, QColor("#0f172a"))
                pen_color = QColor("#020617")
                pen_width = 1.0

            painter.setPen(QPen(pen_color, pen_width))
            painter.setBrush(QBrush(grad))
            painter.drawRoundedRect(rect.adjusted(0.5, 0, -0.5, 0), 2, 2)

            # 黑键调式背景音弱光底衬
            if is_scale and not is_chord:
                painter.setPen(Qt.NoPen)
                painter.setBrush(QBrush(QColor(scale_col.red(), scale_col.green(), scale_col.blue(), 65)))
                painter.drawRect(rect.adjusted(1, rect.height() * 0.65, -1, -1))

            # 黑键音名文字
            text_rect = QRectF(rect.x(), rect.height() - 22, rect.width(), 18)
            clean_name = info['name'].split('/')[0]
            if is_chord:
                if is_light_b:
                    painter.setPen(QPen(QColor("#0f172a")))
                else:
                    painter.setPen(QPen(QColor("#ffffff")))
                painter.setFont(QFont("Segoe UI", 7, QFont.Bold))
                painter.drawText(text_rect, Qt.AlignCenter, clean_name)
            elif is_scale:
                painter.setPen(QPen(scale_col.lighter(130)))
                painter.setFont(QFont("Segoe UI", 7, QFont.Bold))
                painter.drawText(text_rect, Qt.AlignCenter, clean_name)

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            idx = self._hit_test(event.pos())
            if 0 <= idx < 48:
                self.is_mouse_down = True
                self.active_keys[idx] = not self.active_keys[idx]
                self.update()
                self.notes_changed.emit()
                if self.active_keys[idx]:
                    self.key_pressed.emit(idx)
                event.accept()

    def mouseMoveEvent(self, event):
        idx = self._hit_test(event.pos())
        if idx != self.hover_key:
            self.hover_key = idx
            self.update()
        super().mouseMoveEvent(event)

    def leaveEvent(self, event):
        self.hover_key = -1
        self.update()
        super().leaveEvent(event)

    def mouseReleaseEvent(self, event):
        self.is_mouse_down = False
        super().mouseReleaseEvent(event)
