import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

/// 最近一次子级音区 Chip 成功接收拖拽的时间戳 (用于彻底阻断向父级排卡片冒泡触发二次置换)
int _lastChipDropTimestamp = 0;

/// 音区对象列表管理抽屉
class RangeManagerSheet extends StatelessWidget {
  const RangeManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final isDark = AppTheme.isDark(context);

    final cardBg = isDark ? const Color(0xFF1E2230) : const Color(0xFFF7F8FA);
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    // 获取黑键侧各排（按 trackOrder 升序：远离键盘 ➔ 靠近键盘）
    final blackLanes = state.getLanesForSide(true);
    // 获取白键侧各排（按 trackOrder 升序：靠近键盘 ➔ 远离键盘）
    final whiteLanes = state.getLanesForSide(false);

    // 组合为全局严格展示排序列：黑键侧所有排在前，白键侧所有排在后
    final List<_DisplayLaneItem> displayLanes = [];
    int globalIdx = 0;
    for (int i = 0; i < blackLanes.length; i++) {
      displayLanes.add(_DisplayLaneItem(
        isBlackSide: true,
        indexInSide: i,
        totalInSide: blackLanes.length,
        globalIndex: globalIdx++,
        ranges: blackLanes[i],
      ));
    }
    for (int j = 0; j < whiteLanes.length; j++) {
      displayLanes.add(_DisplayLaneItem(
        isBlackSide: false,
        indexInSide: j,
        totalInSide: whiteLanes.length,
        globalIndex: globalIdx++,
        ranges: whiteLanes[j],
      ));
    }

    final hasCustomGroups = state.userRanges.any((r) => r.trackGroupId != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部导航与快捷操作栏
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 4),
              Tooltip(
                message: '长按卡片可拖拽合并无重叠音区；拖到具体音区上可交替置换（支持跨侧）；使用箭头可上下调整排顺序',
                child: Icon(Icons.help_outline_rounded, size: 14, color: AppTheme.textTertiary(context)),
              ),
              const Spacer(),

              // 右侧操作按钮组 (保存预设、载入预设、重置分轨，完整展示无遮挡)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 一键恢复智能分轨
                  if (hasCustomGroups) ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => state.resetAllTrackGroups(),
                      child: const Text('重置分轨', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // 保存预设
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showSavePresetDialog(context, state),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 13),
                    label: const Text('保存预设', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),

