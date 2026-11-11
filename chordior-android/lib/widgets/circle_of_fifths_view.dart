import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chordior_flutter/core/theory_engine.dart';

/// 现代交互式五度圈调式罗盘组件 (CustomPainter 纯原生绘制)
class CircleOfFifthsView extends StatefulWidget {
  final String currentKey;
  final bool isMinor;
  final ValueChanged<String>? onKeyChanged;
  final ValueChanged<bool>? onMinorChanged;

  const CircleOfFifthsView({
    super.key,
    required this.currentKey,
    this.isMinor = false,
    this.onKeyChanged,
    this.onMinorChanged,
  });

  @override
  State<CircleOfFifthsView> createState() => _CircleOfFifthsViewState();
}

class _CircleOfFifthsViewState extends State<CircleOfFifthsView> {
  int _selectedSector = 0; // 0 ~ 11
  bool _isMinorSelected = false;

  @override
  void initState() {
    super.initState();
    _syncCurrentKey();
  }

  @override
  void didUpdateWidget(covariant CircleOfFifthsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentKey != widget.currentKey || oldWidget.isMinor != widget.isMinor) {
      _syncCurrentKey();
    }
  }

  void _syncCurrentKey() {
    final clean = widget.currentKey.split('/').first.replaceAll('m', '').trim();
    _isMinorSelected = widget.isMinor;
    if (widget.isMinor) {
      for (int i = 0; i < kCircleRelativeMinors.length; i++) {
        if (kCircleRelativeMinors[i].split('/').contains(clean)) {
          _selectedSector = i;
          return;
        }
      }
    } else {
      for (int i = 0; i < kCircleOfFifths.length; i++) {
        if (kCircleOfFifths[i].split('/').contains(clean)) {
          _selectedSector = i;
          return;
        }
      }
    }
  }

  void _handleTap(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);

    final maxR = min(size.width, size.height) / 2 - 8;
    final innerR = maxR * 0.42;
    final midR = maxR * 0.72;

    // 点击在有效内外圈范围内
    if (dist < innerR || dist > maxR) return;

    // 计算极坐标角度 (12 点钟为 C，即 -90 度)
    double angle = atan2(dy, dx) * 180 / pi; // -180 ~ 180
    angle = (angle + 90) % 360;
    if (angle < 0) angle += 360;

    // 每个扇区 30 度
    int sector = ((angle + 15) ~/ 30) % 12;
    final isInner = dist < midR;

    setState(() {
      _selectedSector = sector;
      _isMinorSelected = isInner;
    });

    final keyName = isInner ? kCircleRelativeMinors[sector] : kCircleOfFifths[sector];
    widget.onMinorChanged?.call(isInner);
    widget.onKeyChanged?.call(keyName);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final renderSize = Size(size, size);

        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, renderSize),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: CustomPaint(
              size: renderSize,
              painter: _CircleOfFifthsPainter(
                selectedSector: _selectedSector,
                isMinorSelected: _isMinorSelected,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleOfFifthsPainter extends CustomPainter {
  final int selectedSector;
  final bool isMinorSelected;

  _CircleOfFifthsPainter({
    required this.selectedSector,
    required this.isMinorSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 8;
    final midR = maxR * 0.72;
    final innerR = maxR * 0.42;

    // 绘制外圈和内圈背景盘
    final bgPaint = Paint()
      ..color = const Color(0xFF141824)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR, bgPaint);

    // 绘制 12 个扇区
    const sweepAngle = 2 * pi / 12;
    const startOffsetAngle = -pi / 2 - sweepAngle / 2;

    for (int i = 0; i < 12; i++) {
      final sectorStart = startOffsetAngle + i * sweepAngle;

      // 1. 外圈扇区 (Major Keys)
      final isOuterSelected = (i == selectedSector && !isMinorSelected);
      final outerPaint = Paint()
        ..color = isOuterSelected ? const Color(0xFF0284C7).withValues(alpha: 0.45) : const Color(0xFF1E2333)
        ..style = PaintingStyle.fill;

      final outerPath = Path()
        ..moveTo(center.dx + midR * cos(sectorStart), center.dy + midR * sin(sectorStart))
        ..arcTo(
          Rect.fromCircle(center: center, radius: maxR),
          sectorStart,
          sweepAngle,
          false,
        )
        ..lineTo(center.dx + midR * cos(sectorStart + sweepAngle), center.dy + midR * sin(sectorStart + sweepAngle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: midR),
          sectorStart + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(outerPath, outerPaint);

      // 扇区边框
      final borderPaint = Paint()
        ..color = isOuterSelected ? const Color(0xFF38BDF8) : const Color(0xFF2E364B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isOuterSelected ? 2.5 : 1.0;
      canvas.drawPath(outerPath, borderPaint);

      // 2. 内圈扇区 (Minor Keys)
      final isInnerSectorSelected = (i == selectedSector && isMinorSelected);
      final innerPaint = Paint()
        ..color = isInnerSectorSelected ? const Color(0xFFA855F7).withValues(alpha: 0.45) : const Color(0xFF181D2C)
        ..style = PaintingStyle.fill;

      final innerPath = Path()
        ..moveTo(center.dx + innerR * cos(sectorStart), center.dy + innerR * sin(sectorStart))
        ..arcTo(
          Rect.fromCircle(center: center, radius: midR),
          sectorStart,
          sweepAngle,
          false,
        )
        ..lineTo(center.dx + innerR * cos(sectorStart + sweepAngle), center.dy + innerR * sin(sectorStart + sweepAngle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          sectorStart + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(innerPath, innerPaint);

      final innerBorderPaint = Paint()
        ..color = isInnerSectorSelected ? const Color(0xFFC084FC) : const Color(0xFF283042)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isInnerSectorSelected ? 2.2 : 0.8;
      canvas.drawPath(innerPath, innerBorderPaint);

      // 绘制外圈音名 (Major)
      final midAngle = sectorStart + sweepAngle / 2;
      final outerTextR = (maxR + midR) / 2;
      final outerTextPos = Offset(center.dx + outerTextR * cos(midAngle), center.dy + outerTextR * sin(midAngle));
      _drawText(
        canvas,
        kCircleOfFifths[i].split('/').first,
        outerTextPos,
        isOuterSelected ? const Color(0xFF38BDF8) : Colors.white,
        fontSize: size.width * 0.046,
        isBold: isOuterSelected,
      );

      // 绘制内圈音名 (Minor)
      final innerTextR = (midR + innerR) / 2;
      final innerTextPos = Offset(center.dx + innerTextR * cos(midAngle), center.dy + innerTextR * sin(midAngle));
      _drawText(
        canvas,
        '${kCircleRelativeMinors[i].split('/').first}m',
        innerTextPos,
        isInnerSectorSelected ? const Color(0xFFD8B4FE) : const Color(0xFF94A3B8),
        fontSize: size.width * 0.038,
        isBold: isInnerSectorSelected,
      );
    }

    // 绘制中心核心装饰圆
    final centerCorePaint = Paint()
      ..color = const Color(0xFF0F121C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerR, centerCorePaint);

    final centerBorder = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, innerR, centerBorder);

    // 中心显示当前选中的调式
    final currentKeyStr = isMinorSelected
        ? '${kCircleRelativeMinors[selectedSector].split('/').first} Minor'
        : '${kCircleOfFifths[selectedSector].split('/').first} Major';
    _drawText(
      canvas,
      currentKeyStr,
      center,
      isMinorSelected ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
      fontSize: size.width * 0.048,
      isBold: true,
    );
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, {double fontSize = 14, bool isBold = false}) {
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
    final offset = Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CircleOfFifthsPainter oldDelegate) {
    return oldDelegate.selectedSector != selectedSector || oldDelegate.isMinorSelected != isMinorSelected;
  }
}
