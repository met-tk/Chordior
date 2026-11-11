import 'package:flutter/material.dart';
import 'package:chordior_flutter/core/theory_engine.dart';

/// 6 弦 21 品专业吉他指板交互组件 (CustomPainter 渲染)
/// 支持点击品位切换选音、立体高亮珍珠贝母菱形品记、品格数字标记、动态缩放与调式音高亮强化
class GuitarView extends StatefulWidget {
  final Set<int> selectedIndices; // 当前点选激活的绝对音高索引集合 (0~47)
  final Set<int> scalePitchClasses; // 调式音级集合 (0~11)
  final int? rootPitchClass; // 和弦根音音级 (0~11)
  final int? scaleRootPitchClass; // 调式根音/主音音级 (0~11)
  final bool highlightChordRoot; // 是否高亮和弦根音 (可设置项控制)
  final bool highlightScaleRoot; // 是否高亮调式主音 (可设置项控制)
  final ValueChanged<int>? onFretToggled; // 点击品位切换选音回调
  final double zoom; // 缩放比例 (0.6x ~ 1.2x，默认 0.85x)
  final Color chordColor; // 和弦音高亮色
  final Color scaleColor; // 调式音高亮色
  final Color bothAccentColor; // 重叠强调色
  final Color chordRootColor; // 和弦根音专属高亮色
  final Color scaleRootColor; // 调式主音专属高亮色
  final double scaleGlowIntensity; // 调式音显色强度

  const GuitarView({
    super.key,
    this.selectedIndices = const {},
    this.scalePitchClasses = const {},
    this.rootPitchClass,
    this.scaleRootPitchClass,
    this.highlightChordRoot = true,
    this.highlightScaleRoot = false,
    this.onFretToggled,
    this.zoom = 0.85,
    this.chordColor = const Color(0xFF38BDF8),
    this.scaleColor = const Color(0xFF0EA5E9),
    this.bothAccentColor = const Color(0xFFF59E0B),
    this.chordRootColor = const Color(0xFFFB923C),
    this.scaleRootColor = const Color(0xFFFBBF24),
    this.scaleGlowIntensity = 0.65,
  });

  @override
  State<GuitarView> createState() => _GuitarViewState();
}

class _GuitarViewState extends State<GuitarView> {
  final ScrollController _scrollController = ScrollController();
  // 6 弦空弦绝对音高 (E4=28, B3=23, G3=19, D3=14, A2=9, E2=4)
  static const stringPitches = [28, 23, 19, 14, 9, 4];
  static const numFrets = 21;

  void _onTapFret(int stringIdx, int fretIdx) {
    final absPitch = stringPitches[stringIdx] + fretIdx;
    widget.onFretToggled?.call(absPitch);
  }

