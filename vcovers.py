import sys
import os

# 自动修复 Windows 下 Qt 平台插件加载路径
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

import cv2
import threading
from pathlib import Path

try:
    from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                                 QLabel, QListWidget, QListWidgetItem, QProgressBar,
                                 QGraphicsDropShadowEffect)
    from PyQt5.QtCore import Qt, pyqtSignal, QObject, QSize
    from PyQt5.QtGui import QDragEnterEvent, QDropEvent, QFont, QColor, QPainter
except ImportError:
    from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                                 QLabel, QListWidget, QListWidgetItem, QProgressBar,
                                 QGraphicsDropShadowEffect)
    from PyQt6.QtCore import Qt, pyqtSignal, QObject, QSize
    from PyQt6.QtGui import QDragEnterEvent, QDropEvent, QFont, QColor, QPainter


# --- 自定义控件：解决版本兼容性并提升美观度 ---

class FileListWidget(QListWidget):
    """支持居中占位文字的自定义列表控件"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setAcceptDrops(True)

    def paintEvent(self, event):
        super().paintEvent(event)
        if self.count() == 0:
            painter = QPainter(self.viewport())
            painter.setPen(QColor("#A0A0A0"))
            painter.setFont(QFont("Microsoft YaHei", 11))
            # 在中心绘制提示文字
            painter.drawText(self.rect(), Qt.AlignmentFlag.AlignCenter,
                             "✦ 拖入视频文件到此处 ✦\n(支持批量处理)")


# --- 后台处理逻辑 ---

class VideoProcessor(QObject):
    """处理视频提取逻辑的信号类"""
    finished_one = pyqtSignal(str, bool)  # 文件名, 是否成功
    all_done = pyqtSignal()

    def extract_cover(self, video_paths):
        for path in video_paths:
            try:
                cap = cv2.VideoCapture(path)
                if not cap.isOpened():
                    self.finished_one.emit(os.path.basename(path), False)
                    continue

                # 智能跳帧：取第1秒或总时长的10%，避免黑屏
                total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
                fps = cap.get(cv2.CAP_PROP_FPS)
                target_frame = int(min(fps if fps > 0 else 24, total_frames // 10))

                cap.set(cv2.CAP_PROP_POS_FRAMES, target_frame)
                ret, frame = cap.read()

                if ret:
                    # 导出为高质量 JPG，保存在原视频目录
                    output_path = str(Path(path).with_suffix('.jpg'))
                    cv2.imwrite(output_path, frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                    self.finished_one.emit(os.path.basename(path), True)
                else:
                    self.finished_one.emit(os.path.basename(path), False)

                cap.release()
            except Exception:
                self.finished_one.emit(os.path.basename(path), False)

        self.all_done.emit()


# --- 主界面 ---

class ModernExtractor(QMainWindow):
    def __init__(self):
        super().__init__()
        self.processor = VideoProcessor()
        self.processor.finished_one.connect(self.on_item_processed)
        self.processor.all_done.connect(self.on_all_finished)
        self.initUI()

    def initUI(self):
        self.setWindowTitle("Video Cover Artisan")
        self.resize(650, 550)

        # 整体 QSS 样式表：简约、优雅、不过时
        self.setStyleSheet("""
            QMainWindow {
                background-color: #F8F9FA;
            }
            QWidget#MainContainer {
                background-color: #FFFFFF;
                border-radius: 15px;
            }
            QLabel#Title {
                color: #2D3436;
                font-family: "Microsoft YaHei";
                font-weight: bold;
            }
            QLabel#Subtitle {
                color: #636E72;
                font-family: "Microsoft YaHei";
            }
            QListWidget {
                border: 2px dashed #DFE6E9;
                border-radius: 12px;
                background-color: #FAFAFA;
                color: #2D3436;
                padding: 10px;
                outline: none;
            }
            QListWidget::item {
                background-color: #FFFFFF;
                border: 1px solid #F1F2F6;
                border-radius: 6px;
                margin-bottom: 5px;
                padding: 10px;
            }
            QProgressBar {
                border: none;
                background-color: #F1F2F6;
                height: 8px;
                border-radius: 4px;
            }
            QProgressBar::chunk {
                background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0, 
                                  stop:0 #0984E3, stop:1 #74B9FF);
                border-radius: 4px;
            }
        """)

        # 主容器
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(25, 25, 25, 25)

        # 卡片式外观
        container = QWidget()
        container.setObjectName("MainContainer")
        layout = QVBoxLayout(container)
        layout.setContentsMargins(30, 30, 30, 30)
        layout.setSpacing(15)

        # 添加阴影效果
        shadow = QGraphicsDropShadowEffect()
        shadow.setBlurRadius(20)
        shadow.setColor(QColor(0, 0, 0, 30))
        shadow.setOffset(0, 5)
        container.setGraphicsEffect(shadow)

        # 头部文字
        title = QLabel("视频封面提取器")
        title.setObjectName("Title")
        title.setFont(QFont("Microsoft YaHei", 20))
        layout.addWidget(title)

        subtitle = QLabel("批量提取视频帧作为封面，保存在视频同级目录。")
        subtitle.setObjectName("Subtitle")
        subtitle.setFont(QFont("Microsoft YaHei", 10))
        layout.addWidget(subtitle)

        # 列表区域
        self.file_list = FileListWidget()
        layout.addWidget(self.file_list)

        # 进度条
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        layout.addWidget(self.progress_bar)

        main_layout.addWidget(container)

        # 允许窗口接收拖拽
        self.setAcceptDrops(True)

    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            event.accept()
        else:
            event.ignore()

    def dropEvent(self, event: QDropEvent):
        urls = event.mimeData().urls()
        video_paths = [url.toLocalFile() for url in urls if self.is_video(url.toLocalFile())]

        if video_paths:
            self.start_processing(video_paths)

    def is_video(self, file_path):
        extensions = ('.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv', '.webm')
        return file_path.lower().endswith(extensions)

    def start_processing(self, paths):
        self.file_list.clear()
        self.progress_bar.setVisible(True)
        self.progress_bar.setMaximum(len(paths))
        self.progress_bar.setValue(0)

        for p in paths:
            item = QListWidgetItem(f"⏳ 等待中: {os.path.basename(p)}")
            self.file_list.addItem(item)

        # 线程处理
        thread = threading.Thread(target=self.processor.extract_cover, args=(paths,), daemon=True)
        thread.start()

    def on_item_processed(self, filename, success):
        # 更新状态
        items = self.file_list.findItems(f"⏳ 等待中: {filename}", Qt.MatchFlag.MatchExactly)
        if items:
            if success:
                items[0].setText(f"✅ 已完成: {filename}")
                items[0].setForeground(QColor("#27AE60"))
            else:
                items[0].setText(f"❌ 失败: {filename}")
                items[0].setForeground(QColor("#EB4D4B"))

        self.progress_bar.setValue(self.progress_bar.value() + 1)

    def on_all_finished(self):
        # 完结反馈
        self.progress_bar.setStyleSheet("QProgressBar::chunk { background-color: #27AE60; }")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    # 强制设置应用字体
    app.setFont(QFont("Microsoft YaHei", 9))
    window = ModernExtractor()
    window.show()
    sys.exit(app.exec())