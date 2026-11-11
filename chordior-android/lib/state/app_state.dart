import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chordior_flutter/audio/audio_synth.dart';
import 'package:chordior_flutter/core/harmonic_presets.dart';
import 'package:chordior_flutter/core/theory_engine.dart';
import 'package:chordior_flutter/services/storage_service.dart';

class ChordCardItem {
  String label;
  List<String> notes;
  int beats;

  ChordCardItem({
    required this.label,
    required this.notes,
    this.beats = 2,
  });
}

class AppState extends ChangeNotifier {
  // 明亮模式 / 深色模式 (true: 暗色模式, false: 明亮模式)
  bool _isDarkMode = true;

  // 当前全局选定的主调式
  String _currentKey = 'C';
  bool _isMinor = false;
  String _currentMode = 'Ionian (自然大调 Major)';

  // 当前激活/探索的和弦信息
  String _currentChordName = 'C Maj';
  List<String> _currentChordNotes = ['C', 'E', 'G'];
  // 乐器上自由点选的琴键/品位绝对索引集合 (0~47)
  Set<int> _selectedPianoIndices = {12, 16, 19}; // C3, E3, G3

  // 调式列表分组模式: 'byRoot' (按主音) 或 'byMode' (按调式)
  String _scaleGroupingMode = 'byRoot';

  // 顺阶和弦分析深度: 'Triad' (三和弦) / '7th' (七和弦) / '9th' (九和弦)
  String _harmonicDepth = 'Triad';

  // 声部连接排列策略 (Voice-Leading Compact / Root Position / Open Spread)
  String _voicingStrategy = 'Voice-Leading Compact';

  // 八度移调范围 (-2 ~ +2, 0 为默认)
  int _octaveShift = 0;

  // 演奏模式: 'Simultaneous' (齐奏), 'Pop Strum' (流行吉他扫弦), 'Arp Up' (上行琶音), 'Arp Down' (下行琶音)
  String _playMode = 'Simultaneous';

  // 当前发声音色预制 (默认 Concert Grand 顶级原声大三角钢琴)
  String _timbre = 'Concert Grand';

  // 基础发音时长 (秒，支持 0.5s ~ 4.0s 动态自然衰减)
  double _sustainDuration = 2.0;

  // 换和弦柔和消音 (默认开启，避免连续点击和弦时余音互相堆叠浑浊)
  bool _dampPreviousChord = true;

  // Pop Strum 扫弦速度 (毫秒，默认 35ms，范围 15ms ~ 90ms)
  int _strumSpeedMs = 35;

  // 乐器视图缩放比例 (0.6x ~ 1.2x，默认 0.85x，可一次性看到更多琴键与品格并降低垂直高度)
  double _instrumentZoom = 0.85;

  // 调色盘与调式音显示方案
  String _colorScheme = 'Sky Blue & Gold';
  double _scaleGlowIntensity = 0.65; // 调式音显色与弱光底衬强度 (0.2 ~ 1.0)

  // 吉他指板根音高亮自定义设置
  bool _highlightChordRoot = true; // 是否高亮和弦根音
  bool _highlightScaleRoot = false; // 是否高亮调式根音 (主音 Tonic)

