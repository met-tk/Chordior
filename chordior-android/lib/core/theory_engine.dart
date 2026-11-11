import 'dart:math';

/// 12 平均律音名（带同音异名兼顾）
const List<String> kNoteNames = [
  'C',
  'C#/Db',
  'D',
  'D#/Eb',
  'E',
  'F',
  'F#/Gb',
  'G',
  'G#/Ab',
  'A',
  'A#/Bb',
  'B'
];

/// 五度圈顺时针大调排列
const List<String> kCircleOfFifths = [
  'C',
  'G',
  'D',
  'A',
  'E',
  'B',
  'Gb/F#',
  'Db',
  'Ab',
  'Eb',
  'Bb',
  'F'
];

/// 五度圈内圈关系小调
const List<String> kCircleRelativeMinors = [
  'A',
  'E',
  'B',
  'F#',
  'C#',
  'G#',
  'Eb/D#',
  'Bb',
  'F',
  'C',
  'G',
  'D'
];

/// 音程中文名称映射
const Map<int, String> kIntervalNames = {
  0: '纯一度',
  1: '小二度',
  2: '大二度',
  3: '小三度',
  4: '大三度',
  5: '纯四度',
  6: '减五/增四',
  7: '纯五度',
  8: '小六度',
  9: '大六度',
  10: '小七度',
  11: '大七度',
};

class ChordDef {
  final String name;
  final List<int> intervals;
  final String description;

  const ChordDef(this.name, this.intervals, this.description);
}

/// 和弦分类配置
const Map<String, List<ChordDef>> kChordCategories = {
  '基础三和弦': [
    ChordDef('Maj', [0, 4, 7], '大三和弦'),
    ChordDef('min', [0, 3, 7], '小三和弦'),
    ChordDef('dim', [0, 3, 6], '减三和弦'),
    ChordDef('aug', [0, 4, 8], '增三和弦'),
    ChordDef('sus2', [0, 2, 7], '挂二和弦'),
    ChordDef('sus4', [0, 5, 7], '挂四和弦'),
    ChordDef('5', [0, 7], '强力和弦 (Power Chord)'),
  ],
  '流行与爵士七和弦': [
    ChordDef('7', [0, 4, 7, 10], '属七和弦'),
    ChordDef('Maj7', [0, 4, 7, 11], '大大七和弦'),
    ChordDef('m7', [0, 3, 7, 10], '小七和弦'),
    ChordDef('mMaj7', [0, 3, 7, 11], '小大七和弦'),
    ChordDef('dim7', [0, 3, 6, 9], '减七和弦'),
    ChordDef('m7b5', [0, 3, 6, 10], '半减七和弦'),
    ChordDef('7sus4', [0, 5, 7, 10], '属七挂四和弦'),
    ChordDef('aug7', [0, 4, 8, 10], '增七和弦'),
    ChordDef('augMaj7', [0, 4, 8, 11], '增大大七和弦'),
  ],
  '高阶扩展和弦': [
    ChordDef('add9', [0, 4, 7, 14], '加九和弦'),
    ChordDef('madd9', [0, 3, 7, 14], '小加九和弦'),
    ChordDef('6', [0, 4, 7, 9], '大六和弦'),
    ChordDef('m6', [0, 3, 7, 9], '小六和弦'),
    ChordDef('6/9', [0, 4, 7, 9, 14], '六九和弦'),
    ChordDef('9', [0, 4, 7, 10, 14], '属九和弦'),
    ChordDef('Maj9', [0, 4, 7, 11, 14], '大九和弦'),
    ChordDef('m9', [0, 3, 7, 10, 14], '小九和弦'),
    ChordDef('m7(b9)', [0, 3, 7, 10, 13], '小七降九和弦'),
    ChordDef('m7b5(b9)', [0, 3, 6, 10, 13], '半减七降九和弦'),
    ChordDef('m9b5', [0, 3, 6, 10, 14], '半减九和弦'),
    ChordDef('7(b9)', [0, 4, 7, 10, 13], '属七降九和弦'),
    ChordDef('7(#9)', [0, 4, 7, 10, 15], '属七升九和弦'),
    ChordDef('Maj9(#11)', [0, 4, 7, 11, 14, 18], '大九升十一和弦'),
    ChordDef('mMaj9', [0, 3, 7, 11, 14], '小大九和弦'),
    ChordDef('11', [0, 4, 7, 10, 14, 17], '十一和弦'),
    ChordDef('13', [0, 4, 7, 10, 14, 21], '十三和弦'),
    ChordDef('7(b13)', [0, 4, 7, 10, 20], '属七降十三和弦'),
    ChordDef('7(b9,b13)', [0, 4, 7, 10, 13, 20], '属七降九降十三和弦'),
    ChordDef('7(#11)', [0, 4, 7, 10, 18], '属七升十一和弦 (利蒂亚属)'),
    ChordDef('m11', [0, 3, 7, 10, 14, 17], '小十一和弦 (So What四度和声)'),
    ChordDef('Maj13', [0, 4, 7, 11, 14, 21], '大大十三和弦'),
    ChordDef('m13', [0, 3, 7, 10, 14, 21], '小十三和弦'),
    ChordDef('m6/9', [0, 3, 7, 9, 14], '小六九和弦'),
    ChordDef('9sus4', [0, 5, 7, 10, 14], '属九挂四和弦'),
    ChordDef('13sus4', [0, 5, 7, 10, 14, 21], '属十三挂四和弦'),
  ],
};

