import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/music_theory.dart';
import '../../core/key_signature.dart';
import '../../core/staff_theory.dart';
import '../../models/vocal_range_model.dart';

/// 大谱表古典出版级高保真矢量五线谱组件 (包含高低音谱表、标准调号记号与极简科学记谱呈现)
class GrandStaffView extends StatelessWidget {
  final int activeMidi;
  final bool preferSharp;
  final KeySignature keySignature;
  final ValueChanged<KeySignature>? onKeySignatureChanged;
  final int? highlightTrainerMidi;
  final VocalRangeItem? activeRange;
  final double height;

  const GrandStaffView({
    super.key,
    required this.activeMidi,
    this.preferSharp = true,
    this.keySignature = KeySignature.defaultKey,
    this.onKeySignatureChanged,
    this.highlightTrainerMidi,
    this.activeRange,
    this.height = 116.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.staffBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.staffBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. 五线谱自定义矢量画布
            Positioned.fill(
              child: CustomPaint(
                painter: _GrandStaffPainter(
                  activeMidi: highlightTrainerMidi ?? activeMidi,
                  preferSharp: preferSharp,
                  keySignature: keySignature,
                  activeRange: activeRange,
                  isDark: isDark,
                ),
              ),
            ),

            // 2. 谱号交互区域：点击高低音谱号区域自定义调号 (消除悬浮按钮对高音谱号的遮挡，完全保持原有功能)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: ((7.0 * (height / 116.0)).clamp(4.2, 13.0) / 7.0 * 48.0).clamp(36.0, 76.0),
              child: Tooltip(
                message: '点击谱号切换调号 (当前: ${keySignature.displayLabel} ${keySignature.accidentalsDescription})',
                waitDuration: const Duration(milliseconds: 300),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showKeySignatureSheet(context),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                    hoverColor: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                    highlightColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹出调号选择弹窗 (结构化展示自然调、升号调与降号调)
  void _showKeySignatureSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF14171F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '五线谱调号设置',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 自然大调
                          _buildSectionTitle('自然大调', isDark),
                          const SizedBox(height: 6),
                          _buildKeyChip(context, ctx, KeySignature.naturalKey, isDark),

                          const SizedBox(height: 12),

                          // 2. 升号调系
                          _buildSectionTitle('升号调系 (♯)', isDark),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: KeySignature.sharpKeys
                                .map((key) => _buildKeyChip(context, ctx, key, isDark))
                                .toList(),
                          ),

                          const SizedBox(height: 12),

                          // 3. 降号调系
                          _buildSectionTitle('降号调系 (♭)', isDark),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: KeySignature.flatKeys
                                .map((key) => _buildKeyChip(context, ctx, key, isDark))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white54 : Colors.black54,
      ),
    );
  }

  Widget _buildKeyChip(BuildContext context, BuildContext sheetCtx, KeySignature key, bool isDark) {
    final isSelected = key.id == keySignature.id;
    return ChoiceChip(
      label: Text(
        '${key.displayLabel} (${key.accidentalsDescription})',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF007799))
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.22 : 0.15),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF00E5FF)
            : (isDark ? Colors.white12 : Colors.black12),
        width: isSelected ? 1.2 : 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (selected) {
        if (selected) {
          onKeySignatureChanged?.call(key);
          Navigator.of(sheetCtx).pop();
        }
      },
    );
  }
}

class _GrandStaffPainter extends CustomPainter {
  final int activeMidi;
  final bool preferSharp;
  final KeySignature keySignature;
  final VocalRangeItem? activeRange;
  final bool isDark;

