import 'dart:math';

/// 八度记谱法标准体系
enum OctaveNotation {
  /// 国际科学记谱法 (Scientific Pitch Notation / SPN / 现代声乐乐理标准: 中央C = C4, A4 = 440Hz)
  spn,

  /// 雅马哈记谱法 (Yamaha Standard / VOCALOID / UTAU / Cubase: 中央C = C3, A3 = 440Hz)
  yamaha,
}

/// 规范化音名数据结构 (支持严格数学角标 $C^\sharp_4$, $D^\flat_4$)
class FormattedNote {
  final int midi;
  final String baseNote;      // 音符基名，如 'C', 'D'
  final String accidental;    // 变音记号，'♯' 或 '♭' 或 ''
  final int octave;           // 八度数字，如 4
  final double frequency;     // 频率 (Hz)
  final String solfege;       // 国际唱名 (Do, Re, Mi...)
  final String enharmonicName;// 等音名称 (如 C♯4 的等音是 D♭4)
  final String japaneseSolfege; // 日本流行片假名唱名 (ド, レ, ミ...)
  final String japaneseTraditionalNote; // 日本传统古典音名 (ハ, 嬰ハ, ニ, 変ホ...)

  const FormattedNote({
    required this.midi,
    required this.baseNote,
    required this.accidental,
    required this.octave,
    required this.frequency,
    required this.solfege,
    required this.enharmonicName,
    required this.japaneseSolfege,
    required this.japaneseTraditionalNote,
  });

  /// 标准乐理显示文本，如 "C♯₄" 或 "D♭₄"
  String get displayName => '$baseNote$accidental$octave';

  /// 富文本或公式风格：如 C^♯_4
  String get scriptNotation => accidental.isEmpty ? '$baseNote$octave' : '$baseNote^${accidental}_$octave';

  /// 纯字母音名 (用于文件查找等，如 "Cs4" 或 "Db4")
  String get fileNoteName {
    final accStr = accidental == '♯' ? 's' : (accidental == '♭' ? 'b' : '');
    return '$baseNote$accStr$octave';
  }
}