/// 展平的公开和弦对照表
final Map<String, List<int>> kChordTypes = () {
  final map = <String, List<int>>{};
  for (final list in kChordCategories.values) {
    for (final def in list) {
      map[def.name] = def.intervals;
    }
  }
  return map;
}();

/// 省五音 (No5) 识别兼容表
const Map<String, List<int>> kHiddenChordTypes = {
  '7(no5)': [0, 4, 10],
  'Maj7(no5)': [0, 4, 11],
  'm7(no5)': [0, 3, 10],
  'mMaj7(no5)': [0, 3, 11],
  '7sus4(no5)': [0, 5, 10],
  '9(no5)': [0, 4, 10, 14],
  'Maj9(no5)': [0, 4, 11, 14],
  'm9(no5)': [0, 3, 10, 14],
  'm7(b9)(no5)': [0, 3, 10, 13],
  '7(b9)(no5)': [0, 4, 10, 13],
  '7(#9)(no5)': [0, 4, 10, 15],
  '7(b13)(no5)': [0, 4, 10, 20],
  '7(b9,b13)(no5)': [0, 4, 10, 13, 20],
  '7(#11)(no5)': [0, 4, 10, 18],
  'm11(no5)': [0, 3, 10, 14, 17],
  'Maj13(no5)': [0, 4, 11, 14, 21],
  'm13(no5)': [0, 3, 10, 14, 21],
  '13(no5)': [0, 4, 10, 14, 21],
  '9sus4(no5)': [0, 5, 10, 14],
  '13sus4(no5)': [0, 5, 10, 14, 21],
};

const Map<String, String> kNo5UiMap = {
  '7(no5)': '7',
  'Maj7(no5)': 'Maj7',
  'm7(no5)': 'm7',
  'mMaj7(no5)': 'mMaj7',
  '7sus4(no5)': '7sus4',
  '9(no5)': '9',
  'Maj9(no5)': 'Maj9',
  'm9(no5)': 'm9',
  'm7(b9)(no5)': 'm7(b9)',
  '7(b9)(no5)': '7(b9)',
  '7(#9)(no5)': '7(#9)',
  '7(b13)(no5)': '7(b13)',
  '7(b9,b13)(no5)': '7(b9,b13)',
  '7(#11)(no5)': '7(#11)',
  'm11(no5)': 'm11',
  'Maj13(no5)': 'Maj13',
  'm13(no5)': 'm13',
  '13(no5)': '13',
  '9sus4(no5)': '9sus4',
  '13sus4(no5)': '13sus4',
};

