import 'package:flutter/material.dart';

/// 应用程序全局主题规范与色彩令牌系统
class AppTheme {
  // ========================== 暗黑模式颜色 ==========================
  static const Color darkScaffoldBg = Color(0xFF0A0C10);
  static const Color darkCardBg = Color(0xFF141720);
  static const Color darkCardBorder = Color(0xFF232838);
  static const Color darkStaffBg = Color(0xFF0F121A);
  static const Color darkStaffBorder = Color(0xFF262C3E);
  static const Color darkStaffLine = Color(0xFF4A5568);
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF8E9BAE);
  static const Color darkTextTertiary = Color(0xFF5A6678);

  // ========================== 明亮模式颜色 ==========================
  static const Color lightScaffoldBg = Color(0xFFF3F5F9);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightStaffBg = Color(0xFFFAF8F5); // 优雅米白乐谱底纸
  static const Color lightStaffBorder = Color(0xFFE5DECE);
  static const Color lightStaffLine = Color(0xFF718096);
  static const Color lightTextPrimary = Color(0xFF1A202C);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightTextTertiary = Color(0xFF718096);

  // ========================== 品牌强调色 ==========================
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryPurple = Color(0xFF7C4DFF);

  /// 暗黑主题 ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffoldBg,
      primaryColor: primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: secondaryPurple,
        surface: darkCardBg,
      ),
      cardColor: darkCardBg,
      dividerColor: darkCardBorder,
      fontFamily: 'Roboto',
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkCardBorder, width: 1),
        ),
      ),
    );
  }

  /// 明亮主题 ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightScaffoldBg,
      primaryColor: const Color(0xFF0091EA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0091EA),
        secondary: secondaryPurple,
        surface: lightCardBg,
      ),
      cardColor: lightCardBg,
      dividerColor: lightCardBorder,
      fontFamily: 'Roboto',
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: lightCardBg,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightCardBorder, width: 1),
        ),
      ),
    );
  }

  // ========================== 上下文色彩助手 ==========================
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? darkScaffoldBg : lightScaffoldBg;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCardBg : lightCardBg;

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? darkCardBorder : lightCardBorder;

  static Color staffBg(BuildContext context) =>
      isDark(context) ? darkStaffBg : lightStaffBg;

  static Color staffBorder(BuildContext context) =>
      isDark(context) ? darkStaffBorder : lightStaffBorder;

  static Color staffLine(BuildContext context) =>
      isDark(context) ? darkStaffLine : lightStaffLine;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? darkTextTertiary : lightTextTertiary;

  static Color dividerColor(BuildContext context) =>
      isDark(context) ? darkCardBorder : lightCardBorder;
}
