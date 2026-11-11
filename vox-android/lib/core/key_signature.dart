/// 西洋古典乐理 15 种标准调号系统 (Key Signature)
class KeySignature {
  final String id;              // 唯一标识 (如 'C', 'G', 'F', 'Bb', 'D')
  final String name;            // 调名 (如 'C 大调', 'G 大调', '降 B 大调')
  final String shortName;       // 简短展示名 (如 '1♯ G', '2♭ B♭', 'C')
  final int accidentalCount;    // 升降记号数量：正数为升号 (1..7)，负数为降号 (-1..-7)，0 为自然 C 调
  final bool isSharp;           // 是否为升号调
  final List<String> accidentalsList; // 升降音级名称 (例如 G 大调为 ['F#'])

  const KeySignature({
    required this.id,
    required this.name,
    required this.shortName,
    required this.accidentalCount,
    required this.isSharp,
    required this.accidentalsList,
  });

  /// 标准 15 种大调调号定义列表 (按升降号序排列：7降 -> 0 -> 7升)
  static const List<KeySignature> all = [
    // 降号调系 (Flat Keys)
    KeySignature(id: 'Cb', name: '降 C 大调', shortName: '7♭ C♭', accidentalCount: -7, isSharp: false, accidentalsList: ['Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb', 'Fb']),
    KeySignature(id: 'Gb', name: '降 G 大调', shortName: '6♭ G♭', accidentalCount: -6, isSharp: false, accidentalsList: ['Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb']),
    KeySignature(id: 'Db', name: '降 D 大调', shortName: '5♭ D♭', accidentalCount: -5, isSharp: false, accidentalsList: ['Bb', 'Eb', 'Ab', 'Db', 'Gb']),
    KeySignature(id: 'Ab', name: '降 A 大调', shortName: '4♭ A♭', accidentalCount: -4, isSharp: false, accidentalsList: ['Bb', 'Eb', 'Ab', 'Db']),
    KeySignature(id: 'Eb', name: '降 E 大调', shortName: '3♭ E♭', accidentalCount: -3, isSharp: false, accidentalsList: ['Bb', 'Eb', 'Ab']),
    KeySignature(id: 'Bb', name: '降 B 大调', shortName: '2♭ B♭', accidentalCount: -2, isSharp: false, accidentalsList: ['Bb', 'Eb']),
    KeySignature(id: 'F',  name: 'F 大调',    shortName: '1♭ F',  accidentalCount: -1, isSharp: false, accidentalsList: ['Bb']),

    // 自然大调 (Natural Key)
    KeySignature(id: 'C',  name: 'C 大调',    shortName: 'C',     accidentalCount: 0,  isSharp: true,  accidentalsList: []),

    // 升号调系 (Sharp Keys)
    KeySignature(id: 'G',  name: 'G 大调',    shortName: '1♯ G',  accidentalCount: 1,  isSharp: true,  accidentalsList: ['F#']),
    KeySignature(id: 'D',  name: 'D 大调',    shortName: '2♯ D',  accidentalCount: 2,  isSharp: true,  accidentalsList: ['F#', 'C#']),
    KeySignature(id: 'A',  name: 'A 大调',    shortName: '3♯ A',  accidentalCount: 3,  isSharp: true,  accidentalsList: ['F#', 'C#', 'G#']),
    KeySignature(id: 'E',  name: 'E 大调',    shortName: '4♯ E',  accidentalCount: 4,  isSharp: true,  accidentalsList: ['F#', 'C#', 'G#', 'D#']),
    KeySignature(id: 'B',  name: 'B 大调',    shortName: '5♯ B',  accidentalCount: 5,  isSharp: true,  accidentalsList: ['F#', 'C#', 'G#', 'D#', 'A#']),
    KeySignature(id: 'Fs', name: '升 F 大调', shortName: '6♯ F♯', accidentalCount: 6,  isSharp: true,  accidentalsList: ['F#', 'C#', 'G#', 'D#', 'A#', 'E#']),
    KeySignature(id: 'Cs', name: '升 C 大调', shortName: '7♯ C♯', accidentalCount: 7,  isSharp: true,  accidentalsList: ['F#', 'C#', 'G#', 'D#', 'A#', 'E#', 'B#']),
  ];