/// 调式全量音程步长字典 (半音跨度)
const Map<String, List<int>> kModes = {
  'Ionian (自然大调 Major)': [2, 2, 1, 2, 2, 2, 1],
  'Dorian (多利亚调式)': [2, 1, 2, 2, 2, 1, 2],
  'Phrygian (弗里吉亚调式)': [1, 2, 2, 2, 1, 2, 2],
  'Lydian (利蒂亚调式)': [2, 2, 2, 1, 2, 2, 1],
  'Mixolydian (混合利蒂亚调式)': [2, 2, 1, 2, 2, 1, 2],
  'Aeolian (自然小调 Minor)': [2, 1, 2, 2, 1, 2, 2],
  'Locrian (洛克里亚调式)': [1, 2, 2, 1, 2, 2, 2],
  'Harmonic Minor (和声小调)': [2, 1, 2, 2, 1, 3, 1],
  'Melodic Minor (旋律小调上行)': [2, 1, 2, 2, 2, 2, 1],
  'Major Pentatonic (大调五声)': [2, 2, 3, 2, 3],
  'Minor Pentatonic (小调五声)': [3, 2, 2, 3, 2],
  'Miyako-bushi (都节音阶 / 阴音阶)': [1, 4, 2, 1, 4],
  'Ritsu (日本律音阶)': [2, 3, 2, 2, 3],
  'Ryukyu (琉球音阶)': [4, 1, 2, 4, 1],
  'Yonanuki Minor (ヨナ抜き短音阶)': [2, 1, 4, 1, 4],
};

const Map<String, String> kModeColors = {
  'Ionian (自然大调 Major)': '#f97316',
  'Dorian (多利亚调式)': '#38bdf8',
  'Phrygian (弗里吉亚调式)': '#a855f7',
  'Lydian (利蒂亚调式)': '#ec4899',
  'Mixolydian (混合利蒂亚调式)': '#eab308',
  'Aeolian (自然小调 Minor)': '#06b6d4',
  'Locrian (洛克里亚调式)': '#64748b',
  'Harmonic Minor (和声小调)': '#10b981',
  'Melodic Minor (旋律小调上行)': '#6366f1',
  'Major Pentatonic (大调五声)': '#f59e0b',
  'Minor Pentatonic (小调五声)': '#14b8a6',
  'Miyako-bushi (都节音阶 / 阴音阶)': '#d946ef',
  'Ritsu (日本律音阶)': '#059669',
  'Ryukyu (琉球音阶)': '#0284c7',
  'Yonanuki Minor (ヨナ抜き短音阶)': '#e11d48',
};