/// 严格专业乐理引擎
class MusicTheory {
  // 12 平均律半音名称 (升号与降号)
  static const List<String> sharpNames = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];
  static const List<String> flatNames  = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B'];

  // 固定调唱名 (以 C 大调为基准)
  static const List<String> solfegeNames = ['Do', 'Di', 'Re', 'Ri', 'Mi', 'Fa', 'Fi', 'Sol', 'Si', 'La', 'Li', 'Ti'];
  static const List<String> solfegeFlatNames = ['Do', 'Ra', 'Re', 'Me', 'Mi', 'Fa', 'Se', 'Sol', 'Le', 'La', 'Te', 'Ti'];

  // 日本流行片假名唱名 (ドレミファソラシ)
  static const List<String> jpSolfegeSharpNames = ['ド', 'ド♯', 'レ', 'レ♯', 'ミ', 'ファ', 'ファ♯', 'ソ', 'ソ♯', 'ラ', 'ラ♯', 'シ'];
  static const List<String> jpSolfegeFlatNames  = ['ド', 'レ♭', 'レ', 'ミ♭', 'ミ', 'ファ', 'ソ♭', 'ソ', 'ラ♭', 'ラ', 'シ♭', 'シ'];

  // 日本传统固定音名 (ハニホヘトイロ / 和名)
  // C=ハ, D=ニ, E=ホ, F=ヘ, G=ト, A=イ, B=ロ (升号加「嬰/えい」、降号加「変/へん」)
  static const List<String> jpTraditionalSharpNames = ['ハ', '嬰ハ', 'ニ', '嬰ニ', 'ホ', 'ヘ', '嬰ヘ', 'ト', '嬰ト', 'イ', '嬰イ', 'ロ'];
  static const List<String> jpTraditionalFlatNames  = ['ハ', '変ニ', 'ニ', '変ホ', 'ホ', 'ヘ', '変ト', 'ト', '変イ', 'イ', '変ロ', 'ロ'];

  /// 计算 MIDI 音高对应的国际标准频率 (A4 = 440Hz)
  static double midiToFrequency(int midi) {
    return 440.0 * pow(2.0, (midi - 69.0) / 12.0);
  }

  /// 判断该 MIDI 音高是否为黑键
  static bool isBlackKey(int midi) {
    final semitone = midi % 12;
    return semitone == 1 || semitone == 3 || semitone == 6 || semitone == 8 || semitone == 10;
  }

  /// 格式化单个音符，生成专业富乐理属性
  static FormattedNote getFormattedNote(
    int midi, {
    bool preferSharp = true,
    OctaveNotation octaveNotation = OctaveNotation.spn,
  }) {
    final octaveOffset = octaveNotation == OctaveNotation.yamaha ? -1 : 0;
    final octave = (midi ~/ 12) - 1 + octaveOffset;
    final semitone = midi % 12;
    final freq = midiToFrequency(midi);

    // 主显示与等音显示
    final noteWithAcc = preferSharp ? sharpNames[semitone] : flatNames[semitone];
    final enharmonicWithAcc = preferSharp ? flatNames[semitone] : sharpNames[semitone];

    final baseNote = noteWithAcc[0];
    final accidental = noteWithAcc.length > 1 ? noteWithAcc[1] : '';

    final solfege = preferSharp ? solfegeNames[semitone] : solfegeFlatNames[semitone];
    final jpSolfege = preferSharp ? jpSolfegeSharpNames[semitone] : jpSolfegeFlatNames[semitone];
    final jpTrad = preferSharp ? jpTraditionalSharpNames[semitone] : jpTraditionalFlatNames[semitone];

    return FormattedNote(
      midi: midi,
      baseNote: baseNote,
      accidental: accidental,
      octave: octave,
      frequency: double.parse(freq.toStringAsFixed(2)),
      solfege: solfege,
      enharmonicName: '$enharmonicWithAcc$octave',
      japaneseSolfege: jpSolfege,
      japaneseTraditionalNote: '$jpTrad$octave',
    );
  }

  /// 计算两个音之间的音程信息 (如半音数、跨度八度描述)
  static String calculateRangeSpan(int startMidi, int endMidi) {
    final diff = (endMidi - startMidi).abs();
    final octaves = diff ~/ 12;
    final semitones = diff % 12;

    if (diff == 0) return '纯一度 (同音)';
    if (octaves == 0) return '$semitones 个半音';
    if (semitones == 0) return '$octaves 个八度';
    return '$octaves 个八度 + $semitones 半音';
  }

  /// 声乐音区分类常识分析与建议
  static String getVoiceRangeDescription(String type, int startMidi, int endMidi) {
    switch (type.toLowerCase()) {
      case 'chestvoice':
      case '真声区':
        return '真声区 (Chest Voice / 胸声)：声带全层振动，声音饱满厚实，是日常说话与中低音演唱的核心基石。练习要点：避免压喉与过度挤卡，保持气息稳定下沉。';
      case 'mixvoice':
      case '混声区':
        return '混声区 (Mix Voice)：通过声带边缘振动与声韧带张力平衡，连接胸声与头声的关键声区（包含第一换声点与第二换声点）。练习要点：使用咽音、母音弱化（如 [u]、[o]）平滑渡过换声点。';
      case 'headvoice':
      case 'falsetto':
      case '假声区':
      case '头声区':
        return '假声/头声区 (Head Voice / Falsetto)：声带边缘变薄微弱闭合，具有空灵高亢的头腔共鸣。练习要点：保持软腭抬起与咽壁力量，建立扎实的气息支持。';
      case 'focuspractice':
      case '重点练习区':
        return '重点攻坚突破区：您当前需要着重打磨与练习的音域，常位于您的换声交界区或高低极限音阶。建议进行每天 10~15 分钟的五度琶音爬坡训练。';
      case 'mainrange':
      case '主要音区':
        return '自然舒适主音区：歌唱表现力最从容、音色最优美稳定的舒适歌唱区间。通常涵盖 1.5 ~ 2 个八度。';
      case 'whistle':
      case '哨音区':
        return '哨音区 (Whistle Register)：声带仅有极小孔隙振动，产生笛声般超高频音质。需要极高声带机能与柔和控制。';
      default:
        final span = (endMidi - startMidi).abs();
        return '自定义声音特征音区：当前跨度为 $span 个半音。您可以根据自身声线特质进行标注并针对性练习跟唱。';
    }
  }
}
