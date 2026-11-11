"""
Presets Dialog - 经典和弦进行预设库
收录数十种流行、日系二次元 ACG、R&B/City Pop、爵士 251、影视配乐史诗进行，支持一键试听与一键加载。
"""

import json
from PyQt5.QtCore import Qt, pyqtSignal, QTimer, QSettings
from PyQt5.QtGui import QFont, QColor
from PyQt5.QtWidgets import (QDialog, QGroupBox, QHBoxLayout, QLabel,
                             QListWidget, QListWidgetItem, QMessageBox,
                             QPushButton, QSplitter, QTextEdit, QVBoxLayout,
                             QWidget, QInputDialog)
from theory_engine import get_chord_notes

# 经典和弦进行预设库字典
PROGRESSION_PRESETS = [
    {
        "category": "🌟 流行热单 (Pop Hits)",
        "name": "4-5-3-6-2-5-1 (流行神级走向)",
        "desc": "华语流行乐与欧美热单中最经典的顶级和弦套路，富有层次与戏剧性解决感。",
        "bpm": 115,
        "chords": [
            {"label": "F Maj", "notes": ["F", "A", "C"], "beats": 2},
            {"label": "G Maj", "notes": ["G", "B", "D"], "beats": 2},
            {"label": "E min", "notes": ["E", "G", "B"], "beats": 2},
            {"label": "A min", "notes": ["A", "C", "E"], "beats": 2},
            {"label": "D min", "notes": ["D", "F", "A"], "beats": 2},
            {"label": "G 7",   "notes": ["G", "B", "D", "F"], "beats": 2},
            {"label": "C Maj", "notes": ["C", "E", "G"], "beats": 4}
        ]
    },
    {
        "category": "🌟 流行热单 (Pop Hits)",
        "name": "1-5-6-4 (卡农流行进行)",
        "desc": "无数流行金曲的基石 (Let It Be / Someone Like You / 稻香)，旋律感极强。",
        "bpm": 120,
        "chords": [
            {"label": "C Maj", "notes": ["C", "E", "G"], "beats": 2},
            {"label": "G Maj", "notes": ["G", "B", "D"], "beats": 2},
            {"label": "A min", "notes": ["A", "C", "E"], "beats": 2},
            {"label": "F Maj", "notes": ["F", "A", "C"], "beats": 2}
        ]
    },
    {
        "category": "🌟 流行热单 (Pop Hits)",
        "name": "6-4-1-5 (伤感流行进行)",
        "desc": "小调开头的深情伤感进行，催泪且充满张力 (Faded / Numb / 默)。",
        "bpm": 125,
        "chords": [
            {"label": "A min", "notes": ["A", "C", "E"], "beats": 2},
            {"label": "F Maj", "notes": ["F", "A", "C"], "beats": 2},
            {"label": "C Maj", "notes": ["C", "E", "G"], "beats": 2},
            {"label": "G Maj", "notes": ["G", "B", "D"], "beats": 2}
        ]
    },
    {
        "category": "🌟 流行热单 (Pop Hits)",
        "name": "1-6-4-5 (50年代复古抒情 Doo-Wop)",
        "desc": "经典百老汇、早期摇滚与复古流行进行 (Stand By Me)。",
        "bpm": 105,
        "chords": [
            {"label": "C Maj", "notes": ["C", "E", "G"], "beats": 2},
            {"label": "A min", "notes": ["A", "C", "E"], "beats": 2},
            {"label": "F Maj", "notes": ["F", "A", "C"], "beats": 2},
            {"label": "G Maj", "notes": ["G", "B", "D"], "beats": 2}
        ]
    },
    {
        "category": "🌸 日系二次元与 ACG (J-Pop / Anime)",
        "name": "4-5-3-6 王道进行 (Royal Road)",
        "desc": "日系二次元与 J-Pop 统治级的王道和弦，明亮热血又略带忧伤 (丸之内虐待狂 / 夜驱)。",
        "bpm": 128,
        "chords": [
            {"label": "F M7",  "notes": ["F", "A", "C", "E"], "beats": 2},
            {"label": "G 7",   "notes": ["G", "B", "D", "F"], "beats": 2},
            {"label": "E m7",  "notes": ["E", "G", "B", "D"], "beats": 2},
            {"label": "A m7",  "notes": ["A", "C", "E", "G"], "beats": 2}
        ]
    },
    {
        "category": "🌸 日系二次元与 ACG (J-Pop / Anime)",
        "name": "Just The Two Of Us 进行 (都市律动)",
        "desc": "融合副属和弦与降VII级离调，极富爵士与 Neo-Soul 律动感 (椎名林檎 / 流行R&B)。",
        "bpm": 96,
        "chords": [
            {"label": "F M7",  "notes": ["F", "A", "C", "E"], "beats": 2},
            {"label": "E 7",   "notes": ["E", "G#/Ab", "B", "D"], "beats": 2},
            {"label": "A m7",  "notes": ["A", "C", "E", "G"], "beats": 2},
            {"label": "G m7",  "notes": ["G", "A#/Bb", "D", "F"], "beats": 1},
            {"label": "C 7",   "notes": ["C", "E", "G", "A#/Bb"], "beats": 1}
        ]
    },
    {
        "category": "🌸 日系二次元与 ACG (J-Pop / Anime)",
        "name": "4-5-b7-1 (J-Pop 标志离调惊喜)",
        "desc": "副歌高潮常使用的借用降VII级和弦，带来开阔与振奋情绪。",
        "bpm": 132,
        "chords": [
            {"label": "F Maj", "notes": ["F", "A", "C"], "beats": 2},
            {"label": "G Maj", "notes": ["G", "B", "D"], "beats": 2},
            {"label": "A#/Bb", "notes": ["A#/Bb", "D", "F"], "beats": 2},
            {"label": "C Maj", "notes": ["C", "E", "G"], "beats": 2}
        ]
    },
    {
        "category": "🎷 爵士与 R&B (Jazz & City Pop)",
        "name": "大调经典 2-5-1 (Major ii-V-I)",
        "desc": "爵士音乐最核心的句法骨架，所有爵士乐手的必练进阶套路 (Autumn Leaves)。",
        "bpm": 110,
        "chords": [
            {"label": "D m7",  "notes": ["D", "F", "A", "C"], "beats": 4},
            {"label": "G 7",   "notes": ["G", "B", "D", "F"], "beats": 4},
            {"label": "C M7",  "notes": ["C", "E", "G", "B"], "beats": 4}
        ]
    },
    {
        "category": "🎷 爵士与 R&B (Jazz & City Pop)",
        "name": "小调爵士 2-5-1 (Minor ii-V-i)",
        "desc": "半减七 + 属七降九和弦解决至小和弦，神秘而优雅的爵士质感。",
        "bpm": 100,
        "chords": [
            {"label": "D m7b5", "notes": ["D", "F", "G#/Ab", "C"], "beats": 4},
            {"label": "G 7b9",  "notes": ["G", "B", "D", "F", "G#/Ab"], "beats": 4},
            {"label": "C min",  "notes": ["C", "D#/Eb", "G"], "beats": 4}
        ]
    },
    {
        "category": "🎷 爵士与 R&B (Jazz & City Pop)",
        "name": "City Pop 浪漫下行 4-3-2-1",
        "desc": "日本 80 年代 City Pop 标志性浪漫下行七和弦 (Plastic Love / Stay With Me)。",
        "bpm": 112,
        "chords": [
            {"label": "F M7",  "notes": ["F", "A", "C", "E"], "beats": 2},
            {"label": "E m7",  "notes": ["E", "G", "B", "D"], "beats": 2},
            {"label": "D m7",  "notes": ["D", "F", "A", "C"], "beats": 2},
            {"label": "C M7",  "notes": ["C", "E", "G", "B"], "beats": 2}
        ]
    },
    {
        "category": "🎬 影视配乐与游戏史诗 (Cinematic & Epic)",
        "name": "1-b6-b7-1 (史诗英雄凯旋进行)",
        "desc": "好莱坞与大片配乐常客 (加勒比海盗 / 指环王 / 权力的游戏)，气势恢宏。",
        "bpm": 120,
        "chords": [
            {"label": "C min",   "notes": ["C", "D#/Eb", "G"], "beats": 2},
            {"label": "G#/Ab",   "notes": ["G#/Ab", "C", "D#/Eb"], "beats": 2},
            {"label": "A#/Bb",   "notes": ["A#/Bb", "D", "F"], "beats": 2},
            {"label": "C min",   "notes": ["C", "D#/Eb", "G"], "beats": 2}
        ]
    }
]