  // 4 大官方 5 维柔和配色方案 (0:和弦主色, 1:调式底色, 2:调内重叠微轮廓, 3:和弦根音高亮, 4:调式主音高亮)
  static const Map<String, List<Color>> defaultColorSchemes = {
    'Sky Blue & Gold': [
      Color(0xFF38BDF8), // 0: 和弦主色 (经典天蓝)
      Color(0xFF0284C7), // 1: 调式底色 (深邃蔚蓝)
      Color(0xFFF59E0B), // 2: 调内重叠微轮廓 (温暖香槟金)
      Color(0xFFFB923C), // 3: 和弦根音高亮 (柔和珊瑚橙)
      Color(0xFFFBBF24), // 4: 调式主音高亮 (温润琥珀金)
    ],
    'Cyber Neon': [
      Color(0xFF10B981), // 0: 和弦主色 (清透翡翠绿)
      Color(0xFF06B6D4), // 1: 调式底色 (电光冰青)
      Color(0xFFF43F5E), // 2: 调内重叠微轮廓 (柔和玫瑰红)
      Color(0xFFF59E0B), // 3: 和弦根音高亮 (亮金暖黄)
      Color(0xFF22D3EE), // 4: 调式主音高亮 (璀璨天青)
    ],
    'Luxury Gold': [
      Color(0xFFF59E0B), // 0: 和弦主色 (高光亮金)
      Color(0xFF94A3B8), // 1: 调式底色 (柔润银灰)
      Color(0xFFFB7185), // 2: 调内重叠微轮廓 (夕阳薄粉)
      Color(0xFFEA580C), // 3: 和弦根音高亮 (深沉琥珀红)
      Color(0xFFFDE047), // 4: 调式主音高亮 (璀璨纯金)
    ],
    'Violet Sunset': [
      Color(0xFF8B5CF6), // 0: 和弦主色 (梦幻紫罗兰)
      Color(0xFFC084FC), // 1: 调式底色 (柔和粉紫)
      Color(0xFFFACC15), // 2: 调内重叠微轮廓 (晨曦金黄)
      Color(0xFFFB923C), // 3: 和弦根音高亮 (暖杏珊瑚橙)
      Color(0xFF38BDF8), // 4: 调式主音高亮 (星空透蓝)
    ],
  };