const Map<String, List<String>> kDegreeFunctions = {
  'Ionian (自然大调 Major)': [
    '主和弦 (Tonic - I)',
    '副特征上主和弦 (Supertonic - ii)',
    '代理主上中和弦 (Mediant - iii)',
    '特征下属和弦 (Subdominant - IV)',
    '属和弦 (Dominant - V)',
    '代理主下中和弦 (Submediant - vi)',
    '导和弦 (Leading-Tone - vii°)',
  ],
  'Aeolian (自然小调 Minor)': [
    '主和弦 (Modal Tonic - i)',
    '禁用和弦 (Avoid - ii°)',
    '平行大调主和弦 (Relative Major - ♭III)',
    '特征下属和弦 (Subdominant - iv)',
    '小属和弦 (Minor Dominant - v)',
    '特征降六大和弦 (Submediant - ♭VI)',
    '下主级进和弦 (Subtonic Cadence - ♭VII)',
  ],
  'Harmonic Minor (和声小调)': [
    '主和弦 (Tonic - i)',
    '下属减上主和弦 (Diminished - ii°)',
    '色彩增和弦 (Augmented - ♭III+)',
    '下属小和弦 (Minor Subdominant - iv)',
    '属和弦 (Dominant - V / V7)',
    '下中扩展和弦 (Submediant - ♭VI)',
    '代理属和弦 (Diminished 7th - vii°7)',
  ],
  'Dorian (多利亚调式)': [
    '主和弦 (Modal Tonic - i)',
    '特征弱终止和弦 (Cadence - ii)',
    '代理主和弦 (Tonic Substitute - ♭III)',
    '特征终止和弦 (Primary Cadence - IV)',
    '弱属和弦 (Minor Dominant - v)',
    '禁用和弦 (Avoid - vi°)',
    '下主级进和弦 (Subtonic - ♭VII)',
  ],
  'Phrygian (弗里吉亚调式)': [
    '主和弦 (Modal Tonic - i)',
    '特征终止和弦 (Neapolitan - ♭II)',
    '避免和弦 (Avoid - ♭III7)',
    '副终止和弦 (Subdominant - iv)',
    '禁用属和弦 (Avoid - v°)',
    '代理主和弦 (Tonic Substitute - ♭VI)',
    '特征弱终止和弦 (Minor Subtonic - ♭vii)',
  ],
  'Lydian (利蒂亚调式)': [
    '主和弦 (Modal Tonic - I)',
    '特征终止和弦 (Cadence - II)',
    '代理主和弦 (Tonic Substitute - iii)',
    '禁用减和弦 (Avoid - ♯iv°)',
    '色彩属弱终止 (Modal Dominant - V)',
    '代理主和弦 (Tonic Substitute - vi)',
    '特征弱终止 (Minor Leading - vii)',
  ],
  'Mixolydian (混合利蒂亚调式)': [
    '挂留主和弦 (Dominant Tonic - I7)',
    '连接下属和弦 (Supertonic - ii)',
    '禁用和弦 (Avoid - iii°)',
    '母下属和弦 (Subdominant - IV)',
    '特征弱属和弦 (Minor Dominant - v)',
    '主代理和弦 (Tonic Substitute - vi)',
    '特征终止和弦 (Subtonic - ♭VII)',
  ],
};

/// 规范化音名
String normalizeNoteName(String? name) {
  if (name == null || name.trim().isEmpty) return '';
  final trimmed = name.trim();
  for (final standard in kNoteNames) {
    final parts = standard.split('/').map((p) => p.toUpperCase()).toList();
    if (parts.contains(trimmed.toUpperCase()) || trimmed.toUpperCase() == standard.toUpperCase()) {
      return standard;
    }
  }
  const flatToStandard = {
    'DB': 'C#/Db',
    'EB': 'D#/Eb',
    'GB': 'F#/Gb',
    'AB': 'G#/Ab',
    'BB': 'A#/Bb'
  };
  const sharpToStandard = {
    'C#': 'C#/Db',
    'D#': 'D#/Eb',
    'F#': 'F#/Gb',
    'G#': 'G#/Ab',
    'A#': 'A#/Bb'
  };
  final upper = trimmed.toUpperCase();
  if (flatToStandard.containsKey(upper)) return flatToStandard[upper]!;
  if (sharpToStandard.containsKey(upper)) return sharpToStandard[upper]!;
  return trimmed;
}

/// 音名转半音音级 (0~11)
int? noteNameToPitchClass(String noteStr) {
  final norm = normalizeNoteName(noteStr);
  final idx = kNoteNames.indexOf(norm);
  return idx >= 0 ? idx : null;
}

/// 半音音级转音名
String pitchClassToNoteName(int pitchClass) {
  return kNoteNames[((pitchClass % 12) + 12) % 12];
}

/// 根据根音与和弦类型计算和弦组成音列表
List<String> getChordNotes(String rootNote, String chordType) {
  final normRoot = normalizeNoteName(rootNote);
  final rootIdx = kNoteNames.indexOf(normRoot);
  if (rootIdx < 0) return [];

  final formula = kChordTypes[chordType] ?? kHiddenChordTypes[chordType];
  if (formula == null) return [];

  return formula.map((i) => kNoteNames[(rootIdx + i) % 12]).toList();
}

