class ProgressionPreset {
  final String category;
  final String name;
  final String desc;
  final int bpm;
  final List<PresetChordItem> chords;

  const ProgressionPreset({
    required this.category,
    required this.name,
    required this.desc,
    required this.bpm,
    required this.chords,
  });
}

class PresetChordItem {
  final String label;
  final List<String> notes;
  final int beats;

  const PresetChordItem({
    required this.label,
    required this.notes,
    this.beats = 2,
  });
}

const List<ProgressionPreset> kProgressionPresets = [
  ProgressionPreset(
    category: '🌟 流行热单 (Pop Hits)',
    name: '4-5-3-6-2-5-1 (流行神级走向)',
    desc: '华语流行乐与欧美热单中最经典的顶级和弦套路，富有层次与戏剧性解决感。',
    bpm: 115,
    chords: [
      PresetChordItem(label: 'F Maj', notes: ['F', 'A', 'C'], beats: 2),
      PresetChordItem(label: 'G Maj', notes: ['G', 'B', 'D'], beats: 2),
      PresetChordItem(label: 'E min', notes: ['E', 'G', 'B'], beats: 2),
      PresetChordItem(label: 'A min', notes: ['A', 'C', 'E'], beats: 2),
      PresetChordItem(label: 'D min', notes: ['D', 'F', 'A'], beats: 2),
      PresetChordItem(label: 'G 7', notes: ['G', 'B', 'D', 'F'], beats: 2),
      PresetChordItem(label: 'C Maj', notes: ['C', 'E', 'G'], beats: 4),
    ],
  ),
  ProgressionPreset(
    category: '🌟 流行热单 (Pop Hits)',
    name: '1-5-6-4 (卡农流行进行)',
    desc: '无数流行金曲的基石 (Let It Be / Someone Like You / 稻香)，旋律感极强。',
    bpm: 120,
    chords: [
      PresetChordItem(label: 'C Maj', notes: ['C', 'E', 'G'], beats: 2),
      PresetChordItem(label: 'G Maj', notes: ['G', 'B', 'D'], beats: 2),
      PresetChordItem(label: 'A min', notes: ['A', 'C', 'E'], beats: 2),
      PresetChordItem(label: 'F Maj', notes: ['F', 'A', 'C'], beats: 2),
    ],
  ),
  ProgressionPreset(
    category: '🌟 流行热单 (Pop Hits)',
    name: '6-4-1-5 (伤感流行进行)',
    desc: '小调开头的深情伤感进行，催泪且充满张力 (Faded / Numb / 默)。',
    bpm: 125,
    chords: [
      PresetChordItem(label: 'A min', notes: ['A', 'C', 'E'], beats: 2),
      PresetChordItem(label: 'F Maj', notes: ['F', 'A', 'C'], beats: 2),
      PresetChordItem(label: 'C Maj', notes: ['C', 'E', 'G'], beats: 2),
      PresetChordItem(label: 'G Maj', notes: ['G', 'B', 'D'], beats: 2),
    ],
  ),
  ProgressionPreset(
    category: '🌸 日系二次元 (J-Pop / ACG)',
    name: '4-5-3-6 (日系王道 / 丸之内走向)',
    desc: 'J-Pop 与动漫神曲的灵魂进行 (夜に駆ける / 丸之内虐待狂)，极度抓耳。',
    bpm: 128,
    chords: [
      PresetChordItem(label: 'F Maj7', notes: ['F', 'A', 'C', 'E'], beats: 2),
      PresetChordItem(label: 'G 7', notes: ['G', 'B', 'D', 'F'], beats: 2),
      PresetChordItem(label: 'E m7', notes: ['E', 'G', 'B', 'D'], beats: 2),
      PresetChordItem(label: 'A m7', notes: ['A', 'C', 'E', 'G'], beats: 2),
    ],
  ),
  ProgressionPreset(
    category: '🌸 日系二次元 (J-Pop / ACG)',
    name: '6-4-5-1 (小室哲哉经典进行)',
    desc: '90年代日系黄金时代标志性进行，气势恢宏，转折强烈。',
    bpm: 132,
    chords: [
      PresetChordItem(label: 'A min', notes: ['A', 'C', 'E'], beats: 2),
      PresetChordItem(label: 'F Maj', notes: ['F', 'A', 'C'], beats: 2),
      PresetChordItem(label: 'G Maj', notes: ['G', 'B', 'D'], beats: 2),
      PresetChordItem(label: 'C Maj', notes: ['C', 'E', 'G'], beats: 2),
    ],
  ),
  ProgressionPreset(
    category: '🎷 爵士与 R&B (Jazz & Soul)',
    name: '2-5-1 (大调爵士标准走向)',
    desc: '爵士乐中最核心的解决法则，充满平滑的导音流动与色彩。',
    bpm: 110,
    chords: [
      PresetChordItem(label: 'D m7', notes: ['D', 'F', 'A', 'C'], beats: 2),
      PresetChordItem(label: 'G 7', notes: ['G', 'B', 'D', 'F'], beats: 2),
      PresetChordItem(label: 'C Maj7', notes: ['C', 'E', 'G', 'B'], beats: 4),
    ],
  ),
  ProgressionPreset(
    category: '🎷 爵士与 R&B (Jazz & Soul)',
    name: '1-6-2-5 (经典爵士回转 Turnaround)',
    desc: '标准爵士循环背景，循环往复、摇摆生动。',
    bpm: 112,
    chords: [
      PresetChordItem(label: 'C Maj7', notes: ['C', 'E', 'G', 'B'], beats: 2),
      PresetChordItem(label: 'A 7', notes: ['A', 'C#/Db', 'E', 'G'], beats: 2),
      PresetChordItem(label: 'D m7', notes: ['D', 'F', 'A', 'C'], beats: 2),
      PresetChordItem(label: 'G 7', notes: ['G', 'B', 'D', 'F'], beats: 2),
    ],
  ),
];
