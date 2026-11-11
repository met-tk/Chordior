import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/vocal_master_state.dart';
import 'scientific_note_card.dart';
import 'grand_staff_painter.dart';

/// 顶部第一大区块：紧凑型信息显示区块 (水平单行集成科学音名与大谱表五线谱)
/// 特性：
/// 1. 左侧 38% 宽度展示规范记谱卡片（基音、升降号八度垂直对齐、唱名频率，内嵌当前音区微胶囊）
/// 2. 右侧 62% 宽度展示大谱表矢量五线谱（矢量高低音谱号、当前音区最低/最高音与当前音）
/// 3. 单行水平 Row 紧凑排布，大幅释放 100px+ 黄金垂直空间给下方键盘
/// 4. 完美支持全局明暗双主题无缝自适应
class InfoHeaderWidget extends StatelessWidget {
  final VoidCallback onOpenRangeManager;
  final VoidCallback onOpenSettings;

  const InfoHeaderWidget({
    super.key,
    required this.onOpenRangeManager,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final isDark = AppTheme.isDark(context);
    final s = AppStrings.of(state.appLanguage);

    return Container(
      color: isDark ? const Color(0xFF0F1117) : const Color(0xFFEAEFF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部轻量状态条 (品牌标识、横竖排快速切换、外观模式切换、设置入口)
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00E5FF),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFFB388FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'Vox',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 0.8),
                    ),
                    child: const Text(
                      'v1.4',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00E5FF),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 外观明暗模式快捷切换
              IconButton(
                icon: Icon(
                  state.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18,
                  color: state.isDarkMode ? const Color(0xFFFFB300) : const Color(0xFF5C6BC0),
                ),
                tooltip: state.isDarkMode ? s.switchToLightMode : s.switchToDarkMode,
                onPressed: () => state.toggleThemeMode(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              const SizedBox(width: 4),

              // 界面右上角纯齿轮设置按钮 (不带任何文字，防误触)
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  size: 19,
                  color: AppTheme.textSecondary(context),
                ),
                tooltip: s.settingsTooltip,
                onPressed: onOpenSettings,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // ================= 核心水平集成区块 (Row) =================
          // 左侧：科学音名 + 唱名 + 和名
          // 右侧：大谱表矢量五线谱
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final leftFlex = isNarrow ? 44 : 38;
              final rightFlex = 100 - leftFlex;

              final contentHeight = (state.headerHeight - 43.0).clamp(50.0, 275.0);

              return SizedBox(
                height: contentHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 左侧音名卡片 (自适应弹性宽度)
                    Expanded(
                      flex: leftFlex,
                      child: ScientificNoteCard(
                        midi: state.trainerNoteHighlight ?? state.currentMidi,
                        preferSharp: state.preferSharps,
                        onToggleSharp: () => state.togglePreferSharps(),
                        height: contentHeight,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 右侧大谱表矢量五线谱
                    Expanded(
                      flex: rightFlex,
                      child: GrandStaffView(
                        activeMidi: state.currentMidi,
                        preferSharp: state.preferSharps,
                        keySignature: state.keySignature,
                        onKeySignatureChanged: (key) => state.setKeySignature(key),
                        highlightTrainerMidi: state.trainerNoteHighlight,
                        activeRange: state.activeRange,
                        height: contentHeight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