  /// 默认 C 大调
  static const KeySignature defaultKey = KeySignature(
    id: 'C',
    name: 'C 大调',
    shortName: 'C',
    accidentalCount: 0,
    isSharp: true,
    accidentalsList: [],
  );

  /// 高音谱表升号标准线间步进 (自左至右: F5, C5, G5, D5, A4, E5, B4)
  static const List<int> trebleSharpSteps = [10, 7, 11, 8, 5, 9, 6];

  /// 高音谱表降号标准线间步进 (自左至右: B4, E5, A4, D5, G4, C5, F4)
  static const List<int> trebleFlatSteps = [6, 9, 5, 8, 4, 7, 3];

  /// 低音谱表升号标准线间步进 (自左至右: F3, C3, G3, D3, A3, E3, B2)
  static const List<int> bassSharpSteps = [-3, -6, -2, -5, -1, -4, -7];

  /// 低音谱表降号标准线间步进 (自左至右: B2, E3, A2, D3, G2, C3, F2)
  static const List<int> bassFlatSteps = [-7, -4, -8, -5, -9, -6, -3];

  /// 当前调号在高音谱表上的变音记号步进列表
  List<int> get trebleAccidentalSteps {
    if (accidentalCount == 0) return const [];
    if (isSharp) {
      return trebleSharpSteps.sublist(0, accidentalCount.clamp(0, 7));
    } else {
      return trebleFlatSteps.sublist(0, (-accidentalCount).clamp(0, 7));
    }
  }

  /// 当前调号在低音谱表上的变音记号步进列表
  List<int> get bassAccidentalSteps {
    if (accidentalCount == 0) return const [];
    if (isSharp) {
      return bassSharpSteps.sublist(0, accidentalCount.clamp(0, 7));
    } else {
      return bassFlatSteps.sublist(0, (-accidentalCount).clamp(0, 7));
    }
  }

  /// 按钮直观展示名：如 "C 调", "G 调 (1♯)", "F 调 (1♭)"
  String get displayLabel {
    if (accidentalCount == 0) return 'C 调';
    if (isSharp) {
      final cleanId = id.replaceAll('s', '♯');
      return '$cleanId 调 ($accidentalCount♯)';
    } else {
      final cleanId = id.replaceAll('b', '♭');
      return '$cleanId 调 (${-accidentalCount}♭)';
    }
  }

  /// 调内变音说明 (如 "升 F", "降 B、降 E")
  String get accidentalsDescription {
    if (accidentalsList.isEmpty) return '自然音阶';
    return accidentalsList.map((a) {
      if (a.endsWith('#')) {
        return '升${a.replaceAll('#', '')}';
      } else if (a.endsWith('b')) {
        return '降${a.replaceAll('b', '')}';
      }
      return a;
    }).join('、');
  }

  /// 自然调
  static const KeySignature naturalKey = defaultKey;

  /// 升号调系 (1♯ 到 7♯)
  static List<KeySignature> get sharpKeys =>
      all.where((k) => k.isSharp && k.accidentalCount > 0).toList();

  /// 降号调系 (1♭ 到 7♭)
  static List<KeySignature> get flatKeys => [
    all.firstWhere((k) => k.id == 'F'),
    all.firstWhere((k) => k.id == 'Bb'),
    all.firstWhere((k) => k.id == 'Eb'),
    all.firstWhere((k) => k.id == 'Ab'),
    all.firstWhere((k) => k.id == 'Db'),
    all.firstWhere((k) => k.id == 'Gb'),
    all.firstWhere((k) => k.id == 'Cb'),
  ];
}
