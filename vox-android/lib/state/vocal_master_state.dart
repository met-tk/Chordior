import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/music_theory.dart';
import '../core/key_signature.dart';
import '../core/app_strings.dart';
import '../models/vocal_range_model.dart';
import '../models/trainer_models.dart';
import '../audio/real_audio_engine.dart';
import '../audio/pitch_detector_service.dart';

/// 软件当前主工作模式
enum StudioMode {
  freePlay,       // 自由弹唱与音高探索模式
  rangeSelect,    // 音区划定与标注模式
  singTrainer,    // 跟唱练声与琶音训练助手
}

/// 人声聆听检测灵敏度等级
enum PitchSensitivity {
  high,           // 高灵敏度 (弱音 / 哼鸣)
  balanced,       // 标准平衡 (推荐默认)
  noiseResistant, // 抗噪稳健 (强音)
}

/// 钢琴键盘亮起发光与余晖效果
enum PianoGlowMode {
  instant,  // 即时响应 (按下亮起，抬起/停音即灭)
  fadeOut,  // 余晖渐隐 (推荐默认，~450ms 优雅淡出)
  trail,    // 多音留痕 (长余晖 ~900ms，产生声音乐动光轨)
}

/// 歌唱音域工作台统一状态管理
class VocalMasterState extends ChangeNotifier {
  VocalMasterState() {
    _initListeningListener();
    _loadPreferences();
    if (_userRanges.isNotEmpty) {
      _activeRange = _userRanges[0];
    }
  }

  // ================= 实时人声聆听与音高识别 =================
  bool _isListeningActive = false;
  bool get isListeningActive => _isListeningActive;

  int? _listeningMidiNote;
  int? get listeningMidiNote => _listeningMidiNote;

  double _listeningPitchHz = 0.0;
  double get listeningPitchHz => _listeningPitchHz;

  StreamSubscription<PitchEvent>? _pitchSub;
  Timer? _silenceTimer;
  final List<int> _pitchFilterBuffer = [];

  // 人声灵敏度配置
  PitchSensitivity _pitchSensitivity = PitchSensitivity.balanced;
  PitchSensitivity get pitchSensitivity => _pitchSensitivity;

  void setPitchSensitivity(PitchSensitivity s) {
    if (_pitchSensitivity != s) {
      _pitchSensitivity = s;
      PitchDetectorService.instance.setSensitivity(s.name);
      notifyListeners();
      _savePreferences();
    }
  }

  // 琴键发光余晖模式配置
  PianoGlowMode _pianoGlowMode = PianoGlowMode.fadeOut;
  PianoGlowMode get pianoGlowMode => _pianoGlowMode;

  void setPianoGlowMode(PianoGlowMode mode) {
    if (_pianoGlowMode != mode) {
      _pianoGlowMode = mode;
      notifyListeners();
      _savePreferences();
    }
  }

  int _octaveJumpCounter = 0;
  int? _octaveJumpTarget;

  void _initListeningListener() {
    _pitchSub = PitchDetectorService.instance.onPitchDetected.listen((event) {
      if (!_isListeningActive) return;
      if (event.active && event.midi != null) {
        _silenceTimer?.cancel();
        final rawMidi = event.midi!;
        _pitchFilterBuffer.add(rawMidi);
        if (_pitchFilterBuffer.length > 4) {
          _pitchFilterBuffer.removeAt(0);
        }

        // 高响应连音平滑滤波算法 (彻底解除连音死锁，兼具抗单帧脉冲杂音与八度防撕裂能力)
        int targetMidi;
        if (_listeningMidiNote == null) {
          // 初始起音：首音瞬时即亮，零延迟
          targetMidi = rawMidi;
          _octaveJumpCounter = 0;
          _octaveJumpTarget = null;
        } else {
          final diff = (rawMidi - _listeningMidiNote!).abs();
          final isOctaveJump = diff > 0 && diff % 12 == 0;

          if (isOctaveJump) {
            if (_octaveJumpTarget == rawMidi) {
              _octaveJumpCounter++;
            } else {
              _octaveJumpTarget = rawMidi;
              _octaveJumpCounter = 1;
            }

            // 抑制八度谐波闪烁：需连续 3 帧确认才跳八度，消除吟唱与扬声器录音时的双八度交替撕裂
            if (_octaveJumpCounter >= 3) {
              targetMidi = rawMidi;
            } else {
              targetMidi = _listeningMidiNote!;
            }
          } else {
            _octaveJumpCounter = 0;
            _octaveJumpTarget = null;

            final len = _pitchFilterBuffer.length;
            // 1. 若最近连续两帧均指向 rawMidi，确信迁移到新音高（连音极速响应：仅需 ~40ms）
            final lastTwoSame = len >= 2 &&
                _pitchFilterBuffer[len - 1] == rawMidi &&
                _pitchFilterBuffer[len - 2] == rawMidi;

            if (lastTwoSame) {
              targetMidi = rawMidi;
            } else if (_pitchFilterBuffer.where((m) => m == _listeningMidiNote).isNotEmpty) {
              // 若历史缓冲区内仍有当前发音的踪影，且新音符仅出现 1 帧，暂保稳定以过滤单帧孤立噪点
              targetMidi = _listeningMidiNote!;
            } else {
              // 老音符已完全退出历史缓冲区（例如快速滑音），立刻跟随最新音符，绝不死锁！
              targetMidi = rawMidi;
            }
          }
        }

        if (_listeningMidiNote != targetMidi || (_listeningPitchHz - event.freq).abs() > 0.5) {
          _listeningMidiNote = targetMidi;
          _listeningPitchHz = event.freq;
          notifyListeners();
        }
      } else {
        _pitchFilterBuffer.clear();
        _octaveJumpCounter = 0;
        _octaveJumpTarget = null;
        _silenceTimer?.cancel();
        _silenceTimer = Timer(const Duration(milliseconds: 250), () {
          if (_listeningMidiNote != null) {
            _listeningMidiNote = null;
            _listeningPitchHz = 0.0;
            notifyListeners();
          }
        });
      }
    });
  }

  Future<void> toggleListeningMode() async {
    if (_isListeningActive) {
      await stopListeningMode();
    } else {
      await startListeningMode();
    }
  }

