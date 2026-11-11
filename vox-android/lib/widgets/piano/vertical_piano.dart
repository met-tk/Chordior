import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/music_theory.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

class _VerticalBlackKeyInfo {
  final int midi;
  final double topOffset;
  const _VerticalBlackKeyInfo({required this.midi, required this.topOffset});
}

/// 竖排立式声学钢琴键盘组件
/// 严格遵循“水平键盘向左逆时针旋转 90 度”的真实几何声学形态：
/// 1. 高音在上方 (Top)，低音在下方 (Bottom)
/// 2. 黑键位于左侧 (黑键根部在最左端 left: 0，向右伸展)
/// 3. 白键向右侧伸展 (弹奏端位于右端，带圆角与音名标注)
/// 4. 音区括号默认置于左侧 (靠近黑键一侧)，可切换至右侧 (靠近白键一侧)
/// 5. 音区发光渐变层置于黑白键顶层，同时浸透黑键与白键，无杂乱圆点
/// 6. 支持琴键渐变褪色余晖与多音留痕光轨动效 (PianoGlowMode)
class VerticalPianoWidget extends StatefulWidget {
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

  const VerticalPianoWidget({
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
  State<VerticalPianoWidget> createState() => _VerticalPianoWidgetState();
}

class _VerticalPianoWidgetState extends State<VerticalPianoWidget> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();
  final Set<int> _pressedKeys = {};

  // 琴键动态发光衰减表: midi -> intensity (0.0 ~ 1.0)
  final Map<int, double> _keyGlow = {};
  Ticker? _glowTicker;
  Duration _lastElapsed = Duration.zero;

  bool _isDraggingTopHandle = false;
  bool _isDraggingBottomHandle = false;
  bool get _isDraggingAnyHandle => _isDraggingTopHandle || _isDraggingBottomHandle;

  double get whiteKeyHeight => 36.0 * widget.scale;
  double get blackKeyHeight => 24.0 * widget.scale;
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
  void didUpdateWidget(covariant VerticalPianoWidget oldWidget) {
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
    // 从上到下高音到低音：maxMidi 在顶部，越大的音在越上面
    double yOffset = 0;
    for (int m = widget.maxMidi; m > midi; m--) {
      if (!MusicTheory.isBlackKey(m)) {
        yOffset += whiteKeyHeight;
      }
    }
    final targetY = (yOffset - 100.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animated) {
      _scrollController.animateTo(
        targetY,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetY);
    }
  }

  /// 获取指定 MIDI 音符的垂直像素区间 [top, bottom]
  Rect _getMidiVerticalRect(int midi, Map<int, double> whiteKeyTops, Map<int, double> blackKeyTops) {
    if (MusicTheory.isBlackKey(midi)) {
      final top = blackKeyTops[midi] ?? 0.0;
      return Rect.fromLTWH(0, top, 100, blackKeyHeight);
    } else {
      final top = whiteKeyTops[midi] ?? 0.0;
      return Rect.fromLTWH(0, top, 100, whiteKeyHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whiteKeys = <int>[];
    final blackKeysWithOffset = <_VerticalBlackKeyInfo>[];
    final whiteKeyTops = <int, double>{};
    final blackKeyTops = <int, double>{};

    // 严格从高音到低音排列 (从 maxMidi 降序到 minMidi，高音在上、低音在下)
    double currentY = 0;
    for (int midi = widget.maxMidi; midi >= widget.minMidi; midi--) {
      if (!MusicTheory.isBlackKey(midi)) {
        whiteKeyTops[midi] = currentY;
        whiteKeys.add(midi);
        currentY += whiteKeyHeight;
      } else {
        // 黑键垂直横跨在两相邻白键之间的缝隙上
        final top = currentY - (blackKeyHeight / 2);
        blackKeyTops[midi] = top;
        blackKeysWithOffset.add(_VerticalBlackKeyInfo(midi: midi, topOffset: top));
      }
    }

    final totalHeight = whiteKeys.length * whiteKeyHeight;
    final visibleRanges = widget.ranges.where((r) => r.isVisible).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // 音区括号栏宽度固定为 46px
        const bracketColWidth = 46.0;

        final blackSideRanges = visibleRanges.where((r) => r.indicatorPosition == RangeIndicatorPosition.blackKeySide).toList();
        final whiteSideRanges = visibleRanges.where((r) => r.indicatorPosition == RangeIndicatorPosition.whiteKeySide).toList();

        // 贪心图着色分轨：无重叠音区共享同一列 (Lane 0)，仅在冲突时分层
        final blackAllocation = RangeLaneAllocation.compute(blackSideRanges);
        final whiteAllocation = RangeLaneAllocation.compute(whiteSideRanges);

        final leftBracketW = blackSideRanges.isNotEmpty
            ? (widget.separateRangeTracks ? (blackAllocation.totalLanes * 36.0 + 4.0) : bracketColWidth)
            : 0.0;
        final rightBracketW = whiteSideRanges.isNotEmpty
            ? (widget.separateRangeTracks ? (whiteAllocation.totalLanes * 36.0 + 4.0) : bracketColWidth)
            : 0.0;

        final hasSelection = widget.selectionStart != null && widget.selectionEnd != null;
        final handleRailWidth = hasSelection ? 34.0 : 0.0;

        // 根据 keyLengthRatio 计算白键整体宽度与黑键宽度 (下限放宽至 40.0，支持超扁琴键)
        final basePianoWidth = (totalWidth - leftBracketW - rightBracketW - handleRailWidth - 6).clamp(50.0, 520.0);
        final pianoWidth = (basePianoWidth * widget.keyLengthRatio).clamp(40.0, totalWidth - leftBracketW - rightBracketW - handleRailWidth - 6);
        final blackKeyWidth = pianoWidth * 0.60;

        // 音区跨度垂直括号栏组件 (支持无重叠音区共享轨道排布与长按事件)
        Widget buildVerticalBracketBar(List<VocalRangeItem> targetRanges, RangeLaneAllocation allocation, {required bool isBlackSide}) {
          if (targetRanges.isEmpty) return const SizedBox.shrink();
          final colW = widget.separateRangeTracks ? (allocation.totalLanes * 36.0 + 4.0) : bracketColWidth;
          return SizedBox(
            width: colW,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: targetRanges.map((range) {
                final highRect = _getMidiVerticalRect(range.endMidi, whiteKeyTops, blackKeyTops);
                final lowRect = _getMidiVerticalRect(range.startMidi, whiteKeyTops, blackKeyTops);
                final top = highRect.top;
                final bottom = lowRect.bottom;
                final height = (bottom - top).clamp(24.0, totalHeight);

                final isActive = widget.activeRange?.id == range.id;
                final trackIdx = widget.separateRangeTracks ? (allocation.rangeIdToLane[range.id] ?? 0) : 0;
                final itemLeft = widget.separateRangeTracks
                    ? (trackIdx * 36.0 + 2.0)
                    : (isBlackSide ? 2.0 : 0.0);
                final itemWidth = widget.separateRangeTracks ? 32.0 : (bracketColWidth - 4.0);

                return Positioned(
                  top: top,
                  left: itemLeft,
                  width: itemWidth,
                  height: height,
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
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: range.color.withValues(alpha: isActive ? 0.32 : 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: range.color.withValues(alpha: isActive ? 1.0 : 0.70),
                          width: isActive ? 2.0 : 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: range.name.split('').map((char) {
                          return Text(
                            char,
                            style: TextStyle(
                              fontSize: (10.5 * widget.scale).clamp(8.5, 12.5),
                              fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                              color: isActive ? Colors.white : range.color,
                              height: 1.15,
                              shadows: isActive
                                  ? [Shadow(color: range.color, blurRadius: 6)]
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }

        // 钢琴主体组件 (黑键在左、白键在右)
        Widget buildVerticalPianoBody() {
          return SizedBox(
            width: pianoWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. 白键列表 (由上至下高音到低音，右侧展开)
                Column(
                  children: whiteKeys.map((m) => _buildWhiteKeyRow(m, pianoWidth)).toList(),
                ),

                // 2. 黑键列表 (水平向左旋转90度后：黑键位于最左侧 left: 0，向右伸展！)
                ...blackKeysWithOffset.map(
                  (info) => _buildBlackKeyBox(info.midi, info.topOffset, blackKeyWidth),
                ),

                // 3. 顶层音区色彩渐变发光渗透层 (消除缝隙，支持自定义Step与方向反转)
                ...visibleRanges.map((range) {
                  final highRect = _getMidiVerticalRect(range.endMidi, whiteKeyTops, blackKeyTops);
                  final lowRect = _getMidiVerticalRect(range.startMidi, whiteKeyTops, blackKeyTops);
                  final top = highRect.top;
                  final bottom = lowRect.bottom;
                  final height = (bottom - top).clamp(10.0, totalHeight);

                  final isActive = widget.activeRange?.id == range.id;
                  final isRangeBlackSide = range.indicatorPosition == RangeIndicatorPosition.blackKeySide;

                  // 消除 4px 缝隙：left 和 right 严格为 0，完全覆盖按键琴键方向区域
                  return Positioned(
                    top: top,
                    height: height,
                    left: 0,
                    right: 0,
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
                  _buildSelectionBackground(pianoWidth, whiteKeyTops, blackKeyTops),

                // 5. 键盘内部水平金色参考导线 (纯细线，绝对不遮挡琴键上的音名)
                if (widget.selectionStart != null && widget.selectionEnd != null)
                  ..._buildVerticalSelectionGuides(pianoWidth, whiteKeyTops, blackKeyTops),
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
                scrollDirection: Axis.vertical,
                physics: _isDraggingAnyHandle ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                child: SizedBox(
                  key: _contentKey,
                  width: totalWidth,
                  height: totalHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (blackSideRanges.isNotEmpty) ...[
                        buildVerticalBracketBar(blackSideRanges, blackAllocation, isBlackSide: true),
                        const SizedBox(width: 2),
                      ],
                      buildVerticalPianoBody(),
                      // 独立纵向选区推子滑槽栏 (完全离开琴键表面，位于白键音名右侧，绝对不遮挡琴键音名)
                      if (hasSelection) ...[
                        const SizedBox(width: 3),
                        buildVerticalSelectionHandleRail(handleRailWidth, whiteKeyTops, blackKeyTops),
                      ],
                      if (whiteSideRanges.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        buildVerticalBracketBar(whiteSideRanges, whiteAllocation, isBlackSide: false),
                      ],
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

  /// 竖排白键行：左侧是根部，向右延伸，右端是手指弹奏端（圆角与音名）
  Widget _buildWhiteKeyRow(int midi, double width) {
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
        width: width,
        height: whiteKeyHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(5),
            bottomRight: Radius.circular(5),
          ),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isGlowing
                ? [
                    const Color(0xFF00E676).withValues(alpha: (0.85 * glow).clamp(0.0, 1.0)),
                    const Color(0xFF00E5FF).withValues(alpha: (0.45 * glow).clamp(0.0, 1.0)),
                  ]
                : isPressed
                    ? [const Color(0xFF00E5FF).withValues(alpha: 0.6), const Color(0xFF00E5FF).withValues(alpha: 0.25)]
                    : isActive
                        ? [const Color(0xFF00E5FF).withValues(alpha: 0.35), Colors.white]
                        : [const Color(0xFFE8ECEF), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: isGlowing
                  ? const Color(0xFF00E676).withValues(alpha: (0.45 * glow).clamp(0.0, 1.0))
                  : Colors.black.withValues(alpha: 0.35),
              offset: const Offset(2, 0),
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
        child: (width >= 24.0)
            ? Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 1.0, bottom: 1.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isC
                        ? Text(
                            noteInfo.scriptNotation,
                            style: TextStyle(
                              fontSize: (11.0 * widget.scale).clamp(9.0, 14.0),
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF2A6D),
                              height: 1.0,
                            ),
                          )
                        : Text(
                            noteInfo.displayName,
                            style: TextStyle(
                              fontSize: (9.5 * widget.scale).clamp(8.0, 12.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// 竖排黑键：向左旋转90度后，黑键位于左侧 (left: 0)，向右延展
  Widget _buildBlackKeyBox(int midi, double topOffset, double blackWidth) {
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

    return Positioned(
      left: 0,
      top: topOffset,
      width: blackWidth,
      height: blackKeyHeight,
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
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
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
                offset: const Offset(3, 2),
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
          child: (blackWidth >= 16.0 && blackKeyHeight >= 10.0)
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0, top: 1.0, bottom: 1.0),
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
                              color: isActive ? Colors.white : Colors.white70,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            noteInfo.accidental,
                            style: TextStyle(
                              fontSize: (9.0 * widget.scale).clamp(7.5, 11.0),
                              fontWeight: FontWeight.w900,
                              color: isActive ? Colors.white : Colors.white70,
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

  int _findClosestMidiAtY(double y, Map<int, double> whiteKeyTops, Map<int, double> blackKeyTops) {
    int bestMidi = widget.minMidi;
    double minDistance = double.infinity;
    for (int m = widget.minMidi; m <= widget.maxMidi; m++) {
      final centerY = MusicTheory.isBlackKey(m)
          ? (blackKeyTops[m] ?? 0.0) + (blackKeyHeight / 2)
          : (whiteKeyTops[m] ?? 0.0) + (whiteKeyHeight / 2);
      final dist = (centerY - y).abs();
      if (dist < minDistance) {
        minDistance = dist;
        bestMidi = m;
      }
    }
    return bestMidi.clamp(widget.minMidi, widget.maxMidi);
  }

  void _updateSelectionHigh(Offset globalPos, Map<int, double> whiteKeyTops, Map<int, double> blackKeyTops, int lowMidi) {
    if (widget.onSelectionRangeChanged == null) return;
    final renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localInContent = renderBox.globalToLocal(globalPos);
    final contentY = localInContent.dy;
    final newMidi = _findClosestMidiAtY(contentY, whiteKeyTops, blackKeyTops);
    final clampedMidi = newMidi.clamp(lowMidi, widget.maxMidi);
    final currentHigh = widget.selectionStart! > widget.selectionEnd! ? widget.selectionStart! : widget.selectionEnd!;
    if (clampedMidi != currentHigh) {
      widget.onSelectionRangeChanged!(lowMidi, clampedMidi);
      widget.onKeyPressed(clampedMidi);
    }
  }

  void _updateSelectionLow(Offset globalPos, Map<int, double> whiteKeyTops, Map<int, double> blackKeyTops, int highMidi) {
    if (widget.onSelectionRangeChanged == null) return;
    final renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localInContent = renderBox.globalToLocal(globalPos);
    final contentY = localInContent.dy;
    final newMidi = _findClosestMidiAtY(contentY, whiteKeyTops, blackKeyTops);
    final clampedMidi = newMidi.clamp(widget.minMidi, highMidi);
    final currentLow = widget.selectionStart! < widget.selectionEnd! ? widget.selectionStart! : widget.selectionEnd!;
    if (clampedMidi != currentLow) {
      widget.onSelectionRangeChanged!(clampedMidi, highMidi);
      widget.onKeyPressed(clampedMidi);
    }
  }

  LinearGradient _buildDynamicRangeGradient(
    VocalRangeItem range,
    bool isActive,
    bool isRangeBlackSide,
  ) {
    final isReversed = range.gradientReversed;

    // 方向判断：
    // 黑键在左侧(left: 0)，白键在右侧
    // 黑键侧常规：从 left 向 right 渐变衰减；反向：从 right 向 left 渐变衰减
    // 白键侧常规：从 right 向 left 渐变衰减；反向：从 left 向 right 渐变衰减
    Alignment begin;
    Alignment end;
    if (isRangeBlackSide) {
      begin = isReversed ? Alignment.centerRight : Alignment.centerLeft;
      end = isReversed ? Alignment.centerLeft : Alignment.centerRight;
    } else {
      begin = isReversed ? Alignment.centerLeft : Alignment.centerRight;
      end = isReversed ? Alignment.centerRight : Alignment.centerLeft;
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

    final isLeftActive = (isRangeBlackSide && !isReversed) || (!isRangeBlackSide && isReversed);
    return Border(
      left: isLeftActive ? side : BorderSide.none,
      right: !isLeftActive ? side : BorderSide.none,
    );
  }

  Widget _buildSelectionBackground(
    double pianoWidth,
    Map<int, double> whiteKeyTops,
    Map<int, double> blackKeyTops,
  ) {
    final startMidi = widget.selectionStart!;
    final endMidi = widget.selectionEnd!;
    final lowMidi = startMidi < endMidi ? startMidi : endMidi;
    final highMidi = startMidi > endMidi ? startMidi : endMidi;

    final highRect = _getMidiVerticalRect(highMidi, whiteKeyTops, blackKeyTops);
    final lowRect = _getMidiVerticalRect(lowMidi, whiteKeyTops, blackKeyTops);
    final top = highRect.top;
    final bottom = lowRect.bottom;
    final height = (bottom - top).clamp(16.0, 5000.0);

    return Positioned(
      left: 0,
      width: pianoWidth,
      top: top,
      height: height,
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

  /// 琴键内部水平参考导线 (纯细线，绝对不遮挡琴键表面的音名)
  List<Widget> _buildVerticalSelectionGuides(
    double pianoWidth,
    Map<int, double> whiteKeyTops,
    Map<int, double> blackKeyTops,
  ) {
    final startMidi = widget.selectionStart!;
    final endMidi = widget.selectionEnd!;
    final lowMidi = startMidi < endMidi ? startMidi : endMidi;
    final highMidi = startMidi > endMidi ? startMidi : endMidi;

    final highRect = _getMidiVerticalRect(highMidi, whiteKeyTops, blackKeyTops);
    final lowRect = _getMidiVerticalRect(lowMidi, whiteKeyTops, blackKeyTops);

    return [
      // 最高音上边界细线
      Positioned(
        left: 0,
        right: 0,
        top: highRect.top - 1.0,
        height: 2.5,
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
      // 最低音下边界细线
      Positioned(
        left: 0,
        right: 0,
        top: lowRect.bottom - 1.5,
        height: 2.5,
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

  /// 琴键右侧专属独立把手纵向导轨滑槽 (离开琴键表面，位于白键音名右侧，绝对不挡琴键音名)
  Widget buildVerticalSelectionHandleRail(
    double railWidth,
    Map<int, double> whiteKeyTops,
    Map<int, double> blackKeyTops,
  ) {
    final startMidi = widget.selectionStart!;
    final endMidi = widget.selectionEnd!;
    final lowMidi = startMidi < endMidi ? startMidi : endMidi;
    final highMidi = startMidi > endMidi ? startMidi : endMidi;

    final highRect = _getMidiVerticalRect(highMidi, whiteKeyTops, blackKeyTops);
    final lowRect = _getMidiVerticalRect(lowMidi, whiteKeyTops, blackKeyTops);

    final top = highRect.top;
    final bottom = lowRect.bottom;

    final highNote = MusicTheory.getFormattedNote(highMidi, preferSharp: widget.preferSharp, octaveNotation: widget.octaveNotation);
    final lowNote = MusicTheory.getFormattedNote(lowMidi, preferSharp: widget.preferSharp, octaveNotation: widget.octaveNotation);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: railWidth,
      height: whiteKeyTops.length * whiteKeyHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 全长垂直标尺导轨凹槽
          Positioned(
            left: 15,
            top: 0,
            bottom: 0,
            width: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2230) : const Color(0xFFCBD5E0),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),

          // 2. 选区跨度垂直高亮连线
          Positioned(
            left: 14.5,
            top: top,
            height: (bottom - top).clamp(4.0, double.infinity),
            width: 4,
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

          // 3. 上把手 (高音调节推子：位于右侧滑槽内，向左三角指针直指琴键分界)
          Positioned(
            left: 0,
            top: top - 24,
            width: railWidth,
            height: 48,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                setState(() => _isDraggingTopHandle = true);
                _updateSelectionHigh(event.position, whiteKeyTops, blackKeyTops, lowMidi);
              },
              onPointerMove: (event) {
                _updateSelectionHigh(event.position, whiteKeyTops, blackKeyTops, lowMidi);
              },
              onPointerUp: (_) {
                if (_isDraggingTopHandle) setState(() => _isDraggingTopHandle = false);
              },
              onPointerCancel: (_) {
                if (_isDraggingTopHandle) setState(() => _isDraggingTopHandle = false);
              },
              child: _buildVerticalHandleSliderPill(highNote.displayName),
            ),
          ),

          // 4. 下把手 (低音调节推子：位于右侧滑槽内，向左三角指针直指琴键分界)
          Positioned(
            left: 0,
            top: bottom - 24,
            width: railWidth,
            height: 48,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                setState(() => _isDraggingBottomHandle = true);
                _updateSelectionLow(event.position, whiteKeyTops, blackKeyTops, highMidi);
              },
              onPointerMove: (event) {
                _updateSelectionLow(event.position, whiteKeyTops, blackKeyTops, highMidi);
              },
              onPointerUp: (_) {
                if (_isDraggingBottomHandle) setState(() => _isDraggingBottomHandle = false);
              },
              onPointerCancel: (_) {
                if (_isDraggingBottomHandle) setState(() => _isDraggingBottomHandle = false);
              },
              child: _buildVerticalHandleSliderPill(lowNote.displayName),
            ),
          ),
        ],
      ),
    );
  }

  /// 纵向推子视觉抓手：向左微型三角指针直指左侧琴键，内嵌音名与把手纹理 (带防溢出自适应)
  Widget _buildVerticalHandleSliderPill(String noteLabel) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 向左微型指针
            const Icon(
              Icons.arrow_left_rounded,
              size: 14,
              color: Color(0xFFFFB300),
            ),
            // 推子抓手本体 (紧凑高辨识)
            Container(
              width: 19,
              height: 30,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF141722),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFFFB300), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(1, 1),
                  ),
                  const BoxShadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.drag_indicator_rounded, size: 10, color: Color(0xFFFFB300)),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      noteLabel,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFB300),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
