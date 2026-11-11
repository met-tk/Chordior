/// 练声模式类型
enum TrainerPatternType {
  fiveToneArp,      // 经典五度琶音 (1-3-5-3-1)
  octaveLeap,       // 八度跳进 (1-5-8-5-1)
  sustainedTone,    // 长音平稳气息跟唱 (1)
  triadChord,       // 三和弦琶音 (1-3-5)
  chromaticLadder,  // 半音阶攀爬练习
}

/// 跟唱练习模板
class TrainerPattern {
  final String id;
  final String title;
  final String description;
  final TrainerPatternType type;
  final List<int> relativeSemitones; // 相对根音的半音偏移量 (如 0, 4, 7, 4, 0 对应 1-3-5-3-1)
  final String vocalVowel;           // 建议练声母音 (如 'Ma / 咪', 'Yi / 咿', 'Woo / 呜')

  const TrainerPattern({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.relativeSemitones,
    this.vocalVowel = 'Ma / 吗',
  });

  /// 根据当前根音生成实际的 MIDI 音符序列
  List<int> generateSequence(int rootMidi) {
    return relativeSemitones.map((s) => rootMidi + s).toList();
  }

  /// 预设练声模板集
  static const List<TrainerPattern> presets = [
    TrainerPattern(
      id: 'five_tone_arp',
      title: '五度琶音跟唱 (1-3-5-3-1)',
      description: '声乐初学者与热身标准练习，放松喉咙，练习基本音准。',
      type: TrainerPatternType.fiveToneArp,
      relativeSemitones: [0, 4, 7, 4, 0],
      vocalVowel: 'Ma (吗)',
    ),
    TrainerPattern(
      id: 'octave_leap',
      title: '八度跳跃攀升 (1-5-8-5-1)',
      description: '拉伸声带长度，建立由胸声向头声过渡的弹性。',
      type: TrainerPatternType.octaveLeap,
      relativeSemitones: [0, 7, 12, 7, 0],
      vocalVowel: 'Woo (呜)',
    ),
    TrainerPattern(
      id: 'triad_chord',
      title: '大三和弦琶音 (1-3-5-8)',
      description: '迅速打开共鸣腔体，提升声线明亮度与共鸣位置。',
      type: TrainerPatternType.triadChord,
      relativeSemitones: [0, 4, 7, 12],
      vocalVowel: 'Yi (咿)',
    ),
    TrainerPattern(
      id: 'sustained_tone',
      title: '稳态长音跟唱 (Sustained Tone)',
      description: '单音保持，练习气息支撑稳定性与音准核心对齐。',
      type: TrainerPatternType.sustainedTone,
      relativeSemitones: [0],
      vocalVowel: 'Ah (啊)',
    ),
  ];
}