  Future<bool> startListeningMode() async {
    await PitchDetectorService.instance.setSensitivity(_pitchSensitivity.name);
    final success = await PitchDetectorService.instance.startListening();
    if (success) {
      _isListeningActive = true;
      notifyListeners();
      return true;
    } else {
      _isListeningActive = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopListeningMode() async {
    _isListeningActive = false;
    _listeningMidiNote = null;
    _listeningPitchHz = 0.0;
    _pitchFilterBuffer.clear();
    _silenceTimer?.cancel();
    await PitchDetectorService.instance.stopListening();
    notifyListeners();
  }

  // 当前按下的琴键音符 (MIDI)，默认 C4 (60)
  int _currentMidi = 60;
  int get currentMidi => _currentMidi;

  // 当前选中的音区对象
  VocalRangeItem? _activeRange;
  VocalRangeItem? get activeRange => _activeRange;

  // 用户音区对象列表 (允许范围重叠)
  List<VocalRangeItem> _userRanges = VocalRangeItem.getDefaultPresets();
  List<VocalRangeItem> get userRanges => _userRanges;

  // 划选音区状态
  int? _selectionStartMidi;
  int? _selectionEndMidi;
  int? get selectionStartMidi => _selectionStartMidi;
  int? get selectionEndMidi => _selectionEndMidi;

  // 钢琴键盘方向：水平横向 (horizontal) 或 垂直竖排 (vertical)
  Axis _pianoOrientation = Axis.horizontal;
  Axis get pianoOrientation => _pianoOrientation;

  // 竖排模式下是否高低音反转 (默认 false: 从上到下高音到低音)
  bool _invertVerticalOrder = false;
  bool get invertVerticalOrder => _invertVerticalOrder;

  // 全局 UI 与字体缩放比例 (0.75x ~ 1.30x，默认 1.00x，支持窄屏精细化缩放)
  double _uiScale = 1.0;
  double get uiScale => _uiScale;

  void setUiScale(double val) {
    final clamped = val.clamp(0.75, 1.30);
    _uiScale = (clamped * 100).roundToDouble() / 100.0;
    notifyListeners();
    _savePreferences();
  }

  void resetUiScale() => setUiScale(1.0);

  // 钢琴键盘按键缩放比例 (0.65x ~ 1.85x，默认 0.65x 最低)
  double _keyboardScale = 0.65;
  double get keyboardScale => _keyboardScale;

  void setKeyboardScale(double val) {
    final clamped = val.clamp(0.65, 1.85);
    _keyboardScale = (clamped * 100).roundToDouble() / 100.0;
    notifyListeners();
    _savePreferences();
  }

  void zoomIn() => setKeyboardScale(_keyboardScale + 0.15);
  void zoomOut() => setKeyboardScale(_keyboardScale - 0.15);
  void resetZoom() => setKeyboardScale(0.65);

  // 软件界面语言 (中日英三语)
  AppLanguage _appLanguage = AppLanguage.zh;
  AppLanguage get appLanguage => _appLanguage;
  AppStrings get strings => AppStrings.of(_appLanguage);

  void setLanguage(AppLanguage lang) {
    if (_appLanguage != lang) {
      _appLanguage = lang;
      notifyListeners();
      _savePreferences();
    }
  }

  // 音名五线谱区块高度与空间比例 (默认 118.0px，范围 90.0px ~ 320.0px)
  static const double defaultHeaderHeight = 118.0;
  static const double minHeaderHeight = 90.0;
  static const double maxHeaderHeight = 320.0;

  double _headerHeight = defaultHeaderHeight;
  double get headerHeight => _headerHeight;

  void setHeaderHeight(double val) {
    final clamped = val.clamp(minHeaderHeight, maxHeaderHeight);
    _headerHeight = (clamped * 10).roundToDouble() / 10.0;
    notifyListeners();
    _savePreferences();
  }

  void adjustHeaderHeight(double delta) {
    setHeaderHeight(_headerHeight + delta);
  }

  void resetHeaderHeight() {
    setHeaderHeight(defaultHeaderHeight);
  }

  // ================= 钢琴窗口定位锚点与音区管理窗口高度配置 =================
  /// 全局钢琴窗口定位锚点 Key
  final GlobalKey pianoContainerKey = GlobalKey();

  /// 实时获取钢琴窗口顶部在全局屏幕中的纵向 Y 坐标 (topY)
  double? get pianoTopY {
    final ctx = pianoContainerKey.currentContext;
    if (ctx == null) return null;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.localToGlobal(Offset.zero).dy;
  }

  // 音区管理窗口高度模式：'auto' (自动贴合钢琴上沿) 或 'custom' (自定义高度比例)
  String _rangeManagerHeightMode = 'auto';
  String get rangeManagerHeightMode => _rangeManagerHeightMode;

  void setRangeManagerHeightMode(String mode) {
    _rangeManagerHeightMode = mode;
    notifyListeners();
    _savePreferences();
  }

  // 自定义高度占屏幕总高比例 (0.25 ~ 0.85，默认 0.50)
  double _rangeManagerCustomRatio = 0.50;
  double get rangeManagerCustomRatio => _rangeManagerCustomRatio;

  void setRangeManagerCustomRatio(double ratio) {
    _rangeManagerCustomRatio = ratio.clamp(0.25, 0.85);
    notifyListeners();
    _savePreferences();
  }

  // 自动贴合模式下的微调偏移量 (-100.0 ~ +100.0，默认 50.0)
  double _rangeManagerHeightOffset = 50.0;
  double get rangeManagerHeightOffset => _rangeManagerHeightOffset;

  void setRangeManagerHeightOffset(double offset) {
    _rangeManagerHeightOffset = offset.clamp(-100.0, 100.0);
    notifyListeners();
    _savePreferences();
  }

  void resetRangeManagerHeight() {
    _rangeManagerHeightMode = 'auto';
    _rangeManagerCustomRatio = 0.50;
    _rangeManagerHeightOffset = 50.0;
    notifyListeners();
    _savePreferences();
  }

  // 琴键整体长度比例 (0.30x ~ 1.50x，默认 0.60x 即 60%)
  double _keyLengthRatio = 0.60;
  double get keyLengthRatio => _keyLengthRatio;

  void setKeyLengthRatio(double val) {
    final clamped = val.clamp(0.30, 1.50);
    _keyLengthRatio = (clamped * 100).roundToDouble() / 100.0;
    notifyListeners();
    _savePreferences();
  }

  // 音区元素方位：黑键侧 (默认) 或 白键侧
  RangeIndicatorPosition _rangeIndicatorPosition = RangeIndicatorPosition.blackKeySide;
  RangeIndicatorPosition get rangeIndicatorPosition => _rangeIndicatorPosition;

  void setRangeIndicatorPosition(RangeIndicatorPosition pos) {
    _rangeIndicatorPosition = pos;
    notifyListeners();
    _savePreferences();
  }

  // 音区元素多轨独立分层堆叠展示 (垂直空间/水平空间区分开展示，避免重叠遮挡)
  bool _separateRangeTracks = true;
  bool get separateRangeTracks => _separateRangeTracks;

  void setSeparateRangeTracks(bool val) {
    _separateRangeTracks = val;
    notifyListeners();
    _savePreferences();
  }

  void toggleSeparateRangeTracks() => setSeparateRangeTracks(!_separateRangeTracks);

  /// 快速打开指定音区的编辑设置状态 (配合实体双把手与属性配置)
  void openRangeSettings(VocalRangeItem range) {
    startEditingExistingRange(range);
  }

  /// 单独切换指定音区位于黑键侧或白键侧 (独立属性交互)
  void toggleSingleRangeIndicatorPosition(String rangeId) {
    final idx = _userRanges.indexWhere((r) => r.id == rangeId);
    if (idx != -1) {
      final cur = _userRanges[idx];
      final newPos = cur.indicatorPosition == RangeIndicatorPosition.blackKeySide
          ? RangeIndicatorPosition.whiteKeySide
          : RangeIndicatorPosition.blackKeySide;
      _userRanges[idx] = cur.copyWith(indicatorPosition: newPos);
      if (_activeRange?.id == rangeId) {
        _activeRange = _userRanges[idx];
      }
      if (_editingRange?.id == rangeId) {
        _editingRange = _userRanges[idx];
      }
      notifyListeners();
      _savePreferences();
    }
  }

  // 全局外观模式 (暗黑模式 vs 明亮模式)
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _savePreferences();
  }

  void toggleThemeMode() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  // 正在编辑的现有音区 (非空时表示处于键盘把手编辑该音区模式)
  VocalRangeItem? _editingRange;
  VocalRangeItem? get editingRange => _editingRange;

  // 记谱显示偏好：优先升号 (true: C♯) 或优先降号 (false: D♭)
  bool _preferSharps = true;
  bool get preferSharps => _preferSharps;

  // 八度记谱法标准体系 (默认雅马哈 Yamaha: C3=中央C; 亦支持国际科学记谱法 SPN: C4=中央C)
  OctaveNotation _octaveNotation = OctaveNotation.yamaha;
  OctaveNotation get octaveNotation => _octaveNotation;

  void setOctaveNotation(OctaveNotation notation) {
    if (_octaveNotation != notation) {
      _octaveNotation = notation;
      notifyListeners();
      _savePreferences();
    }
  }

  void toggleOctaveNotation() {
    setOctaveNotation(_octaveNotation == OctaveNotation.spn ? OctaveNotation.yamaha : OctaveNotation.spn);
  }

  // 当前五线谱调号 (默认 C 大调)
  KeySignature _keySignature = KeySignature.defaultKey;
  KeySignature get keySignature => _keySignature;

  void setKeySignature(KeySignature key) {
    _keySignature = key;
    if (key.accidentalCount > 0) {
      _preferSharps = true;
    } else if (key.accidentalCount < 0) {
      _preferSharps = false;
    }
    notifyListeners();
    _savePreferences();
  }

  // 当前模式
  StudioMode _currentMode = StudioMode.freePlay;
  StudioMode get currentMode => _currentMode;

  /// 单击切换到指定模式，若已处于该模式则再次单击返回默认自由弹唱模式
  void toggleMode(StudioMode mode) {
    if (_currentMode == mode) {
      setMode(StudioMode.freePlay);
    } else {
      setMode(mode);
    }
  }

  // 乐器音色
  String _currentTimbre = 'Concert Grand';
  String get currentTimbre => _currentTimbre;

  // 琴键点击单音防混叠快速渐弱包络 (Voice Damping)
  bool _pianoVoiceDamping = true;
  bool get pianoVoiceDamping => _pianoVoiceDamping;

  void setPianoVoiceDamping(bool value) {
    if (_pianoVoiceDamping != value) {
      _pianoVoiceDamping = value;
      notifyListeners();
      _savePreferences();
    }
  }

  // 练声跟唱状态
  TrainerPattern _trainerPattern = TrainerPattern.presets[0];
  TrainerPattern get trainerPattern => _trainerPattern;

  int _trainerRootMidi = 60; // 练声当前根音 C4
  int get trainerRootMidi => _trainerRootMidi;

  int _trainerBpm = 80; // 练声速度
  int get trainerBpm => _trainerBpm;

  bool _isPlayingTrainer = false;
  bool get isPlayingTrainer => _isPlayingTrainer;

  int? _trainerNoteHighlight; // 练声时当前播放音符高亮
  int? get trainerNoteHighlight => _trainerNoteHighlight;

  Timer? _trainerTimer;

  /// 快速切换音区指示方位 (黑键侧 ⇄ 白键侧)
  void toggleRangeIndicatorPosition() {
    _rangeIndicatorPosition = (_rangeIndicatorPosition == RangeIndicatorPosition.blackKeySide)
        ? RangeIndicatorPosition.whiteKeySide
        : RangeIndicatorPosition.blackKeySide;
    notifyListeners();
    _savePreferences();
  }

  /// 点击或触摸钢琴键发音
  void onPianoKeyPressed(int midi) {
    _currentMidi = midi;
    RealAudioEngine.instance.playNote(midi, dampPrevious: _pianoVoiceDamping);

    // 检查当前按键是否落在某个音区内，优先高亮匹配的音区
    final matching = _userRanges.where((r) => r.containsMidi(midi)).toList();
    if (matching.isNotEmpty && (_activeRange == null || !_activeRange!.containsMidi(midi))) {
      _activeRange = matching.first;
    }

    notifyListeners();
  }

  /// 松开琴键
  void onPianoKeyReleased(int midi) {
    // 教堂管风琴 (Church Organ)、音乐会长笛 (Concert Flute)、独奏小提琴 (Solo Violin) 等持续发音乐器
    // 需要在松开手指时平滑停音，实现长按延音、短按短奏；
    // 钢琴、电钢琴、吉他、钢片琴等原声击弦拨弦乐器具有自然延音衰减，抬手时保持自然泛音回响。
    const sustainedInstruments = {
      'Church Organ',
      'Concert Flute',
      'Solo Violin',
    };
    if (sustainedInstruments.contains(RealAudioEngine.instance.currentTimbre)) {
      RealAudioEngine.instance.stopNote(midi);
    }
  }

  /// 快速切换音区管理窗口纵向高度模式 (自动适配 ⇄ 自定义高度)
  void toggleRangeManagerHeightMode() {
    _rangeManagerHeightMode = (_rangeManagerHeightMode == 'auto') ? 'custom' : 'auto';
    notifyListeners();
    _savePreferences();
  }

  /// 选中特定音区对象
  void selectRange(VocalRangeItem range) {
    _activeRange = range;
    // 自动将当前信息音符定位到该音区的起始音或根音
    _currentMidi = range.startMidi;
    notifyListeners();
    _savePreferences();
  }

  /// 播放试听整个音区 (起始音 + 终止音 + 琶音)
  void previewRange(VocalRangeItem range) {
    selectRange(range);
    final notes = <int>[];
    // 收集音区内的自然三和弦或端点音
    notes.add(range.startMidi);
    if (range.semitones > 4) {
      notes.add(range.startMidi + 4);
    }
    if (range.semitones > 7) {
      notes.add(range.startMidi + 7);
    }
    notes.add(range.endMidi);
    RealAudioEngine.instance.playSequence(notes, speedMs: 250, dampPrevious: _pianoVoiceDamping);
  }

  /// 切换钢琴键盘方向 (横向 / 竖排)
  void togglePianoOrientation() {
    _pianoOrientation = (_pianoOrientation == Axis.horizontal) ? Axis.vertical : Axis.horizontal;
    notifyListeners();
    _savePreferences();
  }

  void setInvertVerticalOrder(bool val) {
    _invertVerticalOrder = val;
    notifyListeners();
    _savePreferences();
  }

  /// 切换升降号偏好
  void togglePreferSharps() {
    _preferSharps = !_preferSharps;
    notifyListeners();
    _savePreferences();
  }

  /// 切换工作模式
  void setMode(StudioMode mode) {
    _currentMode = mode;
    if (mode == StudioMode.rangeSelect) {
      _selectionStartMidi ??= 60;
      _selectionEndMidi ??= 67;
    } else {
      _selectionStartMidi = null;
      _selectionEndMidi = null;
    }
    if (mode != StudioMode.singTrainer && _isPlayingTrainer) {
      stopTrainer();
    }
    notifyListeners();
    _savePreferences();
  }

  /// 切换音源
  void setTimbre(String timbre) {
    _currentTimbre = timbre;
    RealAudioEngine.instance.setTimbre(timbre);
    notifyListeners();
    _savePreferences();
  }

  /// 调节主音量
  double get audioVolume => RealAudioEngine.instance.volume;
  void setAudioVolume(double val) {
    RealAudioEngine.instance.volume = val;
    notifyListeners();
    _savePreferences();
  }

  /// 设置划选范围
  void setSelectionRange(int start, int end) {
    _selectionStartMidi = start < end ? start : end;
    _selectionEndMidi = start < end ? end : start;
    _currentMidi = _selectionStartMidi!;
    notifyListeners();
    _savePreferences();
  }

  /// 清空划选范围
  void clearSelection() {
    _selectionStartMidi = null;
    _selectionEndMidi = null;
    notifyListeners();
    _savePreferences();
  }

  /// 将当前划选保存为音区对象
  void saveCurrentSelectionAsRange({
    required String name,
    required VocalRangeType type,
    required Color color,
    String description = '',
    RangeIndicatorPosition indicatorPosition = RangeIndicatorPosition.blackKeySide,
    int gradientSteps = 6,
    bool gradientReversed = false,
    double startOpacity = 0.70,
    double endOpacity = 0.05,
  }) {
    if (_selectionStartMidi == null || _selectionEndMidi == null) return;

    final newItem = VocalRangeItem(
      id: 'range_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      startMidi: _selectionStartMidi!,
      endMidi: _selectionEndMidi!,
      color: color,
      description: description.isNotEmpty
          ? description
          : MusicTheory.getVoiceRangeDescription(name, _selectionStartMidi!, _selectionEndMidi!),
      indicatorPosition: indicatorPosition,
      gradientSteps: gradientSteps,
      gradientReversed: gradientReversed,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
    );

    _userRanges.add(newItem);
    _activeRange = newItem;
    _selectionStartMidi = null;
    _selectionEndMidi = null;
    _currentMode = StudioMode.freePlay;

    _savePreferences();
    notifyListeners();
  }

  /// 更新已有音区
  void updateRange(VocalRangeItem item) {
    final idx = _userRanges.indexWhere((r) => r.id == item.id);
    if (idx != -1) {
      _userRanges[idx] = item;
      if (_activeRange?.id == item.id) {
        _activeRange = item;
      }
      _savePreferences();
      notifyListeners();
    }
  }

  /// 直接添加音区对象 (用于导入、模板克隆或单元测试)
  void addCustomRange(VocalRangeItem item) {
    _userRanges.add(item);
    _savePreferences();
    notifyListeners();
  }

  /// 开始在钢琴键盘上编辑已有音区 (载入现有范围，唤出把手)
  void startEditingExistingRange(VocalRangeItem range) {
    _editingRange = range;
    _currentMode = StudioMode.rangeSelect;
    _selectionStartMidi = range.startMidi;
    _selectionEndMidi = range.endMidi;
    _activeRange = range;
    notifyListeners();
  }

  /// 保存当前键盘把手编辑后的音区修改
  void saveEditedRange({
    String? name,
    VocalRangeType? type,
    Color? color,
    String? description,
    RangeIndicatorPosition? indicatorPosition,
    int? gradientSteps,
    bool? gradientReversed,
    double? startOpacity,
    double? endOpacity,
  }) {
    if (_editingRange == null || _selectionStartMidi == null || _selectionEndMidi == null) return;
    final updated = _editingRange!.copyWith(
      name: name ?? _editingRange!.name,
      type: type ?? _editingRange!.type,
      color: color ?? _editingRange!.color,
      startMidi: _selectionStartMidi!,
      endMidi: _selectionEndMidi!,
      description: description ?? _editingRange!.description,
      indicatorPosition: indicatorPosition ?? _editingRange!.indicatorPosition,
      gradientSteps: gradientSteps ?? _editingRange!.gradientSteps,
      gradientReversed: gradientReversed ?? _editingRange!.gradientReversed,
      startOpacity: startOpacity ?? _editingRange!.startOpacity,
      endOpacity: endOpacity ?? _editingRange!.endOpacity,
    );
    updateRange(updated);
    _editingRange = null;
    _selectionStartMidi = null;
    _selectionEndMidi = null;
    _currentMode = StudioMode.freePlay;
    notifyListeners();
  }

  /// 取消编辑已有音区
  void cancelEditingRange() {
    _editingRange = null;
    _selectionStartMidi = null;
    _selectionEndMidi = null;
    _currentMode = StudioMode.freePlay;
    notifyListeners();
  }

  /// 删除音区
  void deleteRange(String id) {
    _userRanges.removeWhere((r) => r.id == id);
    if (_activeRange?.id == id) {
      _activeRange = _userRanges.isNotEmpty ? _userRanges.first : null;
    }
    _savePreferences();
    notifyListeners();
  }

  /// 恢复默认音区预设
  void resetDefaultRanges() {
    _userRanges = VocalRangeItem.getDefaultPresets();
    _activeRange = _userRanges.first;
    _savePreferences();
    notifyListeners();
  }

  // ================= 音区轨道排组管理 (Track Groups & Combination) =================

  /// 尝试将两个无重叠音区合并至同一排（若存在范围重叠则返回 false 并拒绝合并）
  bool tryMergeRangesToSameTrack(String sourceId, String targetId) {
    if (sourceId == targetId) return false;
    final sourceIdx = _userRanges.indexWhere((r) => r.id == sourceId);
    final targetIdx = _userRanges.indexWhere((r) => r.id == targetId);
    if (sourceIdx == -1 || targetIdx == -1) return false;

    final source = _userRanges[sourceIdx];
    final target = _userRanges[targetIdx];

    // 充要条件1：两者必须属于同一侧（同属黑键侧或同属白键侧）
    if (source.indicatorPosition != target.indicatorPosition) {
      return false;
    }

    // 充要条件2：两者绝对不能有重叠
    if (source.overlapsWith(target)) {
      return false;
    }

    // 检查目标所在组内是否还有其他成员，若有，source 也必须与它们全都不重叠
    final targetGroupId = target.trackGroupId ?? 'group_${target.id}';
    final existingGroupMembers = _userRanges.where(
      (r) => r.id != source.id && (r.trackGroupId == targetGroupId || r.id == target.id),
    );

    if (!source.canShareTrackWithAll(existingGroupMembers)) {
      return false;
    }

    // 合并：统一赋予 targetGroupId
    target.trackGroupId = targetGroupId;
    source.trackGroupId = targetGroupId;
    _savePreferences();
    notifyListeners();
    return true;
  }

  /// 尝试将某个音区加入已有轨道排组（若与组内任意音区重叠则返回 false）
  bool tryAddRangeToTrackGroup(String rangeId, String targetGroupId) {
    final rangeIdx = _userRanges.indexWhere((r) => r.id == rangeId);
    if (rangeIdx == -1) return false;
    final range = _userRanges[rangeIdx];

    final groupMembers = _userRanges.where((r) => r.id != rangeId && r.trackGroupId == targetGroupId);
    if (!range.canShareTrackWithAll(groupMembers)) {
      return false;
    }

    range.trackGroupId = targetGroupId;
    _savePreferences();
    notifyListeners();
    return true;
  }

  /// 获取某个音区在其所在键侧排道中的所有伙伴音区（除其自身之外）
  List<VocalRangeItem> getTrackPartners(VocalRangeItem item) {
    final isBlack = item.indicatorPosition == RangeIndicatorPosition.blackKeySide;
    final lanes = getLanesForSide(isBlack);
    for (final lane in lanes) {
      if (lane.any((r) => r.id == item.id)) {
        return lane.where((r) => r.id != item.id).toList();
      }
    }
    return [];
  }

  /// 校验两个音区是否满足交替置换 (Swap) 条件：
  /// 只要源音区替换目标音区后与目标所在排其余伙伴无重叠，
  /// 且目标音区替换源音区后与源所在排其余伙伴无重叠，即允许交换！
  /// 无论两音区是否同侧（黑键侧 / 白键侧），均完全支持自由置换。
  bool canSwapRanges(String sourceId, String targetId) {
    if (sourceId == targetId) return false;
    final sourceIdx = _userRanges.indexWhere((r) => r.id == sourceId);
    final targetIdx = _userRanges.indexWhere((r) => r.id == targetId);
    if (sourceIdx == -1 || targetIdx == -1) return false;

    final source = _userRanges[sourceIdx];
    final target = _userRanges[targetIdx];

    final targetPartners = getTrackPartners(target);
    final sourcePartners = getTrackPartners(source);

    // 校验 A：源音区替换目标音区放入目标排
    // 目标排中除 target 外其余所有音区，不能与 source 发生任何范围重叠
    if (targetPartners.isNotEmpty) {
      if (targetPartners.any((p) => p.overlapsWith(source))) {
        return false;
      }
    }

    // 校验 B：目标音区替换源音区放入源排
    // 源排中除 source 外其余所有音区，不能与 target 发生任何范围重叠
    if (sourcePartners.isNotEmpty) {
      if (sourcePartners.any((p) => p.overlapsWith(target))) {
        return false;
      }
    }

    return true;
  }

  int _lastSwapTimestamp = 0;
  String? _lastSwapPair;

  /// 尝试将两个音区进行交替置换 (Swap)
  /// 支持跨侧置换：置换后各自继承对方排的方位 (indicatorPosition) 与排道次序
  bool trySwapRanges(String sourceId, String targetId) {
    if (sourceId == targetId) return false;
    if (!canSwapRanges(sourceId, targetId)) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final pairKey = sourceId.compareTo(targetId) < 0 ? '${sourceId}_$targetId' : '${targetId}_$sourceId';
    if (_lastSwapPair == pairKey && (now - _lastSwapTimestamp) < 250) {
      // 250ms 内同一对音区的重复触发（如嵌套 DragTarget 重复触发），做安全幂等拦截
      return true;
    }

    final sourceIdx = _userRanges.indexWhere((r) => r.id == sourceId);
    final targetIdx = _userRanges.indexWhere((r) => r.id == targetId);
    if (sourceIdx == -1 || targetIdx == -1) return false;

    final source = _userRanges[sourceIdx];
    final target = _userRanges[targetIdx];

    final targetPartners = getTrackPartners(target);
    final sourcePartners = getTrackPartners(source);

    // 保存置换双方原方位与排属性
    final originalSourcePos = source.indicatorPosition;
    final originalSourceOrder = source.trackOrder;
    final originalSourceGroupId = source.trackGroupId;

    final originalTargetPos = target.indicatorPosition;
    final originalTargetOrder = target.trackOrder;
    final originalTargetGroupId = target.trackGroupId;

    // 1. source 换入 target 原排：继承 target 原排方位与次序
    source.indicatorPosition = originalTargetPos;
    source.trackOrder = originalTargetOrder;
    if (targetPartners.isNotEmpty) {
      final targetGroupId = originalTargetGroupId ?? 'group_lane_${DateTime.now().millisecondsSinceEpoch}_T';
      source.trackGroupId = targetGroupId;
      for (final p in targetPartners) {
        p.trackGroupId = targetGroupId;
        p.indicatorPosition = originalTargetPos;
        p.trackOrder = originalTargetOrder;
      }
    } else {
      source.trackGroupId = null;
    }

    // 2. target 换入 source 原排：继承 source 原排方位与次序
    target.indicatorPosition = originalSourcePos;
    target.trackOrder = originalSourceOrder;
    if (sourcePartners.isNotEmpty) {
      final sourceGroupId = originalSourceGroupId ?? 'group_lane_${DateTime.now().millisecondsSinceEpoch}_S';
      target.trackGroupId = sourceGroupId;
      for (final p in sourcePartners) {
        p.trackGroupId = sourceGroupId;
        p.indicatorPosition = originalSourcePos;
        p.trackOrder = originalSourceOrder;
      }
    } else {
      target.trackGroupId = null;
    }

    // 3. 交换在全局音区列表中的顺序
    final temp = _userRanges[sourceIdx];
    _userRanges[sourceIdx] = _userRanges[targetIdx];
    _userRanges[targetIdx] = temp;

    _lastSwapTimestamp = now;
    _lastSwapPair = pairKey;

    _savePreferences();
    notifyListeners();
    return true;
  }

  /// 获取指定键侧的所有排列表（每排为 List<VocalRangeItem>，按当前 trackOrder 升序排列）
  List<List<VocalRangeItem>> getLanesForSide(bool isBlackSide) {
    final targetPos = isBlackSide ? RangeIndicatorPosition.blackKeySide : RangeIndicatorPosition.whiteKeySide;
    final sideRanges = _userRanges.where((r) => r.indicatorPosition == targetPos).toList();
    if (sideRanges.isEmpty) return [];

    final allocation = RangeLaneAllocation.compute(sideRanges);
    final Map<int, List<VocalRangeItem>> laneMap = {};
    for (final r in sideRanges) {
      final lane = allocation.rangeIdToLane[r.id] ?? 0;
      laneMap.putIfAbsent(lane, () => []).add(r);
    }
    final sortedLanes = laneMap.keys.toList()..sort();
    return sortedLanes.map((l) => laneMap[l]!).toList();
  }

  /// 调整同一键侧内两个排的先后次序 (如上移或下移)，并实时同步更新所有相关音区的 trackOrder 与物理泳道
  void swapLaneOrder({required bool isBlackSide, required int indexA, required int indexB}) {
    final lanes = getLanesForSide(isBlackSide);
    if (indexA < 0 || indexA >= lanes.length || indexB < 0 || indexB >= lanes.length || indexA == indexB) {
      return;
    }

    final laneA = lanes[indexA];
    final laneB = lanes[indexB];

    // 确保两排都有明确的 trackGroupId，使得互换后保持各自组的排布
    final groupA = laneA.first.trackGroupId ?? 'group_${laneA.first.id}_${DateTime.now().millisecondsSinceEpoch}';
    final groupB = laneB.first.trackGroupId ?? 'group_${laneB.first.id}_${DateTime.now().millisecondsSinceEpoch}';
    for (final r in laneA) {
      r.trackGroupId = groupA;
      r.trackOrder = indexB; // 赋予新顺序
    }
    for (final r in laneB) {
      r.trackGroupId = groupB;
      r.trackOrder = indexA; // 赋予新顺序
    }

    // 刷新该侧其余排的 trackOrder，保持整体有序
    for (int i = 0; i < lanes.length; i++) {
      if (i != indexA && i != indexB) {
        for (final r in lanes[i]) {
          r.trackOrder = i;
        }
      }
    }

    _savePreferences();
    notifyListeners();
  }

  /// 将音区从轨道排组中移出（恢复为独立排）
  void removeRangeFromTrackGroup(String rangeId) {
    final rangeIdx = _userRanges.indexWhere((r) => r.id == rangeId);
    if (rangeIdx != -1) {
      _userRanges[rangeIdx].trackGroupId = null;
      _savePreferences();
      notifyListeners();
    }
  }

  /// 一键重置所有音区自定义分组（恢复为系统智能自动避让分轨）
  void resetAllTrackGroups() {
    for (final r in _userRanges) {
      r.trackGroupId = null;
      r.trackOrder = 0;
    }
    _savePreferences();
    notifyListeners();
  }

  // ================= 跟唱练声控制逻辑 =================

  void setTrainerPattern(TrainerPattern pattern) {
    _trainerPattern = pattern;
    notifyListeners();
    _savePreferences();
  }

  void setTrainerRootMidi(int midi) {
    _trainerRootMidi = midi;
    _currentMidi = midi;
    notifyListeners();
    _savePreferences();
  }

  void setTrainerBpm(int bpm) {
    _trainerBpm = bpm;
    notifyListeners();
    _savePreferences();
  }

  /// 启动跟唱练习
  void startTrainer() {
    if (_isPlayingTrainer) return;
    _isPlayingTrainer = true;
    notifyListeners();

    _runTrainerStep();
  }

  void _runTrainerStep() {
    if (!_isPlayingTrainer) return;

    final intervalMs = (60000 / _trainerBpm).round();
    final pitches = _trainerPattern.relativeSemitones.map((s) => _trainerRootMidi + s).toList();

    int step = 0;
    _trainerTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_isPlayingTrainer) {
        timer.cancel();
        return;
      }

      if (step < pitches.length) {
        final currentPitch = pitches[step];
        _trainerNoteHighlight = currentPitch;
        _currentMidi = currentPitch;
        RealAudioEngine.instance.playNote(currentPitch, dampPrevious: _pianoVoiceDamping);
        notifyListeners();
        step++;
      } else {
        timer.cancel();
        _trainerNoteHighlight = null;
        notifyListeners();

        // 唱完一遍后，停留 1 个小节，然后自动向上半音移调 (半音爬坡练声)！
        Future.delayed(Duration(milliseconds: intervalMs * 2), () {
          if (_isPlayingTrainer) {
            // 爬升半音，最高限制在 A5 (81)
            if (_trainerRootMidi < 72) {
              _trainerRootMidi += 1;
            } else {
              _trainerRootMidi = 48; // 回到 C3 重新循环
            }
            _runTrainerStep();
          }
        });
      }
    });
  }

  /// 停止跟唱
  void stopTrainer() {
    _isPlayingTrainer = false;
    _trainerTimer?.cancel();
    _trainerNoteHighlight = null;
    RealAudioEngine.instance.stopAll();
    notifyListeners();
  }

  /// 切换指定音区在键盘上的显示/隐藏状态
  void toggleRangeVisibility(String rangeId) {
    final idx = _userRanges.indexWhere((r) => r.id == rangeId);
    if (idx != -1) {
      final cur = _userRanges[idx];
      _userRanges[idx] = cur.copyWith(isVisible: !cur.isVisible);
      if (_activeRange?.id == rangeId) {
        _activeRange = _userRanges[idx];
      }
      notifyListeners();
      _savePreferences();
    }
  }

  /// 用户自定义预设字典: `presetName -> List<VocalRangeItem>`
  Map<String, List<VocalRangeItem>> _userPresets = {};
  Map<String, List<VocalRangeItem>> get userPresets => _userPresets;
  List<String> get userPresetNames => _userPresets.keys.toList();

  /// 将当前所有音区保存为一个自定义预设
  void saveCurrentRangesAsPreset(String presetName) {
    if (presetName.trim().isEmpty) return;
    final copy = _userRanges.map((r) => r.copyWith()).toList();
    _userPresets[presetName.trim()] = copy;
    notifyListeners();
    _savePreferences();
  }

  /// 载入指定的用户预设
  void loadPreset(String presetName) {
    if (_userPresets.containsKey(presetName)) {
      _userRanges = _userPresets[presetName]!.map((r) => r.copyWith()).toList();
      _activeRange = _userRanges.isNotEmpty ? _userRanges.first : null;
      notifyListeners();
      _savePreferences();
    }
  }

  /// 删除指定用户预设
  void deletePreset(String presetName) {
    if (_userPresets.containsKey(presetName)) {
      _userPresets.remove(presetName);
      notifyListeners();
      _savePreferences();
    }
  }

  // ================= 本地数据持久化 =================

  /// 供外部生命周期监听 (切后台、暂停、退出) 调用
  Future<void> savePreferences() => _savePreferences();

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _userRanges.map((r) => r.toJson()).toList();
      await prefs.setString('user_vocal_ranges', jsonEncode(jsonList));
      await prefs.setBool('prefer_sharps', _preferSharps);
      await prefs.setDouble('vocal_keyboard_scale', _keyboardScale);
      await prefs.setDouble('vocal_key_length_ratio', _keyLengthRatio);
      await prefs.setDouble('vocal_ui_scale', _uiScale);
      await prefs.setDouble('vocal_header_height', _headerHeight);
      await prefs.setString('vocal_range_indicator_pos', _rangeIndicatorPosition.name);
      await prefs.setBool('vocal_separate_range_tracks', _separateRangeTracks);
      await prefs.setString('vocal_range_manager_height_mode', _rangeManagerHeightMode);
      await prefs.setDouble('vocal_range_manager_custom_ratio', _rangeManagerCustomRatio);
      await prefs.setDouble('vocal_range_manager_height_offset', _rangeManagerHeightOffset);
      await prefs.setString('app_theme_mode', _themeMode.name);
      await prefs.setString('app_language', _appLanguage.name);
      await prefs.setString('vocal_pitch_sensitivity', _pitchSensitivity.name);
      await prefs.setString('vocal_piano_glow_mode', _pianoGlowMode.name);
      await prefs.setBool('piano_voice_damping', _pianoVoiceDamping);
      await prefs.setString('vocal_octave_notation', _octaveNotation.name);
      await prefs.setDouble('vocal_audio_volume', RealAudioEngine.instance.volume);

      // 设置项补齐
      await prefs.setString('vocal_current_timbre', _currentTimbre);
      await prefs.setString('vocal_piano_orientation', _pianoOrientation == Axis.vertical ? 'vertical' : 'horizontal');
      await prefs.setBool('vocal_invert_vertical_order', _invertVerticalOrder);
      await prefs.setString('vocal_key_signature', _keySignature.id);

      // 退出前界面状态
      if (_activeRange != null) {
        await prefs.setString('vocal_active_range_id', _activeRange!.id);
      }
      await prefs.setString('vocal_current_mode', _currentMode.name);
      await prefs.setInt('vocal_current_midi', _currentMidi);
      if (_selectionStartMidi != null) {
        await prefs.setInt('vocal_selection_start_midi', _selectionStartMidi!);
      } else {
        await prefs.remove('vocal_selection_start_midi');
      }
      if (_selectionEndMidi != null) {
        await prefs.setInt('vocal_selection_end_midi', _selectionEndMidi!);
      } else {
        await prefs.remove('vocal_selection_end_midi');
      }

      // 跟唱练声状态
      await prefs.setString('vocal_trainer_pattern_id', _trainerPattern.id);
      await prefs.setInt('vocal_trainer_root_midi', _trainerRootMidi);
      await prefs.setInt('vocal_trainer_bpm', _trainerBpm);

      // 保存用户自定义预设集
      final presetsMap = <String, dynamic>{};
      _userPresets.forEach((k, v) {
        presetsMap[k] = v.map((r) => r.toJson()).toList();
      });
      await prefs.setString('user_saved_presets', jsonEncode(presetsMap));
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawRanges = prefs.getString('user_vocal_ranges');
      if (rawRanges != null) {
        final decoded = jsonDecode(rawRanges) as List;
        _userRanges = decoded.map((item) => VocalRangeItem.fromJson(item as Map<String, dynamic>)).toList();
      }

      // 优先恢复退出前激活选中的音区
      final savedActiveId = prefs.getString('vocal_active_range_id');
      if (_userRanges.isNotEmpty) {
        if (savedActiveId != null) {
          _activeRange = _userRanges.firstWhere(
            (r) => r.id == savedActiveId,
            orElse: () => _userRanges.first,
          );
        } else {
          _activeRange = _userRanges.first;
        }
      }

      final rawPresets = prefs.getString('user_saved_presets');
      if (rawPresets != null) {
        final decodedMap = jsonDecode(rawPresets) as Map<String, dynamic>;
        _userPresets = decodedMap.map((k, v) {
          final list = (v as List).map((i) => VocalRangeItem.fromJson(i as Map<String, dynamic>)).toList();
          return MapEntry(k, list);
        });
      }

      _preferSharps = prefs.getBool('prefer_sharps') ?? true;
      final octNotation = prefs.getString('vocal_octave_notation');
      if (octNotation == 'spn') {
        _octaveNotation = OctaveNotation.spn;
      } else {
        _octaveNotation = OctaveNotation.yamaha;
      }
      _keyboardScale = prefs.getDouble('vocal_keyboard_scale') ?? 0.65;
      _keyLengthRatio = prefs.getDouble('vocal_key_length_ratio') ?? 0.60;
      _uiScale = prefs.getDouble('vocal_ui_scale') ?? 1.0;
      _headerHeight = (prefs.getDouble('vocal_header_height') ?? defaultHeaderHeight).clamp(minHeaderHeight, maxHeaderHeight);
      _separateRangeTracks = prefs.getBool('vocal_separate_range_tracks') ?? true;
      _rangeManagerHeightMode = prefs.getString('vocal_range_manager_height_mode') ?? 'auto';
      _rangeManagerCustomRatio = (prefs.getDouble('vocal_range_manager_custom_ratio') ?? 0.50).clamp(0.25, 0.85);
      _rangeManagerHeightOffset = (prefs.getDouble('vocal_range_manager_height_offset') ?? 50.0).clamp(-100.0, 100.0);
      RealAudioEngine.instance.volume = prefs.getDouble('vocal_audio_volume') ?? 1.0;

      // 乐器音色恢复并联动底层音频引擎
      final savedTimbre = prefs.getString('vocal_current_timbre');
      if (savedTimbre != null && savedTimbre.isNotEmpty) {
        _currentTimbre = savedTimbre;
        RealAudioEngine.instance.setTimbre(savedTimbre);
      }

      // 键盘方向与竖排高低音顺序
      final orient = prefs.getString('vocal_piano_orientation');
      if (orient == 'vertical') {
        _pianoOrientation = Axis.vertical;
      } else if (orient == 'horizontal') {
        _pianoOrientation = Axis.horizontal;
      }
      _invertVerticalOrder = prefs.getBool('vocal_invert_vertical_order') ?? false;

      // 调号恢复
      final savedKeyId = prefs.getString('vocal_key_signature');
      if (savedKeyId != null) {
        _keySignature = KeySignature.all.firstWhere(
          (k) => k.id == savedKeyId,
          orElse: () => KeySignature.defaultKey,
        );
      }

      // 聚焦音符与划选范围
      _currentMidi = prefs.getInt('vocal_current_midi') ?? 60;
      _selectionStartMidi = prefs.getInt('vocal_selection_start_midi');
      _selectionEndMidi = prefs.getInt('vocal_selection_end_midi');

      // 主工作模式恢复
      final savedModeName = prefs.getString('vocal_current_mode');
      if (savedModeName != null) {
        _currentMode = StudioMode.values.firstWhere(
          (m) => m.name == savedModeName,
          orElse: () => StudioMode.freePlay,
        );
      }

      // 跟唱练声状态恢复
      final savedPatternId = prefs.getString('vocal_trainer_pattern_id');
      if (savedPatternId != null) {
        _trainerPattern = TrainerPattern.presets.firstWhere(
          (p) => p.id == savedPatternId,
          orElse: () => TrainerPattern.presets[0],
        );
      }
      _trainerRootMidi = prefs.getInt('vocal_trainer_root_midi') ?? 60;
      _trainerBpm = prefs.getInt('vocal_trainer_bpm') ?? 80;

      final posName = prefs.getString('vocal_range_indicator_pos');
      if (posName != null) {
        _rangeIndicatorPosition = RangeIndicatorPosition.values.firstWhere(
          (p) => p.name == posName,
          orElse: () => RangeIndicatorPosition.blackKeySide,
        );
      }
      final themeName = prefs.getString('app_theme_mode');
      if (themeName != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == themeName,
          orElse: () => ThemeMode.dark,
        );
      }
      final langName = prefs.getString('app_language');
      if (langName != null) {
        _appLanguage = AppLanguage.values.firstWhere(
          (l) => l.name == langName,
          orElse: () => AppLanguage.zh,
        );
      }
      final sensName = prefs.getString('vocal_pitch_sensitivity');
      if (sensName != null) {
        _pitchSensitivity = PitchSensitivity.values.firstWhere(
          (s) => s.name == sensName,
          orElse: () => PitchSensitivity.balanced,
        );
        PitchDetectorService.instance.setSensitivity(_pitchSensitivity.name);
      }
      final glowName = prefs.getString('vocal_piano_glow_mode');
      if (glowName != null) {
        _pianoGlowMode = PianoGlowMode.values.firstWhere(
          (m) => m.name == glowName,
          orElse: () => PianoGlowMode.fadeOut,
        );
      }
      _pianoVoiceDamping = prefs.getBool('piano_voice_damping') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _trainerTimer?.cancel();
    _silenceTimer?.cancel();
    _pitchSub?.cancel();
    PitchDetectorService.instance.stopListening();
    super.dispose();
  }
}
