import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/vocal_master_state.dart';

/// 从屏幕顶部向下滑出的抽屉窗口 (Top Sheet)
/// 纵向长度实时根据钢琴窗口的纵向空间（由分割滑块驱动）与屏幕总空间相减计算，
/// 严格停在钢琴键盘上方，零遮挡钢琴窗口
Future<T?> showTopSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double? maxHeight,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'TopSheet',
    barrierColor: Colors.black.withValues(alpha: 0.40),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Consumer<VocalMasterState>(
        builder: (dialogCtx, state, _) {
          final media = MediaQuery.of(dialogCtx);
          // 1. 实时计算钢琴窗口上方区域的纵向全局坐标
          final pianoTop = state.pianoTopY;
          // 备用兜底计算（若首次尚未完成 RenderBox 测量时）
          final fallbackPianoTop = media.padding.top + state.headerHeight + 12.0;
          final effectivePianoTop = pianoTop ?? fallbackPianoTop;

          // 2. 根据高度模式计算音区管理窗口的纵向长度
          double targetHeight;
          if (state.rangeManagerHeightMode == 'custom') {
            // 用户在设置项中指定的自定义固定比例
            targetHeight = (media.size.height * state.rangeManagerCustomRatio)
                .clamp(140.0, media.size.height * 0.90);
          } else {
            // 自动模式（推荐）：直接把管理窗口的长度拉到钢琴窗口上方纵向坐标！
            // 窗口自顶部 SafeArea 边距开始向下延伸，其下边缘精确停在 effectivePianoTop，
            // 包含用户在设置项中的像素级微调偏移量
            final calculatedHeight = effectivePianoTop - media.padding.top + state.rangeManagerHeightOffset;
            targetHeight = (maxHeight ?? calculatedHeight)
                .clamp(120.0, media.size.height * 0.90);
          }

          return SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 780, // 平板与桌面端限制最大宽度，居中呈现
                ),
                child: SizedBox(
                  height: targetHeight,
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: builder(dialogCtx),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}
