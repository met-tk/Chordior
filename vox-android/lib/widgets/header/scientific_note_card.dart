import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../core/music_theory.dart';
import '../../state/vocal_master_state.dart';

/// 规范科学记谱卡片 (Scientific Note Card)
/// 左侧自适应布局设计：与右侧五线谱水平并列，垂直空间按比例饱满分布
/// 1. 规范科学音名 ($C_4$, $C^\sharp_4$, $D^\flat_4$，升降号与八度严格垂直对齐)
/// 2. 国际唱名 (Do, Re, Mi...) 与日本流行片假名唱名 (ド, レ, ミ...)
/// 3. 日本传统固定音名 (ハ, 嬰ハ, ニ, 変ホ...) 与等音对齐
/// 4. 空间与缩放全面重分配：主音名与下方 3 大副音名元素均支持等比缩放并填满卡片空间
class ScientificNoteCard extends StatelessWidget {
  final int midi;
  final bool preferSharp;
  final VoidCallback onToggleSharp;
  final double height;

  const ScientificNoteCard({
    super.key,
    required this.midi,
    required this.preferSharp,
    required this.onToggleSharp,
    this.height = 116.0,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final s = AppStrings.of(state.appLanguage);
    final isDark = AppTheme.isDark(context);
    final note = MusicTheory.getFormattedNote(
      midi,
      preferSharp: preferSharp,
      octaveNotation: state.octaveNotation,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 核心音名显示行 (占约 62% 高度)：主音名自适应充满，右侧为升降号切换胶囊
          Expanded(
            flex: 62,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 规范科学记谱主音名 (自适应撑满可用空间，字号上限大幅放宽)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: onToggleSharp,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B202E) : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: note.accidental.isNotEmpty
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                  : (isDark ? Colors.white12 : Colors.black12),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 基音大写字母
                              Text(
                                note.baseNote,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary(context),
                                  letterSpacing: -1.0,
                                  height: 1.0,
                                ),
                              ),

                              // 升降号与八度数字
                              if (note.accidental.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        note.accidental,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF00E5FF),
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${note.octave}',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFB300),
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0, top: 20),
                                  child: Text(
                                    '${note.octave}',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textSecondary(context),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // 升降号优先切换胶囊
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onToggleSharp,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color: (preferSharp ? const Color(0xFF00E5FF) : const Color(0xFF7C4DFF))
                            .withValues(alpha: isDark ? 0.20 : 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (preferSharp ? const Color(0xFF00E5FF) : const Color(0xFF7C4DFF))
                              .withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        preferSharp ? s.preferSharpLabel : s.preferFlatLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: preferSharp ? const Color(0xFF00E5FF) : const Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // 2. 底部第二行 (占约 38% 高度)：国际唱名 + 日本片假名唱名 + 日本传统固定音名
          // 使用 FittedBox(fit: BoxFit.contain) 确保随高度与缩放等比放大，饱满填满卡片下部
          Expanded(
            flex: 38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 国际唱名胶囊
                    _buildSubChip(
                      text: note.solfege,
                      color: const Color(0xFF7C4DFF),
                      textColor: const Color(0xFFB388FF),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),

                    // 日本片假名唱名徽章 (ドレミファソラシ)
                    _buildSubChip(
                      text: note.japaneseSolfege,
                      color: const Color(0xFF00E5FF),
                      textColor: const Color(0xFF00E5FF),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),

                    // 日本传统固定音名徽章 (和名：绯红色 #FF2A6D)
                    _buildSubChip(
                      text: note.japaneseTraditionalNote,
                      color: const Color(0xFFFF2A6D),
                      textColor: const Color(0xFFFF2A6D),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自适应副音名胶囊
  Widget _buildSubChip({
    required String text,
    required Color color,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }
}