  _GrandStaffPainter({
    required this.activeMidi,
    required this.preferSharp,
    required this.keySignature,
    this.activeRange,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double baseLineSpacing = (7.0 * (size.height / 116.0)).clamp(4.2, 13.0);
    final double halfSpacing = baseLineSpacing / 2.0;
    final double scaleFactor = (baseLineSpacing / 7.0).clamp(0.55, 1.85);

    // 谱表基准线计算 (以中央 C4 为基准 0)
    final double middleC4Y = size.height / 2.0;

    // 高音谱表 5 条线 (E4: step 2 到 F5: step 10)
    final double trebleLine1Y = middleC4Y - (2 * halfSpacing); // E4 (第一线)

    // 低音谱表 5 条线 (G2: step -10 到 A3: step -2)
    final double bassLine5Y = middleC4Y + (2 * halfSpacing);   // A3 (第五线)

    // 线条画笔
    final staffLineColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.14);
    final staffLinePaint = Paint()
      ..color = staffLineColor
      ..strokeWidth = (0.9 * scaleFactor).clamp(0.65, 1.6)
      ..style = PaintingStyle.stroke;

    final barLineColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.30);
    final barLinePaint = Paint()
      ..color = barLineColor
      ..strokeWidth = (1.4 * scaleFactor).clamp(1.0, 2.4)
      ..style = PaintingStyle.stroke;

    final double leftMargin = 12.0 * scaleFactor;
    final double rightMargin = 12.0 * scaleFactor;