  // 用户可自定义的 5 维配色方案缓存
  final Map<String, List<Color>> _customColorSchemes = {
    'Sky Blue & Gold': [
      const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFFF59E0B),
      const Color(0xFFFB923C), const Color(0xFFFBBF24),
    ],
    'Cyber Neon': [
      const Color(0xFF10B981), const Color(0xFF06B6D4), const Color(0xFFF43F5E),
      const Color(0xFFF59E0B), const Color(0xFF22D3EE),
    ],
    'Luxury Gold': [
      const Color(0xFFF59E0B), const Color(0xFF94A3B8), const Color(0xFFFB7185),
      const Color(0xFFEA580C), const Color(0xFFFDE047),
    ],
    'Violet Sunset': [
      const Color(0xFF8B5CF6), const Color(0xFFC084FC), const Color(0xFFFACC15),
      const Color(0xFFFB923C), const Color(0xFF38BDF8),
    ],
  };

  // 主界面乐器插入模式: 'none' (不插入/隐藏), 'piano' (仅钢琴), 'guitar' (仅吉他), 'both' (两者都有)
  String _instrumentInsertMode = 'none';

  // 用户自定义和弦进行预设
  final List<ProgressionPreset> _userPresets = [];

  // 和弦进行工坊状态
  final List<ChordCardItem> _progression = [
    ChordCardItem(label: 'C Maj', notes: ['C', 'E', 'G'], beats: 2),
    ChordCardItem(label: 'G Maj', notes: ['G', 'B', 'D'], beats: 2),
    ChordCardItem(label: 'A min', notes: ['A', 'C', 'E'], beats: 2),
    ChordCardItem(label: 'F Maj', notes: ['F', 'A', 'C'], beats: 2),
  ];

  int _bpm = 120;
  bool _isPlaying = false;
  int _currentPlayingIndex = -1;
  Timer? _playTimer;

  AppState() {
    _loadSavedPreferences();
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currentKey => _currentKey;
  bool get isMinor => _isMinor;
  String get currentMode => _currentMode;
  String get currentChordName => _currentChordName;
  List<String> get currentChordNotes => _currentChordNotes;
  Set<int> get selectedPianoIndices => _selectedPianoIndices;
  String get scaleGroupingMode => _scaleGroupingMode;
  String get harmonicDepth => _harmonicDepth;
  String get voicingStrategy => _voicingStrategy;
  int get octaveShift => _octaveShift;
  String get playMode => _playMode;
  String get instrumentInsertMode => _instrumentInsertMode;
  List<ProgressionPreset> get userPresets => _userPresets;
  String get timbre => _timbre;
  double get sustainDuration => _sustainDuration;
  bool get dampPreviousChord => _dampPreviousChord;
  int get strumSpeedMs => _strumSpeedMs;
  double get instrumentZoom => _instrumentZoom;
  String get colorScheme => _colorScheme;
  double get scaleGlowIntensity => _scaleGlowIntensity;
  bool get highlightChordRoot => _highlightChordRoot;
  bool get highlightScaleRoot => _highlightScaleRoot;

  /// 获取指定配色方案的颜色列表 [chord, scale, both, chordRoot, scaleRoot]
  List<Color> getSchemeColors(String name) {
    return _customColorSchemes[name] ?? defaultColorSchemes[name] ?? defaultColorSchemes['Sky Blue & Gold']!;
  }

  /// 当前配色方案和弦主色
  Color get chordColor => getSchemeColors(_colorScheme)[0];

  /// 当前配色方案调式底色
  Color get scaleColor => getSchemeColors(_colorScheme)[1];

  /// 当前配色方案重叠与强调色
  Color get bothAccentColor => getSchemeColors(_colorScheme)[2];

  /// 当前配色方案和弦根音高亮色
  Color get chordRootColor => getSchemeColors(_colorScheme)[3];

  /// 当前配色方案调式主音高亮色
  Color get scaleRootColor => getSchemeColors(_colorScheme)[4];

  /// 切换明亮/深色模式
  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _savePreferences();
  }

  /// 设置主题模式
  void setThemeMode(bool isDark) {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();
    _savePreferences();
  }

  /// 自定义指定配色方案的颜色 (0: chord, 1: scale, 2: both, 3: chordRoot, 4: scaleRoot)
  void updateCustomColor(String schemeName, int index, Color newColor) {
    if (!_customColorSchemes.containsKey(schemeName)) {
      _customColorSchemes[schemeName] = List.from(defaultColorSchemes[schemeName] ?? defaultColorSchemes['Sky Blue & Gold']!);
    }
    _customColorSchemes[schemeName]![index] = newColor;
    notifyListeners();
    _savePreferences();
  }

  /// 恢复指定配色方案为官方默认
  void resetColorScheme(String schemeName) {
    if (defaultColorSchemes.containsKey(schemeName)) {
      _customColorSchemes[schemeName] = List.from(defaultColorSchemes[schemeName]!);
      notifyListeners();
    }
  }

  /// 恢复全部配色方案为官方默认
  void resetAllColorSchemes() {
    for (final entry in defaultColorSchemes.entries) {
      _customColorSchemes[entry.key] = List.from(entry.value);
    }
    notifyListeners();
  }

  /// 切换吉他指板和弦根音高亮
  void setHighlightChordRoot(bool val) {
    _highlightChordRoot = val;
    notifyListeners();
  }

  /// 切换吉他指板调式主音高亮
  void setHighlightScaleRoot(bool val) {
    _highlightScaleRoot = val;
    notifyListeners();
  }

  /// 当前调式主音音级 (0~11)
  int? get currentScaleRootPitchClass =>
      _currentKey == 'None' ? null : noteNameToPitchClass(_currentKey);

  /// 当前和弦组成音的音级集合 (0~11)
  Set<int> get currentChordPitchClasses =>
      _currentChordNotes.map((n) => noteNameToPitchClass(n)).whereType<int>().toSet();

  /// 当前和弦根音音级 (0~11)
  int? get currentRootPitchClass =>
      _currentChordNotes.isNotEmpty ? noteNameToPitchClass(_currentChordNotes.first) : null;

  /// 当前全局调式的音级集合 (0~11)
  Set<int> get currentScalePitchClasses {
    if (_currentKey == 'None' || _currentMode == 'None') return {};
    final norm = normalizeNoteName(_currentKey);
    final all = getAllScales();
    final key = '$norm $_currentMode';
    if (all.containsKey(key)) {
      return all[key]!.map((n) => noteNameToPitchClass(n)).whereType<int>().toSet();
    }
    return {};
  }

  /// 当前调式的一整排顺阶和弦 (根据当前选择的深度 Triad/7th/9th)
  List<HarmonicDegreeInfo> get currentHarmonics {
    if (_currentKey == 'None' || _currentMode == 'None') return [];
    return getModeHarmonics(_currentKey, _currentMode, depth: _harmonicDepth);
  }

  /// 当前和弦匹配到的所有可能母体调式
  List<MatchedScaleInfo> get matchingScales => findMatchingScales(_currentChordNotes);

  List<ChordCardItem> get progression => _progression;
  int get bpm => _bpm;
  bool get isPlaying => _isPlaying;
  int get currentPlayingIndex => _currentPlayingIndex;

  /// 切换顺阶和弦深度 (Triad / 7th / 9th)
  void setHarmonicDepth(String depth) {
    _harmonicDepth = depth;
    notifyListeners();
  }

  /// 根据指定的根音与和弦类型，主动设置当前和弦并反查调式
  void setChordByRootAndType(String root, String type) {
    final chordName = type.isEmpty ? root : '$root $type';
    final notes = getChordNotes(root, type);
    _currentChordName = chordName;
    _currentChordNotes = List.from(notes);

    final indices = notesToPianoIndices(notes);
    _selectedPianoIndices.clear();
    _selectedPianoIndices.addAll(indices);

    AudioSynth.instance.playPianoIndices(indices);
    notifyListeners();
  }

  /// 切换声部连接策略
  void setVoicingStrategy(String strategy) {
    _voicingStrategy = strategy;
    notifyListeners();
    _savePreferences();
  }

  /// 切换八度移调 (-2 ~ +2)
  void setOctaveShift(int shift) {
    _octaveShift = shift.clamp(-2, 2);
    AudioSynth.instance.octaveShift = _octaveShift;
    notifyListeners();
    _savePreferences();
  }

  /// 切换演奏模式 (Simultaneous / Pop Strum / Arp Up / Arp Down)
  void setPlayMode(String mode) {
    _playMode = mode;
    AudioSynth.instance.playMode = mode;
    notifyListeners();
    _savePreferences();
  }

  /// 切换发声音色预制并即时预热全局音频采样引擎
  void setTimbre(String timbre) {
    if (_timbre == timbre) return;
    _timbre = timbre;
    AudioSynth.instance.setTimbre(timbre);
    notifyListeners();
    _savePreferences();
  }

  /// 调节发声延音时长 (0.8s ~ 4.0s，自然阻尼声学衰减)
  void setSustainDuration(double val) {
    _sustainDuration = val.clamp(0.8, 4.0);
    AudioSynth.instance.sustainDuration = _sustainDuration;
    notifyListeners();
    _savePreferences();
  }

  /// 设置是否在换和弦时柔和衰减上一个和弦
  void setDampPreviousChord(bool val) {
    _dampPreviousChord = val;
    AudioSynth.instance.dampPreviousChord = val;
    notifyListeners();
    _savePreferences();
  }

  /// 调节 Pop Strum 扫弦速度 (15ms ~ 90ms，默认 35ms)
  void setStrumSpeedMs(int val) {
    _strumSpeedMs = val.clamp(15, 90);
    AudioSynth.instance.strumSpeedMs = _strumSpeedMs;
    notifyListeners();
    _savePreferences();
  }

  /// 删除用户自定义和弦进行预设
  void deleteUserPreset(ProgressionPreset preset) {
    _userPresets.removeWhere((p) => p.name == preset.name);
    notifyListeners();
    _savePreferences();
  }

  /// 调节乐器视图缩放比例 (0.3x ~ 1.2x，更宽阔全景)
  void setInstrumentZoom(double val) {
    _instrumentZoom = val.clamp(0.3, 1.2);
    notifyListeners();
    _savePreferences();
  }

  /// 切换色彩方案
  void setColorScheme(String scheme) {
    _colorScheme = scheme;
    notifyListeners();
    _savePreferences();
  }

  /// 调节调式音显色强度 (0.2 ~ 1.0)
  void setScaleGlowIntensity(double val) {
    _scaleGlowIntensity = val.clamp(0.2, 1.0);
    notifyListeners();
    _savePreferences();
  }

  /// 清除所选择的所有音，包括和弦组成音和当前调式组成音
  void clearAllSelectedNotes() {
    _currentKey = 'None';
    _currentMode = 'None';
    _currentChordNotes = [];
    _currentChordName = 'None';
    _selectedPianoIndices.clear();
    notifyListeners();
    _savePreferences();
  }

  /// 切换主界面乐器插入模式 (none -> piano -> guitar -> both)
  void setInstrumentInsertMode(String mode) {
    _instrumentInsertMode = mode;
    notifyListeners();
    _savePreferences();
  }

  /// 循环切换主界面乐器插入模式
  void cycleInstrumentInsertMode() {
    switch (_instrumentInsertMode) {
      case 'none':
        _instrumentInsertMode = 'piano';
        break;
      case 'piano':
        _instrumentInsertMode = 'guitar';
        break;
      case 'guitar':
        _instrumentInsertMode = 'both';
        break;
      default:
        _instrumentInsertMode = 'none';
        break;
    }
    notifyListeners();
    _savePreferences();
  }

  /// 将当前和弦进行保存为用户自定义预设
  void saveCurrentProgressionAsPreset(String name) {
    if (_progression.isEmpty || name.trim().isEmpty) return;
    final presetChords = _progression.map((c) => PresetChordItem(
      label: c.label,
      notes: List.from(c.notes),
      beats: c.beats,
    )).toList();

    _userPresets.add(ProgressionPreset(
      name: name.trim(),
      category: 'User Custom (用户自定义)',
      desc: '包含 ${_progression.length} 个和弦的自定义进行',
      bpm: _bpm,
      chords: presetChords,
    ));
    notifyListeners();
  }

  /// 和弦工坊中点击播放单个和弦，并将其全局同步为当前选定和弦
  void selectChordCardItem(ChordCardItem item) {
    _currentChordName = item.label;
    _currentChordNotes = List.from(item.notes);

    final indices = notesToPianoIndices(
      item.notes,
      strategy: _voicingStrategy,
      scaleRoot: _currentKey,
      previousIndices: _selectedPianoIndices.toList(),
    );
    _selectedPianoIndices.clear();
    _selectedPianoIndices.addAll(indices);

    AudioSynth.instance.playPianoIndices(indices);
    notifyListeners();
  }

  /// 1. 顺阶和弦点击选择：触发和弦试听，并立刻反查其所属调式
  void selectHarmonicChord(HarmonicDegreeInfo info) {
    _currentChordName = info.name;
    _currentChordNotes = List.from(info.notes);

    // 计算平滑声部诱导排列
    final indices = notesToPianoIndices(
      info.notes,
      strategy: _voicingStrategy,
      scaleRoot: _currentKey,
      previousIndices: _selectedPianoIndices.toList(),
    );
    _selectedPianoIndices.clear();
    _selectedPianoIndices.addAll(indices);

    // 试听
    AudioSynth.instance.playPianoIndices(indices);
    notifyListeners();
    _savePreferences();
  }

  /// 2. 匹配调式点击切换：切换系统当前主调式，重新生成该调式全套顺阶和弦！
  void selectMatchedScale(MatchedScaleInfo scale) {
    _currentKey = scale.root;
    _currentMode = scale.mode;
    _isMinor = scale.mode.contains('Minor') || scale.mode.contains('Aeolian');
    notifyListeners();
    _savePreferences();
  }

  /// 3. 在乐器 (钢琴/吉他) 上点选音符，切换开关 (Toggle Selection)
  void togglePianoKey(int index) {
    if (_selectedPianoIndices.contains(index)) {
      _selectedPianoIndices.remove(index);
    } else {
      _selectedPianoIndices.add(index);
      // 点按发声
      AudioSynth.instance.playPianoIndices([index]);
    }

    _refreshChordFromSelectedIndices();
    notifyListeners();
    _savePreferences();
  }

  /// 在吉他品位上点击触发选音切换
  void toggleGuitarFret(int absolutePitch) {
    if (absolutePitch >= 0 && absolutePitch < 48) {
      togglePianoKey(absolutePitch);
    }
  }

  /// 清空乐器上的所有选音
  void clearInstrumentSelection() {
    _selectedPianoIndices.clear();
    _currentChordName = 'None';
    _currentChordNotes = [];
    notifyListeners();
    _savePreferences();
  }

  /// 播放当前所选和弦
  void playCurrentChord() {
    if (_selectedPianoIndices.isNotEmpty) {
      AudioSynth.instance.playPianoIndices(_selectedPianoIndices.toList());
    } else if (_currentChordNotes.isNotEmpty) {
      AudioSynth.instance.playChordNotes(_currentChordNotes);
    }
  }

  /// 根据当前琴键点选的绝对音符索引，反向解析和弦名称与音符
  void _refreshChordFromSelectedIndices() {
    if (_selectedPianoIndices.isEmpty) {
      _currentChordName = 'None';
      _currentChordNotes = [];
      return;
    }

    final sorted = _selectedPianoIndices.toList()..sort();
    final struct = analyzeChordStructure(sorted);
    _currentChordName = struct.name;

    // 提取音符列表
    final uniquePcs = <int>[];
    for (final idx in sorted) {
      final pc = idx % 12;
      if (!uniquePcs.contains(pc)) {
        uniquePcs.add(pc);
      }
    }
    _currentChordNotes = uniquePcs.map((pc) => kNoteNames[pc]).toList();
  }

  /// 切换主调 (来自五度圈直接选择)
  void setKey(String key, {bool isMinor = false}) {
    _currentKey = key;
    _isMinor = isMinor;
    _currentMode = isMinor ? 'Aeolian (自然小调 Minor)' : 'Ionian (自然大调 Major)';
    notifyListeners();
    _savePreferences();
  }

  /// 切换分组模式 (按主音 / 按调式)
  void setGroupingMode(String mode) {
    _scaleGroupingMode = mode;
    notifyListeners();
    _savePreferences();
  }

  // -------------------------------------------------------------
  // 和弦进行工坊管理
  // -------------------------------------------------------------

  void addCurrentChordToProgression() {
    if (_currentChordNotes.isEmpty) return;
    _progression.add(ChordCardItem(
      label: _currentChordName,
      notes: List.from(_currentChordNotes),
      beats: 2,
    ));
    notifyListeners();
  }

  void removeChordFromProgression(int index) {
    if (index >= 0 && index < _progression.length) {
      _progression.removeAt(index);
      notifyListeners();
    }
  }

  void reorderProgression(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _progression.removeAt(oldIndex);
    _progression.insert(newIndex, item);
    notifyListeners();
  }

  void setBpm(int newBpm) {
    _bpm = newBpm.clamp(40, 240);
    notifyListeners();
    if (_isPlaying) {
      stopPlayback();
      startPlayback();
    }
  }

  void updateChordBeats(int index, int beats) {
    if (index >= 0 && index < _progression.length) {
      _progression[index].beats = beats;
      notifyListeners();
    }
  }

  void loadPreset(ProgressionPreset preset) {
    _progression.clear();
    for (final c in preset.chords) {
      _progression.add(ChordCardItem(
        label: c.label,
        notes: List.from(c.notes),
        beats: c.beats,
      ));
    }
    _bpm = preset.bpm;
    notifyListeners();
  }

  void startPlayback() {
    if (_progression.isEmpty) return;
    _isPlaying = true;
    _currentPlayingIndex = 0;
    notifyListeners();
    _scheduleNextChord();
  }

  void stopPlayback() {
    _playTimer?.cancel();
    _playTimer = null;
    _isPlaying = false;
    _currentPlayingIndex = -1;
    notifyListeners();
  }

  void _scheduleNextChord() {
    if (!_isPlaying || _progression.isEmpty) return;

    final chord = _progression[_currentPlayingIndex];
    _currentChordName = chord.label;
    _currentChordNotes = List.from(chord.notes);
    final indices = notesToPianoIndices(
      chord.notes,
      strategy: _voicingStrategy,
      scaleRoot: _currentKey,
      previousIndices: _selectedPianoIndices.toList(),
    );
    _selectedPianoIndices.clear();
    _selectedPianoIndices.addAll(indices);

    AudioSynth.instance.playPianoIndices(indices);

    final msPerBeat = 60000 / _bpm;
    final durationMs = (chord.beats * msPerBeat).toInt();

    _playTimer = Timer(Duration(milliseconds: durationMs), () {
      if (!_isPlaying) return;
      _currentPlayingIndex = (_currentPlayingIndex + 1) % _progression.length;
      notifyListeners();
      _scheduleNextChord();
    });
  }
  Future<void> _loadSavedPreferences() async {
    final data = await StorageService.loadPreferences();
    if (data != null) {
      if (data.containsKey('isDarkMode')) _isDarkMode = data['isDarkMode'] as bool;
      if (data.containsKey('currentKey')) _currentKey = data['currentKey'] as String;
      if (data.containsKey('isMinor')) _isMinor = data['isMinor'] as bool;
      if (data.containsKey('currentMode')) _currentMode = data['currentMode'] as String;
      if (data.containsKey('currentChordName')) _currentChordName = data['currentChordName'] as String;
      if (data.containsKey('currentChordNotes')) {
        _currentChordNotes = List<String>.from(data['currentChordNotes'] as List);
      }
      if (data.containsKey('selectedPianoIndices')) {
        _selectedPianoIndices = (data['selectedPianoIndices'] as List).map((e) => e as int).toSet();
      }
      if (data.containsKey('scaleGroupingMode')) _scaleGroupingMode = data['scaleGroupingMode'] as String;
      if (data.containsKey('harmonicDepth')) _harmonicDepth = data['harmonicDepth'] as String;
      if (data.containsKey('voicingStrategy')) _voicingStrategy = data['voicingStrategy'] as String;
      if (data.containsKey('octaveShift')) _octaveShift = data['octaveShift'] as int;
      if (data.containsKey('playMode')) {
        _playMode = data['playMode'] as String;
        AudioSynth.instance.playMode = _playMode;
      }
      if (data.containsKey('timbre')) {
        _timbre = data['timbre'] as String;
        AudioSynth.instance.setTimbre(_timbre);
      }
      if (data.containsKey('sustainDuration')) {
        _sustainDuration = (data['sustainDuration'] as num).toDouble();
        AudioSynth.instance.sustainDuration = _sustainDuration;
      }
      if (data.containsKey('dampPreviousChord')) {
        _dampPreviousChord = data['dampPreviousChord'] as bool;
        AudioSynth.instance.dampPreviousChord = _dampPreviousChord;
      }
      if (data.containsKey('strumSpeedMs')) {
        _strumSpeedMs = data['strumSpeedMs'] as int;
        AudioSynth.instance.strumSpeedMs = _strumSpeedMs;
      }
      if (data.containsKey('instrumentZoom')) _instrumentZoom = (data['instrumentZoom'] as num).toDouble();
      if (data.containsKey('colorScheme')) _colorScheme = data['colorScheme'] as String;
      if (data.containsKey('scaleGlowIntensity')) _scaleGlowIntensity = (data['scaleGlowIntensity'] as num).toDouble();
      if (data.containsKey('highlightChordRoot')) _highlightChordRoot = data['highlightChordRoot'] as bool;
      if (data.containsKey('highlightScaleRoot')) _highlightScaleRoot = data['highlightScaleRoot'] as bool;
      if (data.containsKey('instrumentInsertMode')) _instrumentInsertMode = data['instrumentInsertMode'] as String;

      // 恢复自定义配色数据
      if (data.containsKey('customColorSchemes')) {
        final map = data['customColorSchemes'] as Map<String, dynamic>;
        for (final entry in map.entries) {
          if (entry.value is List) {
            _customColorSchemes[entry.key] = (entry.value as List).map((val) => Color(val as int)).toList();
          }
        }
      }

      notifyListeners();
    }
  }

  /// 保存当前所有配置到本地存储
  void _savePreferences() {
    final customSchemesJson = <String, List<int>>{};
    for (final entry in _customColorSchemes.entries) {
      customSchemesJson[entry.key] = entry.value.map((c) => c.value).toList();
    }

    final data = <String, dynamic>{
      'isDarkMode': _isDarkMode,
      'currentKey': _currentKey,
      'isMinor': _isMinor,
      'currentMode': _currentMode,
      'currentChordName': _currentChordName,
      'currentChordNotes': _currentChordNotes,
      'selectedPianoIndices': _selectedPianoIndices.toList(),
      'scaleGroupingMode': _scaleGroupingMode,
      'harmonicDepth': _harmonicDepth,
      'voicingStrategy': _voicingStrategy,
      'octaveShift': _octaveShift,
      'playMode': _playMode,
      'timbre': _timbre,
      'sustainDuration': _sustainDuration,
      'dampPreviousChord': _dampPreviousChord,
      'strumSpeedMs': _strumSpeedMs,
      'instrumentZoom': _instrumentZoom,
      'colorScheme': _colorScheme,
      'scaleGlowIntensity': _scaleGlowIntensity,
      'highlightChordRoot': _highlightChordRoot,
      'highlightScaleRoot': _highlightScaleRoot,
      'instrumentInsertMode': _instrumentInsertMode,
      'customColorSchemes': customSchemesJson,
    };
    StorageService.savePreferences(data);
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }
}