/// 获取全部根音与调式的音阶
Map<String, List<String>> getAllScales() {
  final scales = <String, List<String>>{};
  for (final root in kNoteNames) {
    for (final entry in kModes.entries) {
      final modeName = entry.key;
      final intervals = entry.value;
      final currentScale = <String>[];
      int currIdx = kNoteNames.indexOf(root);
      for (final step in intervals) {
        currentScale.add(kNoteNames[currIdx % 12]);
        currIdx += step;
      }
      scales['$root $modeName'] = currentScale;
    }
  }
  return scales;
}

/// 和弦结构解析结果
class ChordStructureInfo {
  final String name;
  final String root;
  final String type;
  final int inversion;
  final String bass;
  final bool isValid;

  const ChordStructureInfo({
    required this.name,
    required this.root,
    required this.type,
    required this.inversion,
    required this.bass,
    required this.isValid,
  });
}

/// 根据琴键绝对音高索引解析和弦结构与转位
ChordStructureInfo analyzeChordStructure(List<int> pIndices) {
  if (pIndices.isEmpty) {
    return const ChordStructureInfo(
      name: 'None',
      root: '',
      type: '',
      inversion: 0,
      bass: '',
      isValid: false,
    );
  }

  final sortedIndices = List<int>.from(pIndices)..sort();
  final bassVal = sortedIndices.first;
  final bassName = kNoteNames[bassVal % 12];

  final uniquePitchClasses = <int>[];
  final seen = <int>{};
  for (final idx in sortedIndices) {
    final pc = idx % 12;
    if (seen.add(pc)) {
      uniquePitchClasses.add(pc);
    }
  }

  if (uniquePitchClasses.length == 1) {
    return ChordStructureInfo(
      name: '$bassName (单音)',
      root: bassName,
      type: '单音',
      inversion: 0,
      bass: bassName,
      isValid: false,
    );
  }

  if (uniquePitchClasses.length == 2) {
    final span = (sortedIndices[1] - sortedIndices[0]).abs() % 12;
    final intervalDesc = kIntervalNames[span] ?? '$span半音';
    final note2 = kNoteNames[uniquePitchClasses[1]];
    return ChordStructureInfo(
      name: '$bassName - $note2 : $intervalDesc',
      root: bassName,
      type: intervalDesc,
      inversion: 0,
      bass: bassName,
      isValid: false,
    );
  }

  final candidates = <Map<String, dynamic>>[];
  for (final candPc in uniquePitchClasses) {
    final rootName = kNoteNames[candPc];
    final currIntervals = uniquePitchClasses.map((pc) => (pc - candPc + 12) % 12).toSet();

    for (final lib in [kChordTypes, kHiddenChordTypes]) {
      for (final entry in lib.entries) {
        final typeName = entry.key;
        final formula = entry.value;
        final formulaModSet = formula.map((f) => f % 12).toSet();

        if (currIntervals.length == formulaModSet.length &&
            currIntervals.every(formulaModSet.contains)) {
          final bassOffset = (bassVal % 12 - candPc + 12) % 12;
          int invIndex = -1;
          for (int i = 0; i < formula.length; i++) {
            if (formula[i] % 12 == bassOffset) {
              invIndex = i;
              break;
            }
          }

          if (invIndex != -1) {
            final score = formula.length * 10 - (invIndex * 8);
            candidates.add({
              'root': rootName,
              'type': typeName,
              'inv': invIndex,
              'score': score,
            });
          }
        }
      }
    }
  }

  if (candidates.isEmpty) {
    return ChordStructureInfo(
      name: '未知和弦 (Unknown)',
      root: '',
      type: '',
      inversion: 0,
      bass: bassName,
      isValid: false,
    );
  }

  candidates.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  final best = candidates.first;
  final rName = best['root'] as String;
  final rawType = best['type'] as String;
  final tName = kNo5UiMap[rawType] ?? rawType;
  final iIdx = best['inv'] as int;

  String fullName;
  if (iIdx == 0) {
    fullName = '$rName $tName';
  } else if (iIdx == 1) {
    fullName = '$rName $tName/1转位 ($bassName)';
  } else if (iIdx == 2) {
    fullName = '$rName $tName/2转位 ($bassName)';
  } else if (iIdx == 3) {
    fullName = '$rName $tName/3转位 ($bassName)';
  } else {
    fullName = '$rName $tName/$bassName';
  }

  return ChordStructureInfo(
    name: fullName,
    root: rName,
    type: tName,
    inversion: iIdx,
    bass: bassName,
    isValid: true,
  );
}

