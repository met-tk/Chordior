import 'package:flutter/material.dart';
import 'package:chordior_flutter/core/theory_engine.dart';

/// 拟真触感 48 键专业大钢琴键盘 (C2 ~ B5, 28 白键 + 20 黑键)
/// 支持自由点击琴键选音/反选，与和弦及所属调式完全联动
class PianoView extends StatefulWidget {
  final Set<int> selectedIndices; // 绝对音高索引集合 (0~47)
  final Set<int> scalePitchClasses; // 调式音级集合 (0~11)
  final ValueChanged<int>? onKeyToggled; // 点击琴键切换选音回调
  final double zoom; // 缩放比例 (0.6x ~ 1.2x，默认 0.85x)
  final Color chordColor; // 和弦音高亮色
  final Color scaleColor; // 调式音高亮色
  final Color bothAccentColor; // 重叠强调色
  final double scaleGlowIntensity; // 调式音显色强度

  const PianoView({
    super.key,
    this.selectedIndices = const {},
    this.scalePitchClasses = const {},
    this.onKeyToggled,
    this.zoom = 0.85,
    this.chordColor = const Color(0xFF38BDF8),
    this.scaleColor = const Color(0xFF0EA5E9),
    this.bothAccentColor = const Color(0xFFF59E0B),
    this.scaleGlowIntensity = 0.65,
  });

  @override
  State<PianoView> createState() => _PianoViewState();
}

class _PianoViewState extends State<PianoView> {
  final ScrollController _scrollController = ScrollController();
  int? _lastTappedKey;

  // 48 键中白键对应的音高索引映射 (共 28 个白键)
  static final List<int> _whiteKeyIndices = [
    0, 2, 4, 5, 7, 9, 11, // C2 ~ B2
    12, 14, 16, 17, 19, 21, 23, // C3 ~ B3
    24, 26, 28, 29, 31, 33, 35, // C4 ~ B4
    36, 38, 40, 41, 43, 45, 47, // C5 ~ B5
  ];

  // 黑键排布元数据
  static final List<_BlackKeyMeta> _blackKeyMetas = [
    // Octave 2
    _BlackKeyMeta(1, 0), // C#2 / Db2 (在第 0 个白键右侧)
    _BlackKeyMeta(3, 1), // D#2 / Eb2
    _BlackKeyMeta(6, 3), // F#2 / Gb2
    _BlackKeyMeta(8, 4), // G#2 / Ab2
    _BlackKeyMeta(10, 5), // A#2 / Bb2
    // Octave 3
    _BlackKeyMeta(13, 7),
    _BlackKeyMeta(15, 8),
    _BlackKeyMeta(18, 10),
    _BlackKeyMeta(20, 11),
    _BlackKeyMeta(22, 12),
    // Octave 4 (中央 C 区)
    _BlackKeyMeta(25, 14),
    _BlackKeyMeta(27, 15),
    _BlackKeyMeta(30, 17),
    _BlackKeyMeta(32, 18),
    _BlackKeyMeta(34, 19),
    // Octave 5
    _BlackKeyMeta(37, 21),
    _BlackKeyMeta(39, 22),
    _BlackKeyMeta(42, 24),
    _BlackKeyMeta(44, 25),
    _BlackKeyMeta(46, 26),
  ];

