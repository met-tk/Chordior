import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

/// 钢琴音区多轨道微型色带与重叠呈现组件 (支持横向与竖排双向)
class MultiRangeRibbon extends StatelessWidget {
  final List<VocalRangeItem> ranges;
  final VocalRangeItem? activeRange;
  final int minMidi;
  final int maxMidi;
  final Axis orientation; // 水平或垂直
  final double keyDimension; // 白键宽度 (横向) 或白键高度 (竖向)
  final Function(VocalRangeItem) onSelectRange;

  const MultiRangeRibbon({
    super.key,
    required this.ranges,
    required this.activeRange,
    required this.minMidi,
    required this.maxMidi,
    required this.orientation,
    required this.keyDimension,
    required this.onSelectRange,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    // 仅显示可见音区
    final visibleRanges = ranges.where((r) => r.isVisible).toList();
    if (visibleRanges.isEmpty) return const SizedBox.shrink();

    final isHorizontal = orientation == Axis.horizontal;
    final allocation = RangeLaneAllocation.compute(visibleRanges);
    final totalLanes = allocation.totalLanes;

    // 轨道高度/宽度
    const laneThickness = 14.0;
    const laneSpacing = 3.0;
    final totalThickness = (totalLanes * (laneThickness + laneSpacing)) + 4.0;

    // 按 lane 分组
    final laneList = List.generate(totalLanes, (index) => <VocalRangeItem>[]);
    for (final range in visibleRanges) {
      final laneIdx = allocation.rangeIdToLane[range.id] ?? 0;
      laneList[laneIdx].add(range);
    }

    return Container(
      width: isHorizontal ? null : totalThickness,
      height: isHorizontal ? totalThickness : null,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: isHorizontal
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: laneList.map((laneRanges) => _buildHorizontalLane(laneRanges, state)).toList(),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: laneList.map((laneRanges) => _buildVerticalLane(laneRanges)).toList(),
            ),
    );
  }

  /// 构建横向单条泳道 (可容纳多个无重叠音区)
  Widget _buildHorizontalLane(List<VocalRangeItem> laneRanges, VocalMasterState state) {
    return Container(
      height: 14.0,
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final totalKeys = maxMidi - minMidi + 1;

          return Stack(
            children: laneRanges.map((range) {
              final startRatio = ((range.startMidi - minMidi) / totalKeys).clamp(0.0, 1.0);
              final endRatio = ((range.endMidi - minMidi + 1) / totalKeys).clamp(0.0, 1.0);
              final widthRatio = (endRatio - startRatio).clamp(0.02, 1.0);
              final leftPos = trackWidth * startRatio;
              final barWidth = trackWidth * widthRatio;
              final isActive = activeRange?.id == range.id;

              return Positioned(
                left: leftPos,
                width: barWidth,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => onSelectRange(range),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? range.color.withValues(alpha: 0.85)
                          : range.color.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActive ? Colors.white : range.color.withValues(alpha: 0.7),
                        width: isActive ? 1.5 : 0.8,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: range.color.withValues(alpha: 0.6),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${range.name} (${range.formatRangeLabel(state.octaveNotation)})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.9),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// 构建竖排单条泳道 (可容纳多个无重叠音区，从上到下为高音到低音)
  Widget _buildVerticalLane(List<VocalRangeItem> laneRanges) {
    return Container(
      width: 14.0,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight;
          final totalKeys = maxMidi - minMidi + 1;

          return Stack(
            children: laneRanges.map((range) {
              final topRatio = ((maxMidi - range.endMidi) / totalKeys).clamp(0.0, 1.0);
              final bottomRatio = ((maxMidi - range.startMidi + 1) / totalKeys).clamp(0.0, 1.0);
              final heightRatio = (bottomRatio - topRatio).clamp(0.02, 1.0);
              final topPos = trackHeight * topRatio;
              final barHeight = trackHeight * heightRatio;
              final isActive = activeRange?.id == range.id;

              return Positioned(
                top: topPos,
                height: barHeight,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onSelectRange(range),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? range.color.withValues(alpha: 0.85)
                          : range.color.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActive ? Colors.white : range.color.withValues(alpha: 0.7),
                        width: isActive ? 1.5 : 0.8,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: range.color.withValues(alpha: 0.6),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        range.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.9),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
