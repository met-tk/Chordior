import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/vocal_master_state.dart';

/// 音名五线谱区块与钢琴键盘区块之间的缝隙分割滑块控件 (Split Divider Handle)
///
/// 核心特性：
/// 1. 专业音频工作站 (DAW) 硬件推子质感：居中微型圆角胶囊把手 + 三道精密凹槽雕刻
/// 2. 交互状态反馈：鼠标悬停 (Hover) 与按压拖拽 (Dragging) 呈现青蓝到电紫动态渐变与霓虹外发光
/// 3. 上下平滑拖拽：实时调整上方音名五线谱与下方键盘的垂直空间比例
/// 4. 贴心手势支持：双击 (Double Tap) 快速恢复默认比例
/// 5. 跨平台光标：光标自动切换为 SystemMouseCursors.resizeUpDown
/// 6. 全局明暗双主题无缝适配
class SplitDividerHandle extends StatefulWidget {
  const SplitDividerHandle({super.key});

  @override
  State<SplitDividerHandle> createState() => _SplitDividerHandleState();
}

class _SplitDividerHandleState extends State<SplitDividerHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final isDark = AppTheme.isDark(context);
    final isActive = _isHovered || _isDragging;

    // 导轨背景与线条色彩
    final railColor = isDark
        ? (isActive ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08))
        : (isActive ? const Color(0xFF5C6BC0).withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.08));

    // 胶囊抓手渐变色彩
    final pillDecoration = isActive
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.45 : 0.30),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          )
        : BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.32) : Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(3),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _isDragging = true),
        onVerticalDragUpdate: (details) {
          state.adjustHeaderHeight(details.delta.dy);
        },
        onVerticalDragEnd: (_) => setState(() => _isDragging = false),
        onVerticalDragCancel: () => setState(() => _isDragging = false),
        onDoubleTap: () => state.resetHeaderHeight(),
        child: Tooltip(
          message: '上下拖动调整五线谱与键盘比例 · 双击恢复默认',
          waitDuration: const Duration(milliseconds: 700),
          child: Container(
            height: 12.0,
            width: double.infinity,
            color: isDark ? const Color(0xFF0B0D12) : const Color(0xFFE2E7EE),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 全宽细微导轨分割线 (1px 高)
                Positioned(
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 1.0,
                    color: railColor,
                  ),
                ),

                // 2. 居中 DAW 风格胶囊抓手 (42px 宽, 5.5px 高)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isActive ? 48.0 : 40.0,
                  height: isActive ? 6.0 : 5.0,
                  decoration: pillDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 1.2,
                        height: 3.0,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.85)
                              : (isDark ? Colors.black38 : Colors.white70),
                          borderRadius: BorderRadius.circular(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
