import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/vocal_master_state.dart';
import 'sing_along_controller.dart';

/// 最下方第三大区块：纯净主控制台 (模式切换、键盘缩放与抽屉入口，音源已移入设置项)
class BottomControlDeck extends StatelessWidget {
  final VoidCallback onOpenRangeManager;
  final VoidCallback onOpenSettings;

  const BottomControlDeck({
    super.key,
    required this.onOpenRangeManager,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final isDark = AppTheme.isDark(context);

    final deckBg = isDark ? const Color(0xFF0F1117) : const Color(0xFFEAEFF5);
    final buttonBg = isDark ? const Color(0xFF161922) : Colors.white;
    final buttonBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E0);

    return Container(
      color: deckBg,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 若处于跟唱练声模式，展开专属练声跟唱播放器控制器
          if (state.currentMode == StudioMode.singTrainer) ...[
            const SingAlongControllerView(),
            const SizedBox(height: 6),
          ],

          // 2. 核心三大功能切换栏 (音区划选 / 琶音练习 / 实时聆听)
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  context,
                  icon: Icons.linear_scale_rounded,
                  label: state.strings.rangeSelectMode,
                  isSelected: state.currentMode == StudioMode.rangeSelect,
                  onTap: () => state.toggleMode(StudioMode.rangeSelect),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildModeButton(
                  context,
                  icon: Icons.music_note_rounded,
                  label: state.strings.arpeggioPractice,
                  isSelected: state.currentMode == StudioMode.singTrainer,
                  onTap: () => state.toggleMode(StudioMode.singTrainer),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildModeButton(
                  context,
                  icon: state.isListeningActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                  label: state.isListeningActive ? state.strings.listeningActive : state.strings.listenPitch,
                  isSelected: state.isListeningActive,
                  activeColor: const Color(0xFF00E676),
                  onTap: () => state.toggleListeningMode(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. 底部轻量工具栏：键盘缩放控制组 + 键盘横竖排切换 + 音区管理 + 设置 (自适应防溢出)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 380;
              final itemPadH = isCompact ? 7.0 : 10.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 键盘无极缩放微调组 ([-] 100% [+])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: buttonBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: buttonBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => state.zoomOut(),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(Icons.remove_rounded, size: 15, color: AppTheme.textSecondary(context)),
                              ),
                            ),
                            InkWell(
                              onTap: () => state.resetZoom(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '${(state.keyboardScale * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => state.zoomIn(),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(Icons.add_rounded, size: 15, color: AppTheme.textSecondary(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 键盘横向 / 竖排快速切换
                      InkWell(
                        onTap: () => state.togglePianoOrientation(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: itemPadH, vertical: 6),
                          decoration: BoxDecoration(
                            color: buttonBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: buttonBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                state.pianoOrientation == Axis.horizontal
                                    ? Icons.stay_current_landscape_rounded
                                    : Icons.stay_current_portrait_rounded,
                                size: 15,
                                color: const Color(0xFF00E5FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.pianoOrientation == Axis.horizontal ? state.strings.horizontal : state.strings.vertical,
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 音区管理入口
                      InkWell(
                        onTap: onOpenRangeManager,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: itemPadH, vertical: 6),
                          decoration: BoxDecoration(
                            color: buttonBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: buttonBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.palette_outlined, size: 15, color: Color(0xFF7C4DFF)),
                              const SizedBox(width: 4),
                              Text(
                                state.strings.rangeManagerBtn,
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final isDark = AppTheme.isDark(context);
    final highlightColor = activeColor ?? const Color(0xFF00E5FF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? highlightColor.withValues(alpha: isDark ? 0.16 : 0.12)
              : (isDark ? const Color(0xFF161922) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? highlightColor
                : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFCBD5E0)),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? highlightColor
                  : AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : (activeColor ?? const Color(0xFF007799)))
                    : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