  @override
  Widget build(BuildContext context) {
    final z = widget.zoom.clamp(0.3, 1.2);
    final fretWidth = 46.0 * z;
    final nutWidth = 36.0 * z;
    final totalWidth = nutWidth + fretWidth * numFrets;
    // 包含底部品格数字预留空间
    final boardHeight = 160.0 * z;
    final totalHeight = boardHeight + (18.0 * z);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 指板滑动容器 (支持缩放改变整体尺寸与垂直占用高度)
        SizedBox(
          height: totalHeight,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _GuitarBoardPainter(
                  selectedIndices: widget.selectedIndices,
                  rootPitchClass: widget.rootPitchClass,
                  scaleRootPitchClass: widget.scaleRootPitchClass,
                  highlightChordRoot: widget.highlightChordRoot,
                  highlightScaleRoot: widget.highlightScaleRoot,
                  scalePitchClasses: widget.scalePitchClasses,
                  stringPitches: stringPitches,
                  nutWidth: nutWidth,
                  fretWidth: fretWidth,
                  boardHeight: boardHeight,
                  zoom: z,
                  chordColor: widget.chordColor,
                  scaleColor: widget.scaleColor,
                  bothAccentColor: widget.bothAccentColor,
                  chordRootColor: widget.chordRootColor,
                  scaleRootColor: widget.scaleRootColor,
                  scaleGlowIntensity: widget.scaleGlowIntensity,
                ),
                child: GestureDetector(
                  onTapUp: (details) {
                    final pos = details.localPosition;
                    if (pos.dy > boardHeight) return;

                    int fret = 0;
                    if (pos.dx >= nutWidth) {
                      fret = ((pos.dx - nutWidth) ~/ fretWidth) + 1;
                    }
                    if (fret > numFrets) fret = numFrets;

                    // 计算是哪根弦 (0~5)
                    final stringSpacing = (boardHeight - 32 * z) / 5;
                    int str = ((pos.dy - 16 * z) / stringSpacing).round();
                    if (str < 0) str = 0;
                    if (str > 5) str = 5;

                    _onTapFret(str, fret);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuitarBoardPainter extends CustomPainter {
  final Set<int> selectedIndices;
  final int? rootPitchClass;
  final int? scaleRootPitchClass;
  final bool highlightChordRoot;
  final bool highlightScaleRoot;
  final Set<int> scalePitchClasses;
  final List<int> stringPitches;
  final double nutWidth;
  final double fretWidth;
  final double boardHeight;
  final double zoom;
  final Color chordColor;
  final Color scaleColor;
  final Color bothAccentColor;
  final Color chordRootColor;
  final Color scaleRootColor;
  final double scaleGlowIntensity;

  const _GuitarBoardPainter({
    required this.selectedIndices,
    required this.rootPitchClass,
    required this.scaleRootPitchClass,
    required this.highlightChordRoot,
    required this.highlightScaleRoot,
    required this.scalePitchClasses,
    required this.stringPitches,
    required this.nutWidth,
    required this.fretWidth,
    required this.boardHeight,
    required this.zoom,
    required this.chordColor,
    required this.scaleColor,
    required this.bothAccentColor,
    required this.chordRootColor,
    required this.scaleRootColor,
    required this.scaleGlowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topMargin = 8.0 * zoom;
    final boardRect = Rect.fromLTWH(0, topMargin, size.width, boardHeight - topMargin * 2);

    // 1. 指板深色优雅底板
    final boardPaint = Paint()..color = const Color(0xFF151821);
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, Radius.circular(6 * zoom)), boardPaint);

    // 2. 琴枕 (Nut)
    final nutPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(nutWidth - (5 * zoom), topMargin, 5 * zoom, boardHeight - topMargin * 2),
        Radius.circular(2 * zoom),
      ),
      nutPaint,
    );

    // 3. 绘制 21 根金属品柱 (Frets)
    final fretLinePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.8 * zoom;
    for (int f = 1; f <= 21; f++) {
      final x = nutWidth + f * fretWidth;
      canvas.drawLine(Offset(x, topMargin), Offset(x, boardHeight - topMargin), fretLinePaint);
    }

    // 4. 绘制立体高亮珍珠贝母菱形品记 (Pearl Diamond Inlays)
    // 3, 5, 7, 9, 15, 17, 19, 21 品单菱形，12 品双菱形
    final cy = boardHeight / 2;
    for (int f = 1; f <= 21; f++) {
      final cx = nutWidth + (f - 0.5) * fretWidth;
      if ([3, 5, 7, 9, 15, 17, 19, 21].contains(f)) {
        _drawDiamond(canvas, cx, cy, 4.2 * zoom, 7.0 * zoom);
      } else if (f == 12) {
        _drawDiamond(canvas, cx, cy - (16 * zoom), 3.8 * zoom, 6.2 * zoom);
        _drawDiamond(canvas, cx, cy + (16 * zoom), 3.8 * zoom, 6.2 * zoom);
      }
    }

    // 5. 绘制品格编号 (1 ~ 21 品数字，置于指板正下方)
    for (int f = 1; f <= 21; f++) {
      final cx = nutWidth + (f - 0.5) * fretWidth;
      final isSpecial = [3, 5, 7, 9, 12, 15, 17, 19, 21].contains(f);
      final numColor = isSpecial ? const Color(0xFFE2E8F0) : const Color(0xFF64748B);
      _drawText(
        canvas,
        '$f',
        Offset(cx, boardHeight + (8 * zoom)),
        numColor,
        fontSize: isSpecial ? (10.0 * zoom).clamp(7.0, 14.0) : (8.5 * zoom).clamp(6.5, 12.0),
        isBold: isSpecial,
      );
    }

    // 6. 绘制 6 根琴弦 (带粗细渐变与弦号标注)
    final stringSpacing = (boardHeight - topMargin * 2 - (16 * zoom)) / 5;
    for (int s = 0; s < 6; s++) {
      final y = topMargin + (8 * zoom) + s * stringSpacing;
      final thickness = (0.9 + (5 - s) * 0.42) * zoom;
      final strPaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = thickness;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), strPaint);
    }

    // 7. 绘制品位音符指示球 (和弦选音、调式音、和弦根音高亮与调式主音高亮)
    for (int s = 0; s < 6; s++) {
      final y = topMargin + (8 * zoom) + s * stringSpacing;
      final openPitch = stringPitches[s];

      for (int f = 0; f <= 21; f++) {
        final pitch = openPitch + f;
        final pc = pitch % 12;
        final isSelected = selectedIndices.contains(pitch);
        final isScale = scalePitchClasses.contains(pc);

        if (!isSelected && !isScale) continue;

        // 根据开关判断是否高亮和弦根音或调式主音
        final isChordRoot = highlightChordRoot && (rootPitchClass != null && rootPitchClass == pc && isSelected);
        final isScaleRoot = highlightScaleRoot && (scaleRootPitchClass != null && scaleRootPitchClass == pc && isScale);

        final cx = f == 0 ? (nutWidth / 2) : (nutWidth + (f - 0.5) * fretWidth);
        final noteName = kNoteNames[pc].split('/').first;

        Color dotColor;
        Color textColor = Colors.white;
        double radius = 11.0 * zoom;

        if (isChordRoot) {
          // 和弦根音：使用配色方案专属和弦根音高亮色
          dotColor = chordRootColor;
          radius = 12.5 * zoom;
        } else if (isSelected && isScale) {
          // 调内核心和弦音
          dotColor = chordColor;
          radius = 12.0 * zoom;
        } else if (isSelected) {
          // 离调和弦音
          dotColor = chordColor;
          radius = 11.5 * zoom;
        } else if (isScaleRoot) {
          // 仅调式主音 (受 scaleGlowIntensity 显色强度控制，通透底衬不抢和弦视觉)
          final rootAlpha = (scaleGlowIntensity * 0.70).clamp(0.2, 0.85);
          dotColor = scaleRootColor.withValues(alpha: rootAlpha);
          textColor = Colors.white.withValues(alpha: (scaleGlowIntensity + 0.15).clamp(0.4, 0.95));
          radius = 10.0 * zoom;
        } else {
          // 普通调式音 (根据 scaleGlowIntensity 柔和渲染)
          final alphaVal = (scaleGlowIntensity * 0.75).clamp(0.2, 0.95);
          dotColor = scaleColor.withValues(alpha: alphaVal);
          textColor = Colors.white.withValues(alpha: (scaleGlowIntensity + 0.2).clamp(0.4, 1.0));
          radius = 9.5 * zoom;
        }

        // 绘制阴影发光光晕 (仅对实际点选/按下的和弦组成音与和弦根音生效)
        if (isSelected || isChordRoot) {
          final glowPaint = Paint()
            ..color = (isChordRoot ? chordRootColor : dotColor).withValues(alpha: 0.5)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * zoom);
          canvas.drawCircle(Offset(cx, y), radius + (2 * zoom), glowPaint);
        }

        // 调内和弦音双环光晕 (使用 bothAccentColor 轮廓)
        if (isSelected && isScale && !isChordRoot) {
          final accentBorder = Paint()
            ..color = bothAccentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * zoom;
          canvas.drawCircle(Offset(cx, y), radius + (1.5 * zoom), accentBorder);
        }

        // 调式主音双环轮廓 (受 scaleGlowIntensity 调节，柔和典雅不刺眼)
        if (isScaleRoot && !isChordRoot) {
          final tonicBorder = Paint()
            ..color = scaleRootColor.withValues(alpha: (scaleGlowIntensity * 0.85).clamp(0.25, 0.9))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * zoom;
          canvas.drawCircle(Offset(cx, y), radius + (1.8 * zoom), tonicBorder);
        }

        final p = Paint()..color = dotColor;
        canvas.drawCircle(Offset(cx, y), radius, p);

        // 绘制音符文字
        _drawText(
          canvas,
          noteName,
          Offset(cx, y),
          textColor,
          fontSize: ((radius > 10 * zoom ? 9.5 : 8.0) * zoom).clamp(6.5, 13.0),
          isBold: isSelected || isChordRoot || isScaleRoot,
        );
      }
    }
  }

  /// 绘制立体珍珠贝母菱形品记 (Pearl Diamond Inlay)
  void _drawDiamond(Canvas canvas, double cx, double cy, double hw, double hh) {
    final path = Path()
      ..moveTo(cx, cy - hh)
      ..lineTo(cx + hw, cy)
      ..lineTo(cx, cy + hh)
      ..lineTo(cx - hw, cy)
      ..close();

    // 珍珠贝母立体光泽纯净渐变
    final gradPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF1F5F9),
          Color(0xFFCBD5E1),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: hw * 2, height: hh * 2));
    canvas.drawPath(path, gradPaint);

    // 纯白高亮轮廓，大幅提高对比度与显眼度
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * zoom;
    canvas.drawPath(path, strokePaint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    double fontSize = 9.0,
    bool isBold = false,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GuitarBoardPainter old) {
    return old.selectedIndices != selectedIndices ||
        old.rootPitchClass != rootPitchClass ||
        old.scalePitchClasses != scalePitchClasses ||
        old.zoom != zoom ||
        old.chordColor != chordColor ||
        old.scaleColor != scaleColor ||
        old.bothAccentColor != bothAccentColor ||
        old.scaleGlowIntensity != scaleGlowIntensity;
  }
}