    // 1. 绘制高音谱表 5 条平行线
    for (int i = 0; i < 5; i++) {
      final y = trebleLine1Y - (i * baseLineSpacing);
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), staffLinePaint);
    }

    // 2. 绘制低音谱表 5 条平行线
    for (int i = 0; i < 5; i++) {
      final y = bassLine5Y + (i * baseLineSpacing);
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), staffLinePaint);
    }

    // 3. 绘制谱表左侧连谱线 (Brace Barline)
    final trebleTopY = trebleLine1Y - (4 * baseLineSpacing);
    final bassBottomY = bassLine5Y + (4 * baseLineSpacing);
    canvas.drawLine(Offset(leftMargin, trebleTopY), Offset(leftMargin, bassBottomY), barLinePaint);

    // 4. 绘制古典矢量高音谱号 (G Clef) 与低音谱号 (F Clef)
    final clefStartX = leftMargin + 6 * scaleFactor;
    _drawVectorTrebleClef(canvas, clefStartX, trebleTopY, baseLineSpacing);
    _drawVectorBassClef(canvas, clefStartX, bassLine5Y, baseLineSpacing);

    // 5. 绘制调号 (Key Signature Glyphs)
    double noteAreaStartX = clefStartX + 24 * scaleFactor;
    if (keySignature.accidentalCount != 0) {
      final accSymbol = keySignature.isSharp ? '♯' : '♭';
      final accCount = keySignature.accidentalCount.abs();
      final double accSpacing = 8.5 * scaleFactor;

      final keyPaint = TextPainter(textDirection: TextDirection.ltr);

      // 绘制高音谱表调号记号
      for (int i = 0; i < keySignature.trebleAccidentalSteps.length; i++) {
        final step = keySignature.trebleAccidentalSteps[i];
        final accY = middleC4Y - (step * halfSpacing);
        final accX = noteAreaStartX + (i * accSpacing);

        keyPaint.text = TextSpan(
          text: accSymbol,
          style: TextStyle(
            fontSize: (11.5 * scaleFactor).clamp(7.5, 18.0),
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.70),
          ),
        );
        keyPaint.layout();
        keyPaint.paint(canvas, Offset(accX, accY - keyPaint.height / 2 - 0.5));
      }

      // 绘制低音谱表调号记号
      for (int i = 0; i < keySignature.bassAccidentalSteps.length; i++) {
        final step = keySignature.bassAccidentalSteps[i];
        final accY = middleC4Y - (step * halfSpacing);
        final accX = noteAreaStartX + (i * accSpacing);

        keyPaint.text = TextSpan(
          text: accSymbol,
          style: TextStyle(
            fontSize: (11.5 * scaleFactor).clamp(7.5, 18.0),
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.70),
          ),
        );
        keyPaint.layout();
        keyPaint.paint(canvas, Offset(accX, accY - keyPaint.height / 2 - 0.5));
      }

      noteAreaStartX += (accCount * accSpacing) + 6 * scaleFactor;
    }

    // 6. 绘制音符 (恢复最低音与最高音纯音符呈现，无大括号、无多余文字)
    final double availWidth = (size.width - rightMargin) - noteAreaStartX;
    if (activeRange != null && activeRange!.startMidi < activeRange!.endMidi) {
      final lowMidi = activeRange!.startMidi;
      final highMidi = activeRange!.endMidi;
      final rangeColor = activeRange!.color;

      final lowX = noteAreaStartX + availWidth * 0.22;
      final curX = noteAreaStartX + availWidth * 0.52;
      final highX = noteAreaStartX + availWidth * 0.82;

      // 最低音 (纯音符呈现)
      _drawNoteOnStaff(
        canvas: canvas,
        midi: lowMidi,
        x: lowX,
        middleC4Y: middleC4Y,
        halfSpacing: halfSpacing,
        scaleFactor: scaleFactor,
        color: rangeColor.withValues(alpha: isDark ? 0.75 : 0.70),
        isHighlight: false,
      );

      // 最高音 (纯音符呈现)
      _drawNoteOnStaff(
        canvas: canvas,
        midi: highMidi,
        x: highX,
        middleC4Y: middleC4Y,
        halfSpacing: halfSpacing,
        scaleFactor: scaleFactor,
        color: rangeColor.withValues(alpha: isDark ? 0.75 : 0.70),
        isHighlight: false,
      );

      // 当前音 (高亮呈现)
      final curColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF00838F);
      _drawNoteOnStaff(
        canvas: canvas,
        midi: activeMidi,
        x: curX,
        middleC4Y: middleC4Y,
        halfSpacing: halfSpacing,
        scaleFactor: scaleFactor,
        color: curColor,
        isHighlight: true,
      );
    } else {
      final curX = noteAreaStartX + availWidth * 0.5;
      final curColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF00838F);

      _drawNoteOnStaff(
        canvas: canvas,
        midi: activeMidi,
        x: curX,
        middleC4Y: middleC4Y,
        halfSpacing: halfSpacing,
        scaleFactor: scaleFactor,
        color: curColor,
        isHighlight: true,
      );
    }
  }

  /// 在大谱表上精准绘制单个音符
  void _drawNoteOnStaff({
    required Canvas canvas,
    required int midi,
    required double x,
    required double middleC4Y,
    required double halfSpacing,
    required double scaleFactor,
    required Color color,
    required bool isHighlight,
  }) {
    // 严谨计算乐理位置与变音记号
    final notePos = StaffTheory.calculatePosition(
      midi,
      keySignature: keySignature,
      preferSharp: preferSharp,
    );
    final noteY = middleC4Y - (notePos.diatonicStep * halfSpacing);

    // 1. 绘制附加线 (Ledger Lines)
    final ledgerColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF4A5568).withValues(alpha: 0.7);
    final ledgerPaint = Paint()
      ..color = ledgerColor
      ..strokeWidth = (1.3 * scaleFactor).clamp(1.0, 2.4)
      ..style = PaintingStyle.stroke;

    final ledgerWing = 8.0 * scaleFactor;
    for (final ledgerStep in notePos.ledgerLines) {
      final ledgerY = middleC4Y - (ledgerStep * halfSpacing);
      canvas.drawLine(Offset(x - ledgerWing, ledgerY), Offset(x + ledgerWing, ledgerY), ledgerPaint);
    }

    // 2. 绘制变音记号 (若调号内已包含则无需临时记号；调外音或还原音精准绘制)
    if (notePos.accidental.isNotEmpty) {
      final accPainter = TextPainter(
        text: TextSpan(
          text: notePos.accidental,
          style: TextStyle(
            fontSize: (13.0 * scaleFactor).clamp(8.0, 22.0),
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      accPainter.paint(canvas, Offset(x - 14 * scaleFactor, noteY - accPainter.height / 2 - 1));
    }

    // 3. 绘制音符头 (Notehead)
    canvas.save();
    canvas.translate(x, noteY);
    canvas.rotate(-0.25); // 经典出版级倾角

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final noteWidth = (isHighlight ? 9.5 : 8.0) * scaleFactor;
    final noteHeight = (isHighlight ? 6.8 : 5.8) * scaleFactor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: noteWidth, height: noteHeight),
      headPaint,
    );
    canvas.restore();

    // 4. 绘制符干 (Stem)
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = (1.3 * scaleFactor).clamp(1.0, 2.4);
    final stemUp = notePos.diatonicStep < 6; // 中线 B4 以下符干朝上
    final stemX = stemUp ? x + 3.8 * scaleFactor : x - 3.8 * scaleFactor;
    final stemYEnd = stemUp ? noteY - 22 * scaleFactor : noteY + 22 * scaleFactor;
    canvas.drawLine(Offset(stemX, noteY), Offset(stemX, stemYEnd), stemPaint);

    // 5. 纯净极简音名小标签 (仅展示音名，如 "C4", "F♯4", 绝无多余字样)
    final formatted = MusicTheory.getFormattedNote(midi, preferSharp: preferSharp);
    final labelPainter = TextPainter(
      text: TextSpan(
        text: formatted.displayName,
        style: TextStyle(
          fontSize: (9.0 * scaleFactor).clamp(6.5, 14.0),
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelY = stemUp ? noteY + 6 * scaleFactor : noteY - 10 * scaleFactor - labelPainter.height;
    labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, labelY));
  }

  /// 国际乐谱出版级高音谱号 (G Clef)
  void _drawVectorTrebleClef(Canvas canvas, double startX, double topY, double spacing) {
    final gLineY = topY + spacing * 3.0; // 第二线 G4 基准线
    final cx = startX + 4.0;
    final clefColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007799);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '\uE050',
        style: TextStyle(
          fontFamily: 'Leland',
          fontSize: spacing * 4.0,
          color: clefColor,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baselineDistance = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    if (textPainter.width > 2.0 && baselineDistance > 0) {
      final yOffset = gLineY - baselineDistance;
      textPainter.paint(canvas, Offset(cx, yOffset));
      return;
    }

    // 贝塞尔 Path 兜底
    final strokePaint = Paint()
      ..color = clefColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..color = clefColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final stemTopY = topY - spacing * 1.35;
    final stemBottomY = gLineY + spacing * 1.85;

    final spinePath = Path();
    spinePath.moveTo(cx + 6.5, stemTopY);
    spinePath.cubicTo(cx + 6.8, topY, cx + 6.8, gLineY, cx + 6.2, stemBottomY);
    spinePath.cubicTo(cx + 5.8, stemBottomY + spacing * 0.5, cx + 2.2, stemBottomY + spacing * 0.45, cx + 1.6, stemBottomY - spacing * 0.1);
    canvas.drawPath(spinePath, strokePaint..strokeWidth = 2.0);

    canvas.drawCircle(Offset(cx + 1.8, stemBottomY - spacing * 0.05), 2.0, fillPaint);

    final topLoop = Path();
    topLoop.moveTo(cx + 6.5, stemTopY);
    topLoop.cubicTo(cx + 2.6, stemTopY + spacing * 0.4, cx + 2.6, topY + spacing * 0.6, cx + 6.5, topY + spacing * 1.3);
    canvas.drawPath(topLoop, strokePaint..strokeWidth = 1.8);

    final bellyPath = Path();
    bellyPath.moveTo(cx + 6.5, topY + spacing * 1.3);
    bellyPath.cubicTo(cx + 12.2, topY + spacing * 1.8, cx + 13.0, gLineY + spacing * 0.2, cx + 9.2, gLineY + spacing * 1.1);
    bellyPath.cubicTo(cx + 7.1, gLineY + spacing * 1.4, cx + 1.5, gLineY + spacing * 1.3, cx + 1.0, gLineY + spacing * 0.3);
    bellyPath.cubicTo(cx + 0.5, gLineY - spacing * 0.7, cx + 4.6, gLineY - spacing * 1.1, cx + 7.4, gLineY - spacing * 0.8);
    bellyPath.cubicTo(cx + 9.8, gLineY - spacing * 0.5, cx + 9.6, gLineY + spacing * 0.3, cx + 6.9, gLineY + spacing * 0.45);
    bellyPath.cubicTo(cx + 4.4, gLineY + spacing * 0.55, cx + 3.5, gLineY + spacing * 0.1, cx + 3.8, gLineY - spacing * 0.2);
    bellyPath.cubicTo(cx + 4.1, gLineY - spacing * 0.4, cx + 5.6, gLineY - spacing * 0.4, cx + 6.2, gLineY);
    canvas.drawPath(bellyPath, strokePaint..strokeWidth = 2.2);

    canvas.drawCircle(Offset(cx + 6.2, gLineY), 1.5, fillPaint);
  }

  /// 国际乐谱出版级低音谱号 (F Clef)
  void _drawVectorBassClef(Canvas canvas, double startX, double line5Y, double spacing) {
    final fLineY = line5Y + spacing; // 第四线 F3 基准线
    final cx = startX + 4.0;
    final clefColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007799);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '\uE062',
        style: TextStyle(
          fontFamily: 'Leland',
          fontSize: spacing * 4.0,
          color: clefColor,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baselineDistance = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    if (textPainter.width > 2.0 && baselineDistance > 0) {
      final yOffset = fLineY - baselineDistance;
      textPainter.paint(canvas, Offset(cx, yOffset));
      return;
    }

    final fillPaint = Paint()
      ..color = clefColor
      ..style = PaintingStyle.fill;

    final headRadius = spacing * 0.36;
    canvas.drawCircle(Offset(cx + headRadius, fLineY), headRadius, fillPaint);

    final arch = Path();
    arch.moveTo(cx + headRadius, fLineY - headRadius);
    arch.cubicTo(cx + headRadius + 2.8, line5Y - spacing * 0.25, cx + 11.0, line5Y - spacing * 0.1, cx + 11.5, fLineY + spacing * 0.5);
    arch.cubicTo(cx + 11.8, fLineY + spacing * 1.6, cx + 7.0, fLineY + spacing * 2.2, cx + 1.8, fLineY + spacing * 2.3);
    arch.lineTo(cx + 1.6, fLineY + spacing * 2.1);
    arch.cubicTo(cx + 5.5, fLineY + spacing * 1.9, cx + 9.2, fLineY + spacing * 1.3, cx + 9.2, fLineY + spacing * 0.5);
    arch.cubicTo(cx + 9.0, line5Y + spacing * 0.15, cx + 4.6, line5Y + spacing * 0.05, cx + headRadius, fLineY + 0.2);
    arch.close();
    canvas.drawPath(arch, fillPaint);

    final dotX = cx + 14.0;
    final dotRadius = spacing * 0.20;
    canvas.drawCircle(Offset(dotX, fLineY - spacing * 0.5), dotRadius, fillPaint);
    canvas.drawCircle(Offset(dotX, fLineY + spacing * 0.5), dotRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _GrandStaffPainter oldDelegate) {
    return oldDelegate.activeMidi != activeMidi ||
        oldDelegate.preferSharp != preferSharp ||
        oldDelegate.keySignature != keySignature ||
        oldDelegate.activeRange != activeRange ||
        oldDelegate.isDark != isDark;
  }
}