                  // 载入预设
                  if (state.userPresetNames.isNotEmpty) ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showLoadPresetDialog(context, state),
                      icon: const Icon(Icons.folder_open_outlined, size: 13),
                      label: Text('载入(${state.userPresetNames.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // 关闭小图标
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppTheme.textTertiary(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 多排紧凑流式卡片列表 (严格按照黑键侧远离➔靠近、白键侧靠近➔远离排列)
          Expanded(
            child: ListView.separated(
              shrinkWrap: false,
              itemCount: displayLanes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final laneInfo = displayLanes[index];
                final trackRanges = laneInfo.ranges;
                final isBlackSide = laneInfo.isBlackSide;

                return DragTarget<VocalRangeItem>(
                  onWillAcceptWithDetails: (details) {
                    final dragged = details.data;
                    if (trackRanges.any((r) => r.id == dragged.id)) return false;

                    // 1. 若当前排仅有单个音区，支持直接作为整排与该音区进行交替置换 (Swap)
                    if (trackRanges.length == 1) {
                      if (state.canSwapRanges(dragged.id, trackRanges.first.id)) {
                        return true;
                      }
                    } else {
                      // 2. 若当前排具有复数个音区元素，只要排内存在至少一个满足置换条件的音区，即接受拖拽
                      if (trackRanges.any((r) => state.canSwapRanges(dragged.id, r.id))) {
                        return true;
                      }
                    }

                    // 3. 检查是否满足同侧合并至同一排
                    return dragged.canShareTrackWithAll(trackRanges);
                  },
                  onAcceptWithDetails: (details) {
                    final now = DateTime.now().millisecondsSinceEpoch;
                    if ((now - _lastChipDropTimestamp) < 250) {
                      // 本次 Drop 已被排内具体的子级音区 Chip 精准接收并处理，外层排卡片安全跳过，防止二次置换串扰
                      return;
                    }
                    final dragged = details.data;
                    if (trackRanges.isEmpty) return;

                    // 1. 若当前排仅有单个音区且满足交替置换条件，优先执行整排交替置换 (Swap)
                    if (trackRanges.length == 1 && state.canSwapRanges(dragged.id, trackRanges.first.id)) {
                      final targetItem = trackRanges.first;
                      final success = state.trySwapRanges(dragged.id, targetItem.id);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已将 [${dragged.name}] 与 [${targetItem.name}] 成功交替置换！'),
                            duration: const Duration(milliseconds: 1400),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    // 2. 若当前排有复数个音区，若松手在卡片空白处，智能与首个满足置换条件的音区置换
                    if (trackRanges.length > 1) {
                      final swappable = trackRanges.where((r) => state.canSwapRanges(dragged.id, r.id)).toList();
                      if (swappable.isNotEmpty) {
                        final targetItem = swappable.first;
                        final success = state.trySwapRanges(dragged.id, targetItem.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已将 [${dragged.name}] 与 [${targetItem.name}] 成功交替置换！'),
                              duration: const Duration(milliseconds: 1400),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }
                    }

                    // 3. 否则执行同侧合并至该排
                    if (dragged.canShareTrackWithAll(trackRanges)) {
                      final success = state.tryMergeRangesToSameTrack(dragged.id, trackRanges.first.id);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已将 [${dragged.name}] 合并至第 ${laneInfo.globalIndex + 1} 排 (${isBlackSide ? '黑键侧' : '白键侧'})'),
                            duration: const Duration(milliseconds: 1200),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isCandidate = candidateData.isNotEmpty && candidateData.first != null;
                    final candidateItem = isCandidate ? candidateData.first! : null;

                    // 识别当前悬停状态属于“置换”还是“合并”
                    final hasSwappableInLane = isCandidate &&
                        candidateItem != null &&
                        trackRanges.any((r) => state.canSwapRanges(candidateItem.id, r.id));
                    final isMergeCandidate = isCandidate &&
                        candidateItem != null &&
                        candidateItem.canShareTrackWithAll(trackRanges);

                    Color trackBorderColor = cardBorder;
                    Color trackContainerBg = cardBg;

                    if (hasSwappableInLane) {
                      // 亮金色高光：表示排内支持音区交替置换！
                      trackBorderColor = const Color(0xFFFFB300);
                      trackContainerBg = const Color(0xFFFFB300).withValues(alpha: isDark ? 0.16 : 0.08);
                    } else if (isMergeCandidate) {
                      // 亮青色高光：表示整排放下即可合并排道！
                      trackBorderColor = const Color(0xFF00E5FF);
                      trackContainerBg = const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.15 : 0.08);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: trackContainerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: trackBorderColor,
                          width: (hasSwappableInLane || isMergeCandidate) ? 1.5 : 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 排号与黑白键侧向徽章 + 上下移动按钮组
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isBlackSide ? const Color(0xFF16202E) : const Color(0xFF282015))
                                  : (isBlackSide ? const Color(0xFFE6F7FA) : const Color(0xFFFFF9E6)),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isBlackSide
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                                    : const Color(0xFFFFB300).withValues(alpha: 0.5),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '排${laneInfo.globalIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isBlackSide ? const Color(0xFF00E5FF) : const Color(0xFFFFB300),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: isBlackSide
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                                        : const Color(0xFFFFB300).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    isBlackSide ? '黑键侧' : '白键侧',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: isBlackSide ? const Color(0xFF00E5FF) : const Color(0xFFFFB300),
                                    ),
                                  ),
                                ),
                                if (hasSwappableInLane) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB300),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      '⇄ 交换',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                                if (laneInfo.totalInSide > 1) ...[
                                  const SizedBox(width: 2),
                                  InkWell(
                                    onTap: laneInfo.indexInSide > 0
                                        ? () => state.swapLaneOrder(isBlackSide: isBlackSide, indexA: laneInfo.indexInSide, indexB: laneInfo.indexInSide - 1)
                                        : null,
                                    child: Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 14,
                                      color: laneInfo.indexInSide > 0
                                          ? (isBlackSide ? const Color(0xFF00E5FF) : const Color(0xFFFFB300))
                                          : AppTheme.textTertiary(context).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: laneInfo.indexInSide < laneInfo.totalInSide - 1
                                        ? () => state.swapLaneOrder(isBlackSide: isBlackSide, indexA: laneInfo.indexInSide, indexB: laneInfo.indexInSide + 1)
                                        : null,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: laneInfo.indexInSide < laneInfo.totalInSide - 1
                                          ? (isBlackSide ? const Color(0xFF00E5FF) : const Color(0xFFFFB300))
                                          : AppTheme.textTertiary(context).withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 排内音区胶囊列表 (同一排内的音区横向并排呈现)
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: trackRanges.map((range) {
                                final isActive = state.activeRange?.id == range.id;
                                final isVisible = range.isVisible;

                                Widget buildRangeChip() {
                                  return Container(
                                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF141722) : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive ? range.color : range.color.withValues(alpha: 0.35),
                                        width: isActive ? 1.2 : 0.6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 拖动手柄
                                        Icon(
                                          Icons.drag_indicator_rounded,
                                          size: 13,
                                          color: AppTheme.textTertiary(context),
                                        ),
                                        const SizedBox(width: 2),

                                        // 显隐快捷切换
                                        InkWell(
                                          onTap: () => state.toggleRangeVisibility(range.id),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Icon(
                                              isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                              size: 13,
                                              color: isVisible ? range.color : AppTheme.textTertiary(context),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 3),

                                        // 音区名称与音域范围
                                        InkWell(
                                          onTap: () => state.selectRange(range),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                range.name,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isActive ? range.color : AppTheme.textPrimary(context),
                                                ),
                                              ),
                                              Text(
                                                ' ${range.formatRangeLabel(state.octaveNotation)}',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: range.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 3),

                                        // 试听按钮
                                        InkWell(
                                          onTap: () => state.previewRange(range),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
                                            child: Icon(Icons.play_circle_outline_rounded, size: 14, color: range.color),
                                          ),
                                        ),

                                        // 键盘微调按钮
                                        InkWell(
                                          onTap: () {
                                            state.startEditingExistingRange(range);
                                            Navigator.pop(context);
                                          },
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
                                            child: Icon(Icons.tune_rounded, size: 13, color: Color(0xFFFFB300)),
                                          ),
                                        ),

                                        // 删除按钮
                                        InkWell(
                                          onTap: () => state.deleteRange(range.id),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
                                            child: Icon(Icons.close_rounded, size: 13, color: AppTheme.textTertiary(context)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final draggableChip = LongPressDraggable<VocalRangeItem>(
                                  delay: const Duration(milliseconds: 150),
                                  data: range,
                                  dragAnchorStrategy: pointerDragAnchorStrategy,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF141722),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: range.color, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: range.color.withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${range.name} (${range.formatRangeLabel(state.octaveNotation)})',
                                        style: TextStyle(
                                          color: range.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.35,
                                    child: buildRangeChip(),
                                  ),
                                  child: buildRangeChip(),
                                );

                                // 音区元素级拖拽目标：支持与满足替换无冲突条件的音区直接交替置换 (Swap)
                                return DragTarget<VocalRangeItem>(
                                  onWillAcceptWithDetails: (details) {
                                    final dragged = details.data;
                                    if (dragged.id == range.id) return false;
                                    return state.canSwapRanges(dragged.id, range.id);
                                  },
                                  onAcceptWithDetails: (details) {
                                    _lastChipDropTimestamp = DateTime.now().millisecondsSinceEpoch;
                                    final dragged = details.data;
                                    if (dragged.id != range.id) {
                                      final success = state.trySwapRanges(dragged.id, range.id);
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('已将 [${dragged.name}] 与 [${range.name}] 成功交替置换！'),
                                            duration: const Duration(milliseconds: 1400),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  builder: (context, swapCandidates, swapRejections) {
                                    final isSwapCandidate = swapCandidates.isNotEmpty && swapCandidates.first != null;
                                    final isSwapRejected = swapRejections.isNotEmpty && swapRejections.first != null;

                                    if (isSwapCandidate) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFB300).withValues(alpha: 0.7),
                                              blurRadius: 10,
                                              spreadRadius: 1.5,
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            draggableChip,
                                            Positioned(
                                              top: 1,
                                              right: 2,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFB300),
                                                  borderRadius: BorderRadius.circular(3),
                                                  boxShadow: const [
                                                    BoxShadow(color: Colors.black26, blurRadius: 2),
                                                  ],
                                                ),
                                                child: const Text(
                                                  '⇄ 交换',
                                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (isSwapRejected) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFF2A6D), width: 1.5),
                                        ),
                                        child: draggableChip,
                                      );
                                    }
                                    return draggableChip;
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 底部极简拉条指示
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 弹出保存预设对话框 (现代高级卡片质感)
  void _showSavePresetDialog(BuildContext context, VocalMasterState state) {
    final controller = TextEditingController(text: '我的自定义音区预设');
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFF00E5FF), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '保存为预设',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppTheme.textTertiary(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 当前音区配置预览卡片
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDF2F7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '包含 ${state.userRanges.length} 个音区对象',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 音区色彩微圆点序列 (弹性防溢出)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: state.userRanges.map((r) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: r.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: r.color.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 80),
                                child: Text(
                                  r.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: r.color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 预设名称输入框
              Text(
                '预设名称',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: '预设名称',
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textTertiary(context)),
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 底部动作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary(context),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 12.5)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('保存预设', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        state.saveCurrentRangesAsPreset(name);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已成功保存预设: $name'),
                            backgroundColor: const Color(0xFF00E5FF),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹出载入预设对话框 (现代卡片列表质感)
  void _showLoadPresetDialog(BuildContext context, VocalMasterState state) {
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Container(
          width: 380,
          constraints: const BoxConstraints(maxHeight: 460),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFFFFB300), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '载入音区预设库',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppTheme.textTertiary(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 预设列表
              if (state.userPresetNames.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 36, color: AppTheme.textTertiary(context)),
                      const SizedBox(height: 8),
                      Text(
                        '暂无已保存的预设',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textTertiary(context)),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.userPresetNames.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final name = state.userPresetNames[i];
                      final presetRanges = state.userPresets[name] ?? [];

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  state.loadPreset(name);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('已成功载入预设: $name'),
                                      backgroundColor: const Color(0xFF00E5FF),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary(context),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${presetRanges.length}个音区',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF00E5FF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    // 预设内音区色彩圆点序列
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: presetRanges.map((r) {
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: r.color,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 载入按钮
                            TextButton.icon(
                              icon: const Icon(Icons.file_download_outlined, size: 15),
                              label: const Text('载入', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00E5FF),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 28),
                              ),
                              onPressed: () {
                                state.loadPreset(name);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已成功载入预设: $name'),
                                    backgroundColor: const Color(0xFF00E5FF),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),

                            // 删除预设按钮
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent),
                              tooltip: '删除此预设',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                state.deletePreset(name);
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary(context),
                  ),
                  child: const Text('关闭', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 排展示元数据模型（严格对齐黑键侧远离➔靠近、白键侧靠近➔远离的空间流向）
class _DisplayLaneItem {
  final bool isBlackSide;
  final int indexInSide;
  final int totalInSide;
  final int globalIndex;
  final List<VocalRangeItem> ranges;

  _DisplayLaneItem({
    required this.isBlackSide,
    required this.indexInSide,
    required this.totalInSide,
    required this.globalIndex,
    required this.ranges,
  });
}
