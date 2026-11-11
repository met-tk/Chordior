import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/music_theory.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

class _BlackKeyInfo {
  final int midi;
  final double leftOffset;
  const _BlackKeyInfo({required this.midi, required this.leftOffset});
}

/// 优雅横向水平钢琴键盘组件
/// 特性：
/// 1. 括线严格收敛于琴键内部，不向白键下端溢出
/// 2. 渐变覆盖层置于黑白键共同顶层，黑键与白键均享受通透渐变发光染色，且具有多段呼吸衰减
/// 3. 支持音区元素方位切换 (靠近黑键侧 / 靠近白键侧)
/// 4. 支持琴键整体长度比率 (keyLengthRatio) 与缩放
/// 5. 完全去除杂乱小圆点，保持琴键纯净高质感
/// 6. 支持琴键渐变褪色余晖与多音留痕光轨动效 (PianoGlowMode)
class HorizontalPianoWidget extends StatefulWidget {
  final int minMidi;
  final int maxMidi;
  final int activeMidi;
  final int? listeningMidi;
  final List<VocalRangeItem> ranges;
  final VocalRangeItem? activeRange;
  final int? selectionStart;
  final int? selectionEnd;
  final bool isSelectionMode;
  final bool preferSharp;
  final double scale;
  final double keyLengthRatio;
  final RangeIndicatorPosition rangeIndicatorPosition;
  final bool separateRangeTracks;
  final PianoGlowMode glowMode;
  final Function(int) onKeyPressed;
  final Function(int) onKeyReleased;
  final Function(VocalRangeItem)? onSelectRange;
  final Function(VocalRangeItem)? onLongPressRange;
  final Function(double)? onScaleChanged;
  final Function(int start, int end)? onSelectionRangeChanged;
  final OctaveNotation octaveNotation;

  const HorizontalPianoWidget({
    super.key,
    this.minMidi = 36, // Yamaha C1 (SPN C2)
    this.maxMidi = 96, // Yamaha C6 (SPN C7)
    required this.activeMidi,
    this.listeningMidi,
    required this.ranges,
    required this.activeRange,
    this.selectionStart,
    this.selectionEnd,
    this.isSelectionMode = false,
    this.preferSharp = true,
    this.scale = 1.0,
    this.keyLengthRatio = 1.0,
    this.rangeIndicatorPosition = RangeIndicatorPosition.blackKeySide,
    this.separateRangeTracks = false,
    this.glowMode = PianoGlowMode.fadeOut,
    this.octaveNotation = OctaveNotation.spn,
    required this.onKeyPressed,
    required this.onKeyReleased,
    this.onSelectRange,
    this.onLongPressRange,
    this.onScaleChanged,
    this.onSelectionRangeChanged,
  });

  @override
  State<HorizontalPianoWidget> createState() => _HorizontalPianoWidgetState();
}