/// 识别和弦名称
String identifyChordName(List<int> pIndices) {
  return analyzeChordStructure(pIndices).name;
}

/// 调式顺阶和弦分析
class HarmonicDegreeInfo {
  final String roman;
  final String name;
  final List<String> notes;
  final String function;

  const HarmonicDegreeInfo({
    required this.roman,
    required this.name,
    required this.notes,
    required this.function,
  });
}

/// 计算调式顺阶和弦
List<HarmonicDegreeInfo> getModeHarmonics(
  String rootName,
  String modeName, {
  String depth = 'Triad',
}) {
  final normRoot = normalizeNoteName(rootName);
  final allScales = getAllScales();
  String? scaleKey = '$normRoot $modeName';
  if (!allScales.containsKey(scaleKey)) {
    scaleKey = allScales.keys.firstWhere(
      (k) => k.startsWith('$normRoot ') && (k.contains(modeName) || k.endsWith(modeName)),
      orElse: () => '',
    );
  }

  if (scaleKey.isEmpty || !allScales.containsKey(scaleKey)) return [];

  final scaleNotes = allScales[scaleKey]!;
  final numDegrees = scaleNotes.length;
  if (numDegrees < 3) return [];

  const romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
  final result = <HarmonicDegreeInfo>[];

  for (int degreeIdx = 0; degreeIdx < numDegrees; degreeIdx++) {
    final indices = [
      degreeIdx,
      (degreeIdx + 2) % numDegrees,
      (degreeIdx + 4) % numDegrees,
    ];
    if ((depth == '7th' || depth == '9th') && numDegrees >= 4) {
      indices.add(numDegrees == 5 ? (degreeIdx + 1) % numDegrees : (degreeIdx + 6) % numDegrees);
    }
    if (depth == '9th' && numDegrees >= 5) {
      indices.add(numDegrees == 5 ? (degreeIdx + 3) % numDegrees : (degreeIdx + 8) % numDegrees);
    }

    final chordNotes = indices.map((i) => scaleNotes[i]).toList();

    // 单调递增原位钢琴键音高映射
    final pianoIndices = <int>[];
    final rootPc = noteNameToPitchClass(chordNotes.first) ?? 0;
    int curVal = rootPc;
    pianoIndices.add(curVal);
    for (int i = 1; i < chordNotes.length; i++) {
      final pc = noteNameToPitchClass(chordNotes[i]) ?? 0;
      int nextVal = curVal + 1;
      while (nextVal % 12 != pc) {
        nextVal++;
      }
      pianoIndices.add(nextVal);
      curVal = nextVal;
    }

    final struct = analyzeChordStructure(pianoIndices);
    final rClean = struct.root.isNotEmpty ? struct.root.split('/').first : '';
    final tClean = struct.type;
    final cleanName = rClean.isNotEmpty
        ? (tClean.isNotEmpty ? '$rClean $tClean' : rClean)
        : '${chordNotes.first.split('/').first} 和声';

    final funcs = kDegreeFunctions[modeName] ?? const [];
    final funcTag = degreeIdx < funcs.length ? funcs[degreeIdx] : '';

    result.add(HarmonicDegreeInfo(
      roman: degreeIdx < romanNumerals.length ? romanNumerals[degreeIdx] : '${degreeIdx + 1}',
      name: cleanName,
      notes: chordNotes,
      function: funcTag,
    ));
  }

  return result;
}

