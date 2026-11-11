import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

/// 选中音区对象详情卡片组件 (防溢出弹性排版)
class ActiveRangeCard extends StatelessWidget {
  final VocalRangeItem? activeRange;
  final VoidCallback onPreview;
  final VoidCallback onManageRanges;

  const ActiveRangeCard({
    super.key,
    required this.activeRange,
    required this.onPreview,
    required this.onManageRanges,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final s = AppStrings.of(state.appLanguage);

    if (activeRange == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141722),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 15, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              s.clickOrDragToSelectRange,
              style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    final range = activeRange!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: range.color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: range.color.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：色彩标识、名称、起止跨度、试听跟唱按钮
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: range.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: range.color.withValues(alpha: 0.6), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  range.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: range.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: range.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  range.formatRangeLabel(state.octaveNotation),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: range.color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${range.semitones}${s.semitonesUnit})',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const Spacer(),
              // 试听跟唱按钮
              InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: range.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: range.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 13, color: range.color),
                      const SizedBox(width: 2),
                      Text(
                        s.previewRange,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: range.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 第二行：简短声乐建议 (单行截断，杜绝垂直溢出)
          if (range.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              range.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