  void _onKeyTap(int pitchIndex) {
    setState(() => _lastTappedKey = pitchIndex);
    widget.onKeyToggled?.call(pitchIndex);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _lastTappedKey = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final z = widget.zoom.clamp(0.3, 1.2);
    final whiteKeyWidth = 42.0 * z;
    final whiteKeyHeight = 150.0 * z;
    final blackKeyWidth = 26.0 * z;
    final blackKeyHeight = 92.0 * z;
    final totalWidth = whiteKeyWidth * 28;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部八度指示标尺 (随缩放自适应尺寸)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * z, vertical: 4 * z),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('C2 (低音)', style: TextStyle(color: Colors.white38, fontSize: (11 * z).clamp(7.5, 13.0))),
              Text('C3', style: TextStyle(color: Colors.white38, fontSize: (11 * z).clamp(7.5, 13.0))),
              Text('C4 (中央C)', style: TextStyle(color: widget.chordColor, fontSize: (12 * z).clamp(8.0, 14.0), fontWeight: FontWeight.bold)),
              Text('C5', style: TextStyle(color: Colors.white38, fontSize: (11 * z).clamp(7.5, 13.0))),
              Text('B5 (高音)', style: TextStyle(color: Colors.white38, fontSize: (11 * z).clamp(7.5, 13.0))),
            ],
          ),
        ),

        // 可横向滑动的钢琴键盘 (支持等比例缩放与高度收缩)
        SizedBox(
          height: whiteKeyHeight,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: whiteKeyHeight,
              child: Stack(
                children: [
                  // 1. 白键底排 (与黑键选中高亮风格完全统一)
                  Row(
                    children: List.generate(28, (index) {
                      final pitchIndex = _whiteKeyIndices[index];
                      final isSelected = widget.selectedIndices.contains(pitchIndex);
                      final isScale = widget.scalePitchClasses.contains(pitchIndex % 12);
                      final isBoth = isSelected && isScale;
                      final isTapped = _lastTappedKey == pitchIndex;

                      // 基础颜色与边框定义
                      Color keyColor = const Color(0xFFF8FAFC);
                      BorderSide borderSide = const BorderSide(color: Color(0xFF94A3B8), width: 0.6);

                      if (isTapped) {
                        keyColor = const Color(0xFF93C5FD);
                      } else if (isSelected) {
                        // 选中的白键与黑键统一使用配色方案第一主色 chordColor 实体填充，避免发暗发黑
                        keyColor = widget.chordColor;
                        borderSide = isBoth
                            ? BorderSide(color: widget.bothAccentColor, width: 2.0 * z)
                            : BorderSide(color: Colors.white.withValues(alpha: 0.85), width: 1.5 * z);
                      } else if (isScale) {
                        keyColor = Colors.white;
                        borderSide = BorderSide(color: widget.scaleColor.withValues(alpha: 0.5), width: 1.0 * z);
                      }

                      return GestureDetector(
                        onTapDown: (_) => _onKeyTap(pitchIndex),
                        child: Container(
                          width: whiteKeyWidth,
                          height: whiteKeyHeight,
                          decoration: BoxDecoration(
                            // 选中时白键带微弱立体垂直渐变，饱满明亮
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      widget.chordColor,
                                      widget.chordColor.darkerOr(0.12),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : keyColor,
                            border: Border(
                              left: borderSide,
                              right: borderSide,
                              bottom: borderSide,
                              top: const BorderSide(color: Color(0xFF64748B), width: 0.5),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(5 * z),
                              bottomRight: Radius.circular(5 * z),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (isBoth ? widget.bothAccentColor : widget.chordColor).withValues(alpha: 0.45),
                                      blurRadius: 8 * z,
                                      spreadRadius: 1 * z,
                                    )
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // 白键调式音强化弱光底衬 (未选中时柔和呈现)
                              if (isScale && !isSelected)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: whiteKeyHeight * 0.38,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.scaleColor.withValues(alpha: (widget.scaleGlowIntensity * 0.38).clamp(0.15, 0.75)),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(4 * z),
                                        bottomRight: Radius.circular(4 * z),
                                      ),
                                    ),
                                  ),
                                ),

                              // 底部音名展示 (选中时与黑键完全一致，使用清晰的纯白粗体)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 6 * z,
                                child: Text(
                                  kNoteNames[pitchIndex % 12].split('/').first,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: (11 * z).clamp(7.0, 14.0),
                                    fontWeight: (isSelected || isScale) ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isScale ? widget.scaleColor : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  // 2. 黑键浮层 (带调式高光边框与弱光底衬)
                  ..._blackKeyMetas.map((meta) {
                    final leftPos = (meta.whiteIndexBefore + 1) * whiteKeyWidth - (blackKeyWidth / 2);
                    final pitchIndex = meta.pitchIndex;
                    final isSelected = widget.selectedIndices.contains(pitchIndex);
                    final isScale = widget.scalePitchClasses.contains(pitchIndex % 12);
                    final isBoth = isSelected && isScale;
                    final isTapped = _lastTappedKey == pitchIndex;

                    Color keyColor = const Color(0xFF1E293B);
                    BorderSide borderSide = BorderSide.none;

                    if (isTapped) {
                      keyColor = const Color(0xFF60A5FA);
                    } else if (isBoth) {
                      keyColor = widget.chordColor;
                      borderSide = BorderSide(color: widget.bothAccentColor, width: 2.0 * z);
                    } else if (isSelected) {
                      keyColor = widget.chordColor;
                      borderSide = BorderSide(color: Colors.white, width: 1.5 * z);
                    } else if (isScale) {
                      keyColor = const Color(0xFF1E293B);
                      borderSide = BorderSide(
                        color: widget.scaleColor.withValues(alpha: (widget.scaleGlowIntensity + 0.2).clamp(0.4, 1.0)),
                        width: 1.6 * z,
                      );
                    }

                    return Positioned(
                      left: leftPos,
                      top: 0,
                      child: GestureDetector(
                        onTapDown: (_) => _onKeyTap(pitchIndex),
                        child: Container(
                          width: blackKeyWidth,
                          height: blackKeyHeight,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      widget.chordColor,
                                      widget.chordColor.darkerOr(0.14),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : keyColor,
                            border: borderSide != BorderSide.none
                                ? Border.all(color: borderSide.color, width: borderSide.width)
                                : null,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4 * z),
                              bottomRight: Radius.circular(4 * z),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isBoth
                                        ? widget.bothAccentColor
                                        : (isSelected ? widget.chordColor : Colors.black))
                                    .withValues(alpha: isSelected ? 0.55 : 0.4),
                                blurRadius: (isSelected ? 6 : 3) * z,
                                offset: Offset(0, 2 * z),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // 黑键调式音强化弱光底衬 (横向完整铺满黑键宽度，覆盖整个下半部分 45%)
                              if (isScale && !isSelected)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: blackKeyHeight * 0.45,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.scaleColor.withValues(
                                        alpha: (widget.scaleGlowIntensity * 0.55).clamp(0.2, 0.85),
                                      ),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(3.5 * z),
                                        bottomRight: Radius.circular(3.5 * z),
                                      ),
                                    ),
                                  ),
                                ),

                              // 底部音名居中展示 (横向铺满整个黑键)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 5 * z,
                                child: Text(
                                  kNoteNames[pitchIndex % 12].split('/').first,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: (9.5 * z).clamp(6.5, 12.0),
                                    fontWeight: (isSelected || isScale) ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (isScale ? widget.scaleColor : Colors.white60),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlackKeyMeta {
  final int pitchIndex;
  final int whiteIndexBefore;

  const _BlackKeyMeta(this.pitchIndex, this.whiteIndexBefore);
}

extension ColorDarken on Color {
  Color darkerOr(double factor) {
    return Color.fromARGB(
      (a * 255.0).toInt().clamp(0, 255),
      (r * 255.0 * (1.0 - factor)).toInt().clamp(0, 255),
      (g * 255.0 * (1.0 - factor)).toInt().clamp(0, 255),
      (b * 255.0 * (1.0 - factor)).toInt().clamp(0, 255),
    );
  }
}