class PresetsDialog(QDialog):
    """预设库浏览器对话框"""

    load_preset_requested = pyqtSignal(dict)  # 发送选中的预设配置字典

    def __init__(self, synth_engine=None, parent=None):
        super().__init__(parent)
        self.synth = synth_engine
        self.setWindowTitle("经典和弦进行预设库 (Chord Progression Presets)")
        self.resize(780, 500)

        # 试听定时器与状态
        self.audition_timer = QTimer(self)
        self.audition_timer.timeout.connect(self._audition_step)
        self.audition_idx = -1
        self.is_auditioning = False
        self.current_audition_preset = None

        # 检测当前主题 (优先从父窗口同步，次选统一 QSettings)
        is_dark = True
        store = QSettings("TaketoAudio", "ChordStudioPro")
        if parent and hasattr(parent, 'is_dark'):
            is_dark = parent.is_dark
        elif parent and hasattr(parent, 'is_dark_theme'):
            is_dark = parent.is_dark_theme
        elif store.contains("is_dark_theme"):
            is_dark = store.value("is_dark_theme", True, type=bool)
        self.is_dark = is_dark

        self.init_ui()
        self.apply_theme(self.is_dark)

    def apply_theme(self, is_dark):
        self.is_dark = is_dark
        if is_dark:
            self.setStyleSheet("""
                PresetsDialog {
                    background-color: #1e222b;
                    color: #f8fafc;
                }
                QLabel {
                    color: #cbd5e1;
                }
                QListWidget {
                    background-color: #16181f;
                    color: #f8fafc;
                    border: 1px solid #363b4a;
                    border-radius: 6px;
                }
                QListWidget::item:selected {
                    background-color: #0284c7;
                    color: #ffffff;
                }
                QTextEdit {
                    background-color: #16181f;
                    color: #f8fafc;
                    border: 1px solid #363b4a;
                    border-radius: 6px;
                }
                QPushButton {
                    background-color: #262a35;
                    color: #cbd5e1;
                    border: 1px solid #363b4a;
                    border-radius: 6px;
                    padding: 5px 12px;
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
                QPushButton#PlayActionButton {
                    background-color: #10b981;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#DangerButton {
                    background-color: #ef4444;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
            """)
        else:
            self.setStyleSheet("""
                PresetsDialog {
                    background-color: #f8fafc;
                    color: #0f172a;
                }
                QLabel {
                    color: #334155;
                }
                QListWidget {
                    background-color: #ffffff;
                    color: #0f172a;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                }
                QListWidget::item:selected {
                    background-color: #e0f2fe;
                    color: #0284c7;
                    font-weight: bold;
                }
                QTextEdit {
                    background-color: #ffffff;
                    color: #0f172a;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                }
                QPushButton {
                    background-color: #ffffff;
                    color: #334155;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                    padding: 5px 12px;
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
                QPushButton#PlayActionButton {
                    background-color: #10b981;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
                QPushButton#DangerButton {
                    background-color: #ef4444;
                    color: #ffffff;
                    border: none;
                    font-weight: bold;
                }
            """)

    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(15, 15, 15, 15)

        splitter = QSplitter(Qt.Horizontal)

        # 1. 左侧预设列表
        self.list_widget = QListWidget()
        self.list_widget.setStyleSheet("font-size: 13px; padding: 4px;")
        splitter.addWidget(self.list_widget)

        # 2. 右侧详情与操作面板
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(10, 0, 0, 0)
        right_layout.setSpacing(8)

        self.title_label = QLabel("选择一个预设进行")
        self.title_label.setFont(QFont("Segoe UI", 14, QFont.Bold))
        self.title_label.setStyleSheet("color: #38bdf8;")
        right_layout.addWidget(self.title_label)

        self.desc_text = QTextEdit()
        self.desc_text.setReadOnly(True)
        self.desc_text.setMaximumHeight(90)
        right_layout.addWidget(self.desc_text)

        self.chords_preview = QTextEdit()
        self.chords_preview.setReadOnly(True)
        self.chords_preview.setFont(QFont("Consolas", 12))
        right_layout.addWidget(self.chords_preview)

        # 用户自定义预设操作条 (修改标注 / 删除预设)
        self.user_action_box = QHBoxLayout()
        self.user_action_box.setSpacing(8)
        self.edit_note_btn = QPushButton("✏️ 修改个人标注 (Edit Note)")
        self.edit_note_btn.clicked.connect(self.edit_user_note)
        self.delete_preset_btn = QPushButton("🗑 删除此预设")
        self.delete_preset_btn.setObjectName("DangerButton")
        self.delete_preset_btn.clicked.connect(self.delete_user_preset)
        self.user_action_box.addWidget(self.edit_note_btn)
        self.user_action_box.addWidget(self.delete_preset_btn)
        self.user_action_box.addStretch()
        right_layout.addLayout(self.user_action_box)

        # 试听与载入按钮条
        btn_layout = QHBoxLayout()
        self.audition_btn = QPushButton("▶ 试听此进行 (Preview)")
        self.audition_btn.setObjectName("PrimaryButton")
        self.audition_btn.clicked.connect(self.audition_preset)

        self.load_btn = QPushButton("📥 载入到编排器 (Load to Studio)")
        self.load_btn.setObjectName("PlayActionButton")
        self.load_btn.clicked.connect(self.load_preset)

        btn_layout.addWidget(self.audition_btn)
        btn_layout.addWidget(self.load_btn)
        right_layout.addLayout(btn_layout)

        splitter.addWidget(right_panel)
        splitter.setSizes([340, 440])
        layout.addWidget(splitter)

        self.populate_list()
        self.list_widget.currentItemChanged.connect(self.on_item_changed)

        # 默认选中第一条有效项
        for i in range(self.list_widget.count()):
            item = self.list_widget.item(i)
            if item.data(Qt.UserRole):
                self.list_widget.setCurrentItem(item)
                break

    def populate_list(self):
        self.list_widget.clear()

        # 1. 置顶加载用户自定义预设 (统一配置域并向下兼容)
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

        if user_presets:
            header_item = QListWidgetItem("--- 📁 我的自定义预设 (My Presets) ---")
            header_item.setFlags(Qt.NoItemFlags)
            header_item.setForeground(QColor("#38bdf8"))
            header_item.setFont(QFont("Segoe UI", 9, QFont.Bold))
            self.list_widget.addItem(header_item)

            for p in user_presets:
                p['is_user'] = True
                item = QListWidgetItem(f"⭐ {p['name']}")
                item.setData(Qt.UserRole, p)
                self.list_widget.addItem(item)

        # 2. 加载内置经典预设
        current_cat = None
        for preset in PROGRESSION_PRESETS:
            cat = preset['category']
            if cat != current_cat:
                current_cat = cat
                header_item = QListWidgetItem(f"--- {cat} ---")
                header_item.setFlags(Qt.NoItemFlags)
                header_item.setForeground(QColor("#94a3b8"))
                header_item.setFont(QFont("Segoe UI", 9, QFont.Bold))
                self.list_widget.addItem(header_item)

            item = QListWidgetItem(f"🎵 {preset['name']}")
            item.setData(Qt.UserRole, preset)
            self.list_widget.addItem(item)

    def on_item_changed(self, current, previous):
        self.stop_audition()
        if not current:
            self.edit_note_btn.setVisible(False)
            self.delete_preset_btn.setVisible(False)
            return

        preset = current.data(Qt.UserRole)
        if not preset:
            self.edit_note_btn.setVisible(False)
            self.delete_preset_btn.setVisible(False)
            return

        is_user = bool(preset.get('is_user', False))
        self.edit_note_btn.setVisible(is_user)
        self.delete_preset_btn.setVisible(is_user)

        self.title_label.setText(preset['name'])
        note_prefix = "📝 个人标注心得:\n" if is_user else ""
        desc_content = preset.get('desc', '暂无标注说明')
        self.desc_text.setText(f"分类: {preset.get('category', '未分类')}\n推荐速度: {preset.get('bpm', 120)} BPM\n{note_prefix}{desc_content}")
        
        chord_str = "和弦序列与节拍：\n"
        for i, c in enumerate(preset.get('chords', [])):
            notes = ' '.join([n.split('/')[0] for n in c.get('notes', [])])
            chord_str += f"[{i+1}] {c.get('label', 'Chord')} ({c.get('beats', 2)}拍) -> 构成音: {notes}\n"
        self.chords_preview.setText(chord_str)

    def edit_user_note(self):
        current = self.list_widget.currentItem()
        if not current:
            return
        preset = current.data(Qt.UserRole)
        if not preset or not preset.get('is_user'):
            return

        curr_note = preset.get('desc', '')
        new_note, ok = QInputDialog.getMultiLineText(self, "修改个人标注", f"为预设【{preset['name']}】更新标注说明:", curr_note)
        if ok:
            preset['desc'] = new_note.strip()
            current.setData(Qt.UserRole, preset)

            # 写回 QSettings (统一主程序配置域并向下兼容)
            target_name = preset.get('name')
            store = QSettings("TaketoAudio", "ChordStudioPro")
            raw = store.value("user_progression_presets", "")
            if not raw:
                raw = QSettings("ChordStudio", "ChordStudioApp").value("user_progression_presets", "[]")
            try:
                user_presets = json.loads(raw)
                matched = False
                for p in user_presets:
                    if p.get('name') == target_name:
                        p['desc'] = preset['desc']
                        matched = True
                        break
                if not matched:
                    user_presets.append(preset)
                store.setValue("user_progression_presets", json.dumps(user_presets, ensure_ascii=False))
            except Exception as e:
                print(f"Error saving updated note: {e}")

            # 立即刷新当前选中的详情展示
            self.on_item_changed(current, None)

            # 重新加载左侧列表并重设当前项，确保数据与视图 100% 绝对实时同步
            self.populate_list()
            for i in range(self.list_widget.count()):
                it = self.list_widget.item(i)
                data = it.data(Qt.UserRole)
                if data and data.get('name') == target_name and data.get('is_user'):
                    self.list_widget.setCurrentItem(it)
                    break

            QMessageBox.information(self, "成功", "个人标注已更新并即时刷新！")

    def delete_user_preset(self):
        current = self.list_widget.currentItem()
        if not current:
            return
        preset = current.data(Qt.UserRole)
        if not preset or not preset.get('is_user'):
            return

        reply = QMessageBox.question(self, "确认删除", f"确定要从预设库中删除自定义预设【{preset['name']}】吗？", QMessageBox.Yes | QMessageBox.No)
        if reply != QMessageBox.Yes:
            return

        store = QSettings("TaketoAudio", "ChordStudioPro")
        raw = store.value("user_progression_presets", "")
        if not raw:
            raw = QSettings("ChordStudio", "ChordStudioApp").value("user_progression_presets", "[]")
        try:
            user_presets = json.loads(raw)
            user_presets = [p for p in user_presets if not (p.get('name') == preset['name'] and p.get('chords') == preset.get('chords'))]
            store.setValue("user_progression_presets", json.dumps(user_presets, ensure_ascii=False))
        except Exception as e:
            print(f"Error deleting preset: {e}")

        self.populate_list()
        for i in range(self.list_widget.count()):
            item = self.list_widget.item(i)
            if item.data(Qt.UserRole):
                self.list_widget.setCurrentItem(item)
                break

    def audition_preset(self):
        if self.is_auditioning:
            self.stop_audition()
            return

        current = self.list_widget.currentItem()
        if not current:
            return
        preset = current.data(Qt.UserRole)
        if not preset or not self.synth:
            return

        chords = preset.get('chords', [])
        if not chords:
            return

        self.current_audition_preset = preset
        self.is_auditioning = True
        self.audition_btn.setText("⏸ 停止试听 (Stop)")
        self.audition_idx = -1
        self._audition_step()

    def _audition_step(self):
        if not self.is_auditioning or not self.current_audition_preset:
            return

        chords = self.current_audition_preset.get('chords', [])
        self.audition_idx += 1
        if self.audition_idx >= len(chords):
            self.stop_audition()
            return

        curr_chord = chords[self.audition_idx]
        from audio_synth import notes_to_piano_indices
        indices = notes_to_piano_indices(curr_chord['notes'])
        self.synth.play_chord(indices, {'timbre': 'Grand Piano', 'mode': 'Simultaneous', 'volume': 0.85})

        bpm = max(20, self.current_audition_preset.get('bpm', 120))
        beats = curr_chord.get('beats', 2)
        dur_ms = int(round((60000.0 / bpm) * beats))
        self.audition_timer.start(dur_ms)

    def stop_audition(self):
        self.is_auditioning = False
        self.audition_timer.stop()
        self.audition_btn.setText("▶ 试听此进行 (Preview)")
        self.current_audition_preset = None

    def load_preset(self):
        self.stop_audition()
        current = self.list_widget.currentItem()
        if not current:
            return
        preset = current.data(Qt.UserRole)
        if preset:
            self.load_preset_requested.emit(preset)
            self.accept()

    def closeEvent(self, event):
        self.stop_audition()
        super().closeEvent(event)

    def reject(self):
        self.stop_audition()
        super().reject()

    def accept(self):
        self.stop_audition()
        super().accept()