/// 智能声部排列引擎（支持 5 大专业声部连接策略）
List<int> notesToPianoIndices(
  List<String> notes, {
  String strategy = 'Voice-Leading Compact',
  String? scaleRoot,
  List<int>? previousIndices,
  int stepCount = 0,
  int contractionInterval = 4,
}) {
  if (notes.isEmpty) return [];

  final pcs = <int>[];
  for (final n in notes) {
    final pc = noteNameToPitchClass(n);
    if (pc != null) pcs.add(pc);
  }
  if (pcs.isEmpty) return [];

  final rootPc = pcs.first;

  // 1. 平滑声部诱导 (Voice-Leading Compact 与 Voice-Leading Guided)
  if (strategy.contains('Voice-Leading') || strategy.contains('Guided') || strategy.contains('Compact')) {
    final isCompact = strategy.contains('Compact');
    final isContractionStep = isCompact && (stepCount > 0 && stepCount % contractionInterval == 0);

    final candidatesPool = pcs.map((p) => List.generate(48, (i) => i).where((i) => i % 12 == p).toList()).toList();

    List<int>? bestCombo;
    double minCost = double.infinity;
    const targetCenter = 24.5; // C4~E4 听感中心

    void searchCombination(int noteIndex, List<int> currentCombo) {
      if (noteIndex == candidatesPool.length) {
        final sortedCombo = List<int>.from(currentCombo)..sort();
        if (sortedCombo.first % 12 != rootPc) return;

        final span = sortedCombo.last - sortedCombo.first;
        double spanCost = 0.0;
        if (isCompact) {
          if (span > 16) spanCost = 3.5 * (span - 16);
          if (span > 24) spanCost += 30.0;
        }

        double moveCost = 0.0;
        if (previousIndices != null && previousIndices.isNotEmpty && !isContractionStep) {
          final pLen = min(sortedCombo.length, previousIndices.length);
          for (int i = 0; i < pLen; i++) {
            moveCost += (sortedCombo[i] - previousIndices[i]).abs();
          }
        }

        final avgCenter = sortedCombo.reduce((a, b) => a + b) / sortedCombo.length;
        final gravityWeight = isContractionStep ? 4.5 : 1.3;
        double gravityCost = gravityWeight * (avgCenter - targetCenter).abs();
        if (avgCenter > 36.0 || avgCenter < 12.0) {
          gravityCost += 35.0;
        }

        final totalCost = moveCost + gravityCost + spanCost;
        if (totalCost < minCost) {
          minCost = totalCost;
          bestCombo = sortedCombo;
        }
        return;
      }

      for (final candidate in candidatesPool[noteIndex]) {
        if (!currentCombo.contains(candidate)) {
          currentCombo.add(candidate);
          searchCombination(noteIndex + 1, currentCombo);
          currentCombo.removeLast();
        }
      }
    }

    searchCombination(0, []);

    if (bestCombo != null) {
      return bestCombo!;
    }
  }

  // 2. 主和弦最低基准方案 (Tonic-Root Base)
  if (strategy.contains('Tonic-Root Base') && scaleRoot != null) {
    final scaleRootPc = noteNameToPitchClass(scaleRoot);
    if (scaleRootPc != null) {
      final tonicBaseIdx = scaleRootPc + 12;
      final interval = (rootPc - scaleRootPc) % 12;
      int chordRootIdx = tonicBaseIdx + interval;
      if (chordRootIdx >= 34) chordRootIdx -= 12;

      int curIdx = chordRootIdx;
      final res = <int>[curIdx];
      for (int i = 1; i < pcs.length; i++) {
        final pc = pcs[i];
        int next = curIdx + 1;
        while (next < 48 && next % 12 != pc) {
          next++;
        }
        if (next < 48) {
          curIdx = next;
          res.add(curIdx);
        }
      }
      return res..sort();
    }
  }

  // 3. 调式主音锚定阶梯排列 (Key-Anchored)
  if (strategy.contains('Key-Anchored') && scaleRoot != null) {
    final scaleRootPc = noteNameToPitchClass(scaleRoot);
    if (scaleRootPc != null) {
      int baseKey = scaleRootPc + 12;
      if (baseKey < 15) baseKey += 12;
      int chordRootIdx = baseKey + ((rootPc - scaleRootPc) % 12);
      if (chordRootIdx >= 34) chordRootIdx -= 12;

      int curIdx = chordRootIdx;
      final res = <int>[curIdx];
      for (int i = 1; i < pcs.length; i++) {
        final pc = pcs[i];
        int next = curIdx + 1;
        while (next < 48 && next % 12 != pc) {
          next++;
        }
        if (next < 48) {
          curIdx = next;
          res.add(curIdx);
        }
      }
      return res..sort();
    }
  }

  // 4. 严格原位基础排列 (Strict Root) 与 默认排列
  int baseRootIdx = rootPc + 12; // C3~B3 基准
  if (baseRootIdx < 16) baseRootIdx += 12;

  int cur = baseRootIdx;
  final fallback = <int>[cur];
  for (int i = 1; i < pcs.length; i++) {
    int next = cur + 1;
    while (next < 48 && next % 12 != pcs[i]) {
      next++;
    }
    if (next < 48) {
      fallback.add(next);
      cur = next;
    }
  }
  return fallback;
}