class _HorizontalPianoWidgetState extends State<HorizontalPianoWidget> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();
  final Set<int> _pressedKeys = {};

  // 琴键动态发光衰减表: midi -> intensity (0.0 ~ 1.0)
  final Map<int, double> _keyGlow = {};
  Ticker? _glowTicker;
  Duration _lastElapsed = Duration.zero;

  bool _isDraggingLeftHandle = false;
  bool _isDraggingRightHandle = false;
  bool get _isDraggingAnyHandle => _isDraggingLeftHandle || _isDraggingRightHandle;

  double get whiteKeyWidth => 38.0 * widget.scale;
  double get blackKeyWidth => 24.0 * widget.scale;

  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _checkAndActivateGlow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMidi(widget.activeMidi, animated: false);
    });
  }

  @override
  void didUpdateWidget(covariant HorizontalPianoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndActivateGlow();
  }

  void _checkAndActivateGlow() {
    if (widget.glowMode == PianoGlowMode.instant) {
      _glowTicker?.stop();
      _keyGlow.clear();
      return;
    }

    bool added = false;
    if (widget.listeningMidi != null && widget.listeningMidi! > 0) {
      _keyGlow[widget.listeningMidi!] = 1.0;
      added = true;
    }
    for (final k in _pressedKeys) {
      _keyGlow[k] = 1.0;
      added = true;
    }

    if (added) {
      _startGlowTicker();
    }
  }

  void _startGlowTicker() {
    _glowTicker ??= createTicker((elapsed) {
      if (!mounted) {
        _glowTicker?.stop();
        return;
      }
      if (widget.glowMode == PianoGlowMode.instant) {
        _glowTicker?.stop();
        return;
      }

      final dt = (_lastElapsed == Duration.zero)
          ? 0.016
          : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      // 根据真实硬件物理 VSYNC 帧间隔计算动态衰减量 (自适应 60Hz/90Hz/120Hz/144Hz)
      // fadeOut 模式标准衰减速度约 2.2 / 秒 (约 0.45 秒丝滑淡出)
      // trail 模式光轨衰减速度约 1.1 / 秒 (约 0.9 秒丝滑留痕)
      final decayRate = (widget.glowMode == PianoGlowMode.trail) ? 1.1 : 2.2;
      final step = (decayRate * dt).clamp(0.001, 0.2);

      bool hasChanges = false;
      bool hasActiveDecay = false;
      final keysToRemove = <int>[];

      final activeListening = widget.listeningMidi;
      for (final entry in _keyGlow.entries) {
        final midi = entry.key;
        if ((activeListening != null && activeListening == midi) || _pressedKeys.contains(midi)) {
          if (entry.value < 1.0) {
            _keyGlow[midi] = 1.0;
            hasChanges = true;
          }
        } else {
          hasActiveDecay = true;
          final nextVal = entry.value - step;
          if (nextVal <= 0.02) {
            keysToRemove.add(midi);
            hasChanges = true;
          } else {
            _keyGlow[midi] = nextVal;
            hasChanges = true;
          }
        }
      }

      for (final k in keysToRemove) {
        _keyGlow.remove(k);
      }

      if (!hasActiveDecay || _keyGlow.isEmpty) {
        _glowTicker?.stop();
        _lastElapsed = Duration.zero;
      }
      if (hasChanges) {
        setState(() {});
      }
    });

    if (!_glowTicker!.isTicking) {
      _lastElapsed = Duration.zero;
      _glowTicker!.start();
    }
  }

  double _getGlowIntensity(int midi, {required bool isListening, required bool isPressed, required bool isActive}) {
    if (widget.glowMode == PianoGlowMode.instant) {
      return (isListening || isPressed) ? 1.0 : (isActive ? 0.5 : 0.0);
    }
    final glow = _keyGlow[midi] ?? 0.0;
    if (isListening || isPressed) return 1.0;
    if (glow > 0.02) return glow;
    return isActive ? 0.35 : 0.0;
  }

  @override
  void dispose() {
    _glowTicker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMidi(int midi, {bool animated = true}) {
    if (!_scrollController.hasClients) return;
    int whiteKeyIndex = 0;
    for (int m = widget.minMidi; m < midi; m++) {
      if (!MusicTheory.isBlackKey(m)) {
        whiteKeyIndex++;
      }
    }
    final targetX = (whiteKeyIndex * whiteKeyWidth - 120.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animated) {
      _scrollController.animateTo(
        targetX,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetX);
    }
  }

  Rect _getMidiRect(int midi, Map<int, double> whiteKeyPositions, Map<int, double> blackKeyPositions) {
    if (MusicTheory.isBlackKey(midi)) {
      final left = blackKeyPositions[midi] ?? 0.0;
      return Rect.fromLTWH(left, 0, blackKeyWidth, 100);
    } else {
      final left = whiteKeyPositions[midi] ?? 0.0;
      return Rect.fromLTWH(left, 0, whiteKeyWidth, 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whiteKeys = <int>[];
    final blackKeysWithOffset = <_BlackKeyInfo>[];
    final whiteKeyPositions = <int, double>{};
    final blackKeyPositions = <int, double>{};

    double currentX = 0;
    for (int midi = widget.minMidi; midi <= widget.maxMidi; midi++) {
      if (!MusicTheory.isBlackKey(midi)) {
        whiteKeyPositions[midi] = currentX;
        whiteKeys.add(midi);
        currentX += whiteKeyWidth;
      } else {
        final left = currentX - (blackKeyWidth / 2);
        blackKeyPositions[midi] = left;
        blackKeysWithOffset.add(_BlackKeyInfo(midi: midi, leftOffset: left));
      }
    }

    final totalPianoWidth = whiteKeys.length * whiteKeyWidth;
    final visibleRanges = widget.ranges.where((r) => r.isVisible).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;
        const bracketBarHeight = 32.0;
        final blackSideRanges = visibleRanges.where((r) => r.indicatorPosition == RangeIndicatorPosition.blackKeySide).toList();
        final whiteSideRanges = visibleRanges.where((r) => r.indicatorPosition == RangeIndicatorPosition.whiteKeySide).toList();

        // 贪心图着色分轨：无重叠的音区共享同一排 (Lane 0)，仅在有实际范围冲突时自动分层换行
        final blackAllocation = RangeLaneAllocation.compute(blackSideRanges);
        final whiteAllocation = RangeLaneAllocation.compute(whiteSideRanges);

        // 动态计算音区栏预留高度：按实际需要的无重叠泳道数动态分配
        final topBracketH = blackSideRanges.isNotEmpty
            ? (widget.separateRangeTracks ? (blackAllocation.totalLanes * 26.0 + 4.0) : bracketBarHeight)
            : 2.0;
        final bottomBracketH = whiteSideRanges.isNotEmpty
            ? (widget.separateRangeTracks ? (whiteAllocation.totalLanes * 26.0 + 4.0) : bracketBarHeight)
            : 2.0;

        final hasSelection = widget.selectionStart != null && widget.selectionEnd != null;
        final handleRailHeight = hasSelection ? 34.0 : 0.0;

        // 琴键整体长度比例调节实装 (keyLengthRatio，支持 0.30x 超薄琴键模式)
        final keyHeight = ((availableH - topBracketH - bottomBracketH - handleRailHeight - 8) * widget.keyLengthRatio).clamp(35.0, 420.0);
        final blackHeight = keyHeight * 0.62;

        // 音区括号组件 (支持无重叠音区智能共享轨道排布及长按事件)
        Widget buildBracketBar(List<VocalRangeItem> targetRanges, RangeLaneAllocation allocation, {required bool isBlackSide}) {
          if (targetRanges.isEmpty) return const SizedBox(height: 2);
          final barH = widget.separateRangeTracks ? (allocation.totalLanes * 26.0 + 4.0) : bracketBarHeight;
          return SizedBox(
            height: barH,
            width: totalPianoWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: targetRanges.map((range) {
                final startRect = _getMidiRect(range.startMidi, whiteKeyPositions, blackKeyPositions);
                final endRect = _getMidiRect(range.endMidi, whiteKeyPositions, blackKeyPositions);

                final left = startRect.left;
                final right = endRect.right;
                final width = (right - left).clamp(24.0, totalPianoWidth);
                final isActive = widget.activeRange?.id == range.id;

                final trackIdx = widget.separateRangeTracks ? (allocation.rangeIdToLane[range.id] ?? 0) : 0;
                final itemTop = widget.separateRangeTracks ? (trackIdx * 26.0 + 2.0) : (isBlackSide ? 2.0 : 0.0);
                final itemHeight = widget.separateRangeTracks ? 22.0 : (bracketBarHeight - 4.0);

                return Positioned(
                  left: left,
                  top: itemTop,
                  width: width,
                  height: itemHeight,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onSelectRange != null) {
                        widget.onSelectRange!(range);
                      }
                    },
                    onLongPress: () {
                      if (widget.onLongPressRange != null) {
                        widget.onLongPressRange!(range);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: range.color.withValues(alpha: isActive ? 0.32 : 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: range.color.withValues(alpha: isActive ? 1.0 : 0.70),
                          width: isActive ? 2.0 : 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        range.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (10.5 * widget.scale).clamp(9.0, 13.0),
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                          color: isActive ? Colors.white : range.color,
                          shadows: isActive
                              ? [Shadow(color: range.color, blurRadius: 6)]
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }

        // 钢琴琴键主体组件
        Widget buildPianoBody() {
          return SizedBox(
            width: totalPianoWidth,
            height: keyHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. 白键行
                Row(
                  children: whiteKeys.map((midi) => _buildWhiteKey(midi, keyHeight)).toList(),
                ),

                // 2. 黑键列表
                ...blackKeysWithOffset.map(
                  (info) => _buildBlackKey(info.midi, info.leftOffset, blackKeyWidth, blackHeight),
                ),

                // 3. 顶层音区发光渗透层 (消除尾部空隙，严丝合缝完全贴合琴键两端，支持自定义Step与方向反转)
                ...visibleRanges.map((range) {
                  final startRect = _getMidiRect(range.startMidi, whiteKeyPositions, blackKeyPositions);
                  final endRect = _getMidiRect(range.endMidi, whiteKeyPositions, blackKeyPositions);
                  final left = startRect.left;
                  final right = endRect.right;
                  final width = (right - left).clamp(10.0, totalPianoWidth);

                  final isActive = widget.activeRange?.id == range.id;
                  final isRangeBlackSide = range.indicatorPosition == RangeIndicatorPosition.blackKeySide;

                  // 严丝合缝覆盖按键两端：top 与 bottom 均为 0
                  return Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _buildDynamicRangeGradient(range, isActive, isRangeBlackSide),
                          border: _buildRangeBorder(range, isActive, isRangeBlackSide),
                        ),
                      ),
                    ),
                  );
                }),

                // 4. 键盘实体选区高亮底色背景 (IgnorePointer 确保内部琴键点击正常弹奏)
                if (widget.selectionStart != null && widget.selectionEnd != null)
                  _buildSelectionBackground(keyHeight, whiteKeyPositions, blackKeyPositions),

                // 5. 键盘内部垂直金色参考导线 (纯细线，绝对不遮挡琴键上的音名)
                if (widget.selectionStart != null && widget.selectionEnd != null)
                  ..._buildSelectionGuides(keyHeight, whiteKeyPositions, blackKeyPositions),
              ],
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return RepaintBoundary(
          child: GestureDetector(
            onScaleStart: (_) => _baseScale = widget.scale,
            onScaleUpdate: (details) {
              if (widget.onScaleChanged != null && details.scale != 1.0) {
                final newScale = (_baseScale * details.scale).clamp(0.65, 1.85);
                widget.onScaleChanged!(newScale);
              }
            },
            child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C0E14) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFCBD5E0),
              ),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: _isDraggingAnyHandle ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              child: SizedBox(
                key: _contentKey,
                width: totalPianoWidth,
                height: availableH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (blackSideRanges.isNotEmpty) buildBracketBar(blackSideRanges, blackAllocation, isBlackSide: true),
                    const SizedBox(height: 2),
                    buildPianoBody(),
                    // 独立选区推子把手导轨栏 (离开琴键表面，位于白键音名下方，绝对不遮挡琴键音名)
                    if (hasSelection) ...[
                      const SizedBox(height: 3),
                      buildSelectionHandleRail(handleRailHeight, whiteKeyPositions, blackKeyPositions),
                    ],
                    const SizedBox(height: 2),
                    if (whiteSideRanges.isNotEmpty) buildBracketBar(whiteSideRanges, whiteAllocation, isBlackSide: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildWhiteKey(int midi, double height) {
    final isPressed = _pressedKeys.contains(midi);
    final isListening = widget.listeningMidi == midi;
    final isActive = isListening || widget.activeMidi == midi;
    final glow = _getGlowIntensity(midi, isListening: isListening, isPressed: isPressed, isActive: isActive);
    final isGlowing = glow > 0.05;
    final noteInfo = MusicTheory.getFormattedNote(
      midi,
      preferSharp: widget.preferSharp,
      octaveNotation: widget.octaveNotation,
    );
    final isC = noteInfo.baseNote == 'C' && noteInfo.accidental.isEmpty;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressedKeys.add(midi);
          if (widget.glowMode != PianoGlowMode.instant) {
            _keyGlow[midi] = 1.0;
            _startGlowTicker();
          }
        });
        widget.onKeyPressed(midi);
      },
      onTapUp: (_) {
        setState(() {
          _pressedKeys.remove(midi);
          if (widget.glowMode != PianoGlowMode.instant) _startGlowTicker();
        });
        widget.onKeyReleased(midi);
      },
      onTapCancel: () {
        setState(() {
          _pressedKeys.remove(midi);
          if (widget.glowMode != PianoGlowMode.instant) _startGlowTicker();
        });
        widget.onKeyReleased(midi);
      },
      child: Container(
        width: whiteKeyWidth,
        height: height,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(5),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isGlowing
                ? [
                    const Color(0xFF00E676).withValues(alpha: (0.85 * glow).clamp(0.0, 1.0)),
                    const Color(0xFF00E5FF).withValues(alpha: (0.45 * glow).clamp(0.0, 1.0)),
                  ]
                : isPressed
                    ? [const Color(0xFF00E5FF).withValues(alpha: 0.6), const Color(0xFF00E5FF).withValues(alpha: 0.25)]
                    : isActive
                        ? [const Color(0xFF00E5FF).withValues(alpha: 0.35), Colors.white]
                        : [const Color(0xFFEDEDED), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: isGlowing
                  ? const Color(0xFF00E676).withValues(alpha: (0.45 * glow).clamp(0.0, 1.0))
                  : Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 3),
              blurRadius: isGlowing ? (3.0 + 4.0 * glow) : 3.0,
            ),
          ],
          border: Border.all(
            color: isGlowing
                ? Color.lerp(const Color(0xFF00E5FF), const Color(0xFF00E676), glow)!
                : (isActive ? const Color(0xFF00E5FF) : Colors.black26),
            width: isGlowing ? (1.2 + 0.8 * glow) : (isActive ? 1.5 : 0.8),
          ),
        ),
        child: (height >= 22.0)
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5.0, left: 1.0, right: 1.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isC
                        ? Text(
                            noteInfo.scriptNotation,
                            style: TextStyle(
                              fontSize: (11.5 * widget.scale).clamp(9.5, 14.5),
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF2A6D), // 绯红色，无底通透
                            ),
                          )
                        : Text(
                            noteInfo.displayName,
                            style: TextStyle(
                              fontSize: (9.5 * widget.scale).clamp(8.0, 12.0),
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBlackKey(int midi, double left, double width, double height) {
    final isPressed = _pressedKeys.contains(midi);
    final isListening = widget.listeningMidi == midi;
    final isActive = isListening || widget.activeMidi == midi;
    final glow = _getGlowIntensity(midi, isListening: isListening, isPressed: isPressed, isActive: isActive);
    final isGlowing = glow > 0.05;
    final noteInfo = MusicTheory.getFormattedNote(
      midi,
      preferSharp: widget.preferSharp,
      octaveNotation: widget.octaveNotation,
    );
    final keyLabelColor = (isGlowing || isActive) ? Colors.white : Colors.white70;

    return Positioned(
      left: left,
      top: 0,
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressedKeys.add(midi);
            if (widget.glowMode != PianoGlowMode.instant) {
              _keyGlow[midi] = 1.0;
              _startGlowTicker();
            }
          });
          widget.onKeyPressed(midi);
        },
        onTapUp: (_) {
          setState(() {
            _pressedKeys.remove(midi);
            if (widget.glowMode != PianoGlowMode.instant) _startGlowTicker();
          });
          widget.onKeyReleased(midi);
        },
        onTapCancel: () {
          setState(() {
            _pressedKeys.remove(midi);
            if (widget.glowMode != PianoGlowMode.instant) _startGlowTicker();
          });
          widget.onKeyReleased(midi);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isGlowing
                  ? [
                      Color.lerp(const Color(0xFF282C38), const Color(0xFF00E676), glow)!,
                      Color.lerp(const Color(0xFF101218), const Color(0xFF00B0FF), glow)!,
                    ]
                  : isPressed
                      ? [const Color(0xFF00E5FF), const Color(0xFF0091EA)]
                      : isActive
                          ? [const Color(0xFF00E5FF).withValues(alpha: 0.8), const Color(0xFF1E212B)]
                          : [const Color(0xFF282C38), const Color(0xFF101218)],
            ),
            boxShadow: [
              BoxShadow(
                color: isGlowing
                    ? const Color(0xFF00E676).withValues(alpha: (0.5 * glow).clamp(0.0, 1.0))
                    : Colors.black.withValues(alpha: 0.6),
                offset: const Offset(1, 4),
                blurRadius: isGlowing ? (4.0 + 3.0 * glow) : 4.0,
              ),
            ],
            border: Border.all(
              color: isGlowing
                  ? Color.lerp(Colors.black87, const Color(0xFF00E676), glow)!
                  : (isActive ? const Color(0xFF00E5FF) : Colors.black87),
              width: isGlowing ? (1.0 + 1.0 * glow) : (isActive ? 1.5 : 1.0),
            ),
          ),
          child: (width >= 10.0 && height >= 20.0)
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0, left: 1.0, right: 1.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            noteInfo.baseNote,
                            style: TextStyle(
                              fontSize: (9.0 * widget.scale).clamp(7.5, 11.0),
                              fontWeight: FontWeight.bold,
                              color: keyLabelColor,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            noteInfo.accidental,
                            style: TextStyle(
                              fontSize: (8.0 * widget.scale).clamp(6.5, 9.5),
                              fontWeight: FontWeight.bold,
                              color: keyLabelColor, // 与音高字母统一步调为相同的颜色
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  int _findClosestMidiAtX(double x, Map<int, double> whitePositions, Map<int, double> blackPositions) {
    int bestMidi = widget.minMidi;
    double minDistance = double.infinity;
    for (int m = widget.minMidi; m <= widget.maxMidi; m++) {
      final centerX = MusicTheory.isBlackKey(m)
          ? (blackPositions[m] ?? 0.0) + (blackKeyWidth / 2)
          : (whitePositions[m] ?? 0.0) + (whiteKeyWidth / 2);
      final dist = (centerX - x).abs();
      if (dist < minDistance) {
        minDistance = dist;
        bestMidi = m;
      }
    }
    return bestMidi.clamp(widget.minMidi, widget.maxMidi);
  }

  void _updateSelectionStart(Offset globalPos, Map<int, double> whitePositions, Map<int, double> blackPositions, int end) {
    if (widget.onSelectionRangeChanged == null) return;
    final renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPoint = renderBox.globalToLocal(globalPos);
      final newMidi = _findClosestMidiAtX(localPoint.dx, whitePositions, blackPositions);
      final clampedMidi = newMidi.clamp(widget.minMidi, end);
      if (clampedMidi != widget.selectionStart) {
        widget.onSelectionRangeChanged!(clampedMidi, end);
        widget.onKeyPressed(clampedMidi);
      }
    }
  }

  void _updateSelectionEnd(Offset globalPos, Map<int, double> whitePositions, Map<int, double> blackPositions, int start) {
    if (widget.onSelectionRangeChanged == null) return;
    final renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPoint = renderBox.globalToLocal(globalPos);
      final newMidi = _findClosestMidiAtX(localPoint.dx, whitePositions, blackPositions);
      final clampedMidi = newMidi.clamp(start, widget.maxMidi);
      if (clampedMidi != widget.selectionEnd) {
        widget.onSelectionRangeChanged!(start, clampedMidi);
        widget.onKeyPressed(clampedMidi);
      }
    }
  }

  LinearGradient _buildDynamicRangeGradient(
    VocalRangeItem range,
    bool isActive,
    bool isRangeBlackSide,
  ) {
    final isReversed = range.gradientReversed;

    // 方向判断：
    // 黑键侧常规：从 top 向 bottom 渐变衰减；反向：从 bottom 向 top 渐变衰减
    // 白键侧常规：从 bottom 向 top 渐变衰减；反向：从 top 向 bottom 渐变衰减
    Alignment begin;
    Alignment end;
    if (isRangeBlackSide) {
      begin = isReversed ? Alignment.bottomCenter : Alignment.topCenter;
      end = isReversed ? Alignment.topCenter : Alignment.bottomCenter;
    } else {
      begin = isReversed ? Alignment.topCenter : Alignment.bottomCenter;
      end = isReversed ? Alignment.bottomCenter : Alignment.topCenter;
    }

    final double activeMultiplier = isActive ? 1.0 : 0.82;
    final double startA = (range.startOpacity * activeMultiplier).clamp(0.12, 1.0);
    final double endA = (range.endOpacity * activeMultiplier).clamp(0.0, 0.50);

    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        range.color.withValues(alpha: startA),
        range.color.withValues(alpha: (startA * 0.55 + endA * 0.45).clamp(0.0, 1.0)),
        range.color.withValues(alpha: (startA * 0.20 + endA * 0.80).clamp(0.0, 1.0)),
        range.color.withValues(alpha: endA),
      ],
      stops: const [0.0, 0.32, 0.72, 1.0],
    );
  }

  Border _buildRangeBorder(
    VocalRangeItem range,
    bool isActive,
    bool isRangeBlackSide,
  ) {
    final isReversed = range.gradientReversed;
    final side = BorderSide(
      color: range.color.withValues(alpha: isActive ? 1.0 : 0.75),
      width: 2.0,
    );

    // 发光边框线始终位于渐变起始强光端
    final isTopActive = (isRangeBlackSide && !isReversed) || (!isRangeBlackSide && isReversed);
    return Border(
      top: isTopActive ? side : BorderSide.none,
      bottom: !isTopActive ? side : BorderSide.none,
    );
  }

  Widget _buildSelectionBackground(
    double keyHeight,
    Map<int, double> whitePositions,
    Map<int, double> blackPositions,
  ) {
    final startMidi = widget.selectionStart!;
    final endMidi = widget.selectionEnd!;
    final start = startMidi < endMidi ? startMidi : endMidi;
    final end = startMidi > endMidi ? startMidi : endMidi;

    final startRect = _getMidiRect(start, whitePositions, blackPositions);
    final endRect = _getMidiRect(end, whitePositions, blackPositions);

    final left = startRect.left;
    final right = endRect.right;
    final width = (right - left).clamp(16.0, 5000.0);

    return Positioned(
      left: left,
      top: 0,
      width: width,
      height: keyHeight,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.8), width: 1.5),
          ),
        ),
      ),
    );
  }

  /// 琴键内部垂直参考导线 (纯细线，绝对不遮挡琴键表面的音名)
  List<Widget> _buildSelectionGuides(
    double keyHeight,
    Map<int, double> whitePositions,
    Map<int, double> blackPositions,
  ) {
    final startMidi = widget.selectionStart!;
    final endMidi = widget.selectionEnd!;
    final start = startMidi < endMidi ? startMidi : endMidi;
    final end = startMidi > endMidi ? startMidi : endMidi;

    final startRect = _getMidiRect(start, whitePositions, blackPositions);
    final endRect = _getMidiRect(end, whitePositions, blackPositions);

    return [
      // 起始音左边界细线
      Positioned(
        left: startRect.left - 1.0,
        top: 0,
        bottom: 0,
        width: 2.5,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFB300).withValues(alpha: 0.8), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
      // 终止音右边界细线
      Positioned(
        left: endRect.right - 1.5,
        top: 0,
        bottom: 0,
        width: 2.5,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFB300).withValues(alpha: 0.8), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  /// 琴键下方专属选区把手滑动导轨槽 (离开琴键表面，位于白键音名下方，绝对不挡琴键音名)
  Widget buildSelectionHandleRail(
    double railHeight,
    Map<int, double> whitePositions,
    Map<int, double> blackPositions,
  ) {
    final startMidi = widget.selectionStart!;
    final endMidi = widget.selectionEnd!;
    final start = startMidi < endMidi ? startMidi : endMidi;
    final end = startMidi > endMidi ? startMidi : endMidi;

    final startRect = _getMidiRect(start, whitePositions, blackPositions);
    final endRect = _getMidiRect(end, whitePositions, blackPositions);

    final left = startRect.left;
    final right = endRect.right;

    final startNote = MusicTheory.getFormattedNote(start, preferSharp: widget.preferSharp, octaveNotation: widget.octaveNotation);
    final endNote = MusicTheory.getFormattedNote(end, preferSharp: widget.preferSharp, octaveNotation: widget.octaveNotation);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: railHeight,
      width: whitePositions.length * whiteKeyWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 全宽水平导轨刻度凹槽
          Positioned(
            left: 0,
            right: 0,
            top: 15,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2230) : const Color(0xFFCBD5E0),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),

          // 2. 选区范围跨度高亮连线
          Positioned(
            left: left,
            width: (right - left).clamp(4.0, double.infinity),
            top: 14.5,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),

          // 3. 起始音调节把手推子 (位于导轨栏内，指针直指琴键边界，内嵌音名)
          Positioned(
            left: left - 28,
            top: 0,
            width: 56,
            height: railHeight,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                setState(() => _isDraggingLeftHandle = true);
                _updateSelectionStart(event.position, whitePositions, blackPositions, end);
              },
              onPointerMove: (event) {
                _updateSelectionStart(event.position, whitePositions, blackPositions, end);
              },
              onPointerUp: (_) {
                if (_isDraggingLeftHandle) setState(() => _isDraggingLeftHandle = false);
              },
              onPointerCancel: (_) {
                if (_isDraggingLeftHandle) setState(() => _isDraggingLeftHandle = false);
              },
              child: _buildHandleSliderPill(startNote.displayName),
            ),
          ),

          // 4. 终止音调节把手推子 (位于导轨栏内，指针直指琴键边界，内嵌音名)
          Positioned(
            left: right - 28,
            top: 0,
            width: 56,
            height: railHeight,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                setState(() => _isDraggingRightHandle = true);
                _updateSelectionEnd(event.position, whitePositions, blackPositions, start);
              },
              onPointerMove: (event) {
                _updateSelectionEnd(event.position, whitePositions, blackPositions, start);
              },
              onPointerUp: (_) {
                if (_isDraggingRightHandle) setState(() => _isDraggingRightHandle = false);
              },
              onPointerCancel: (_) {
                if (_isDraggingRightHandle) setState(() => _isDraggingRightHandle = false);
              },
              child: _buildHandleSliderPill(endNote.displayName),
            ),
          ),
        ],
      ),
    );
  }

  /// 硬件质感专业推子视觉抓手：顶部向上微型三角指标直指琴键，中间显示清晰音名 (带防溢出自适应)
  Widget _buildHandleSliderPill(String noteLabel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 向上微型指针
        const Icon(
          Icons.arrow_drop_up_rounded,
          size: 14,
          color: Color(0xFFFFB300),
        ),
        // 推子抓手本体 (内嵌音名，紧凑高辨识，带 FittedBox 杜绝溢出)
        Container(
          height: 19,
          constraints: const BoxConstraints(maxWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFFFB300), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
              const BoxShadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.drag_indicator_rounded, size: 10, color: Color(0xFFFFB300)),
                  const SizedBox(width: 2),
                  Text(
                    noteLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFB300),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