/// 匹配调式信息实体
class MatchedScaleInfo {
  final String key;
  final String root;
  final String mode;
  final String degree; // 顺阶级数，如 'I', 'IV', 'V'
  final List<String> scaleNotes;
  final String colorHex;

  const MatchedScaleInfo({
    required this.key,
    required this.root,
    required this.mode,
    required this.degree,
    required this.scaleNotes,
    required this.colorHex,
  });
}

/// 根据所给的一组和弦音符，在全部调式音阶中反查包含这组音符的所有所属母体调式
List<MatchedScaleInfo> findMatchingScales(List<String> chordNotes) {
  if (chordNotes.isEmpty) return [];

  final chordPcs = chordNotes
      .map((n) => noteNameToPitchClass(n))
      .whereType<int>()
      .toSet();

  if (chordPcs.isEmpty) return [];

  final allScales = getAllScales();
  final matched = <MatchedScaleInfo>[];
  const romanList = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];

  final rootPc = noteNameToPitchClass(chordNotes.first);

  for (final entry in allScales.entries) {
    final scaleKey = entry.key;
    final scaleNotes = entry.value;

    final scalePcs = scaleNotes
        .map((n) => noteNameToPitchClass(n))
        .whereType<int>()
        .toSet();

    // 核心算法：判断调式是否包含当前和弦的所有构成音
    if (chordPcs.every(scalePcs.contains)) {
      final parts = scaleKey.split(' ');
      final sRoot = parts.first;
      final sMode = parts.sublist(1).join(' ');

      String degreeStr = '';
      if (rootPc != null) {
        for (int i = 0; i < scaleNotes.length; i++) {
          if (noteNameToPitchClass(scaleNotes[i]) == rootPc) {
            degreeStr = (i < romanList.length) ? romanList[i] : '${i + 1}';
            break;
          }
        }
      }

      final cHex = kModeColors[sMode] ?? '#0284C7';

      matched.add(MatchedScaleInfo(
        key: scaleKey,
        root: sRoot,
        mode: sMode,
        degree: degreeStr,
        scaleNotes: scaleNotes,
        colorHex: cHex,
      ));
    }
  }

  return matched;
}
