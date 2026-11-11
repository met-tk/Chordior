import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../core/music_theory.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';
import '../../audio/real_audio_engine.dart';

/// 个性化配置与设置抽屉 (支持中日英三语切换，精简排版)
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final s = state.strings;
    final isDark = AppTheme.isDark(context);

    // 内部卡片自适应背景色
    final innerCardBg = isDark ? const Color(0xFF1C202C) : const Color(0xFFF7F8FA);
    final innerCardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶端居中手柄
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Color(0xFF00E5FF), size: 19),
                  const SizedBox(width: 8),
                  Text(
                    s.settingsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary(context)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              key: const Key('settings_list_view'),
              children: [
                // ================= 0. 软件语言切换 (中 / 英 / 日) =================
                _buildSectionHeader(Icons.language_rounded, s.languageTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Row(
                    children: [
                      _buildLanguageOption(
                        context,
                        label: '中文',
                        sub: '简体中文',
                        isSelected: state.appLanguage == AppLanguage.zh,
                        onTap: () => state.setLanguage(AppLanguage.zh),
                        innerCardBorder: innerCardBorder,
                      ),
                      const SizedBox(width: 6),
                      _buildLanguageOption(
                        context,
                        label: 'English',
                        sub: 'EN',
                        isSelected: state.appLanguage == AppLanguage.en,
                        onTap: () => state.setLanguage(AppLanguage.en),
                        innerCardBorder: innerCardBorder,
                      ),
                      const SizedBox(width: 6),
                      _buildLanguageOption(
                        context,
                        label: '日本語',
                        sub: 'JA',
                        isSelected: state.appLanguage == AppLanguage.ja,
                        onTap: () => state.setLanguage(AppLanguage.ja),
                        innerCardBorder: innerCardBorder,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 1. 全局外观主题 (暗黑 / 明亮) =================
                _buildSectionHeader(Icons.palette_outlined, s.themeModeTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => state.setThemeMode(ThemeMode.dark),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: state.isDarkMode
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                  : (isDark ? const Color(0xFF161922) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: state.isDarkMode ? const Color(0xFF00E5FF) : innerCardBorder,
                                width: state.isDarkMode ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.dark_mode_rounded, size: 18, color: Color(0xFF00E5FF)),
                                const SizedBox(width: 6),
                                Text(
                                  s.themeDark,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: state.isDarkMode ? FontWeight.bold : FontWeight.w500,
                                    color: state.isDarkMode ? const Color(0xFF00E5FF) : AppTheme.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => state.setThemeMode(ThemeMode.light),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: !state.isDarkMode
                                  ? const Color(0xFF0091EA).withValues(alpha: 0.16)
                                  : (isDark ? const Color(0xFF161922) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !state.isDarkMode ? const Color(0xFF0091EA) : innerCardBorder,
                                width: !state.isDarkMode ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.light_mode_rounded, size: 18, color: Color(0xFFFFB300)),
                                const SizedBox(width: 6),
                                Text(
                                  s.themeLight,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !state.isDarkMode ? FontWeight.bold : FontWeight.w500,
                                    color: !state.isDarkMode ? const Color(0xFF0091EA) : AppTheme.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 1.1 全局界面与字体比例 (UI Scale) =================
                _buildSectionHeader(Icons.aspect_ratio_rounded, s.uiScaleTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(state.uiScale * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.uiScale == 1.0 ? '(标准 100%)' : (state.uiScale < 1.0 ? '(紧凑)' : '(放大)'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppTheme.textTertiary(context),
                                ),
                              ),
                            ],
                          ),
                          if (state.uiScale != 1.0)
                            InkWell(
                              key: const Key('ui_scale_reset_button'),
                              onTap: () => state.resetUiScale(),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  s.uiScaleReset,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          activeTrackColor: const Color(0xFF00E5FF),
                          inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                          thumbColor: const Color(0xFF00E5FF),
                          overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                        ),
                        child: Slider(
                          value: state.uiScale,
                          min: 0.75,
                          max: 1.30,
                          divisions: 11,
                          onChanged: (val) => state.setUiScale(val),
                        ),
                      ),
                      Text(
                        s.uiScaleHint,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 2. 真实原声乐器音源选择区 =================
                _buildSectionHeader(Icons.music_note_rounded, s.instrumentTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Column(
                    children: RealAudioEngine.instruments.map((inst) {
                      final isSelected = state.currentTimbre == inst.id;
                      final localizedName = s.instrumentName(inst.id, inst.name);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () {
                            state.setTimbre(inst.id);
                            state.onPianoKeyPressed(60);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.12)
                                  : (isDark ? const Color(0xFF161922) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00E5FF) : innerCardBorder,
                                width: isSelected ? 1.4 : 0.6,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    inst.iconData,
                                    size: 15,
                                    color: isSelected ? const Color(0xFF00E5FF) : AppTheme.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    localizedName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF00E5FF) : AppTheme.textPrimary(context),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF00E5FF))
                                else
                                  Icon(Icons.volume_up_outlined, size: 15, color: AppTheme.textTertiary(context)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 2.1 琴键音符防浑浊渐弱 =================
                _buildSectionHeader(Icons.auto_fix_high_rounded, s.voiceDampingTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.voiceDampingTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.voiceDampingDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textTertiary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        key: const Key('voice_damping_switch'),
                        value: state.pianoVoiceDamping,
                        onChanged: (val) => state.setPianoVoiceDamping(val),
                        activeColor: const Color(0xFF00E5FF),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 2.2 人声聆听灵敏度 =================
                _buildSectionHeader(Icons.mic_external_on_rounded, s.listeningSensitivityTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Row(
                    children: [
                      _buildOptionTab(
                        context,
                        label: s.sensitivityHigh,
                        isSelected: state.pitchSensitivity == PitchSensitivity.high,
                        onTap: () => state.setPitchSensitivity(PitchSensitivity.high),
                        innerCardBorder: innerCardBorder,
                      ),
                      const SizedBox(width: 6),
                      _buildOptionTab(
                        context,
                        label: s.sensitivityBalanced,
                        isSelected: state.pitchSensitivity == PitchSensitivity.balanced,
                        onTap: () => state.setPitchSensitivity(PitchSensitivity.balanced),
                        innerCardBorder: innerCardBorder,
                      ),
                      const SizedBox(width: 6),
                      _buildOptionTab(
                        context,
                        label: s.sensitivityNoiseResistant,
                        isSelected: state.pitchSensitivity == PitchSensitivity.noiseResistant,
                        onTap: () => state.setPitchSensitivity(PitchSensitivity.noiseResistant),
                        innerCardBorder: innerCardBorder,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 2.2 琴键发光与余晖效果 =================
                _buildSectionHeader(Icons.auto_awesome_rounded, s.pianoGlowModeTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Row(
                    children: [
                      _buildOptionTab(
                        context,
                        label: s.glowModeInstant,
                        isSelected: state.pianoGlowMode == PianoGlowMode.instant,
                        onTap: () => state.setPianoGlowMode(PianoGlowMode.instant),
                        innerCardBorder: innerCardBorder,
                      ),
                      const SizedBox(width: 6),
                      _buildOptionTab(
                        context,
                        label: s.glowModeFadeOut,
                        isSelected: state.pianoGlowMode == PianoGlowMode.fadeOut,
                        onTap: () => state.setPianoGlowMode(PianoGlowMode.fadeOut),
                        innerCardBorder: innerCardBorder,
                      ),
                      const SizedBox(width: 6),
                      _buildOptionTab(
                        context,
                        label: s.glowModeTrail,
                        isSelected: state.pianoGlowMode == PianoGlowMode.trail,
                        onTap: () => state.setPianoGlowMode(PianoGlowMode.trail),
                        innerCardBorder: innerCardBorder,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 2.4 八度记谱法标准 (SPN vs Yamaha) =================
                _buildSectionHeader(Icons.music_note_rounded, s.octaveNotationTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildOptionTab(
                            context,
                            label: s.octaveNotationSpn,
                            isSelected: state.octaveNotation == OctaveNotation.spn,
                            onTap: () => state.setOctaveNotation(OctaveNotation.spn),
                            innerCardBorder: innerCardBorder,
                          ),
                          const SizedBox(width: 8),
                          _buildOptionTab(
                            context,
                            label: s.octaveNotationYamaha,
                            isSelected: state.octaveNotation == OctaveNotation.yamaha,
                            onTap: () => state.setOctaveNotation(OctaveNotation.yamaha),
                            innerCardBorder: innerCardBorder,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.octaveNotationDesc,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textTertiary(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 3. 钢琴键盘缩放与排布控制 =================
                _buildSectionHeader(Icons.aspect_ratio_rounded, s.keyboardSectionTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Column(
                    children: [
                      // 琴键宽幅缩放
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.horizontalScale, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                          Row(
                            children: [
                              Text(
                                '${(state.keyboardScale * 100).round()}%',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              _buildMiniResetBtn(context, onTap: () => state.resetZoom(), text: s.reset),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: state.keyboardScale,
                        min: 0.65,
                        max: 1.85,
                        divisions: 12,
                        activeColor: const Color(0xFF00E5FF),
                        onChanged: (v) => state.setKeyboardScale(v),
                      ),
                      Divider(color: innerCardBorder, height: 12),

                      // 琴键长薄比例
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.keyLength, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                          Row(
                            children: [
                              Text(
                                '${(state.keyLengthRatio * 100).round()}%',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFFFB300), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              _buildMiniResetBtn(context, onTap: () => state.setKeyLengthRatio(0.60), text: s.reset),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: state.keyLengthRatio,
                        min: 0.30,
                        max: 1.50,
                        divisions: 24,
                        activeColor: const Color(0xFFFFB300),
                        onChanged: (v) => state.setKeyLengthRatio(v),
                      ),
                      Divider(color: innerCardBorder, height: 12),

                      // 新建音区默认方位 (单个紧凑切换胶囊按钮)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.defaultIndicatorSide, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                          InkWell(
                            onTap: () => state.toggleRangeIndicatorPosition(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.14 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    state.rangeIndicatorPosition == RangeIndicatorPosition.blackKeySide
                                        ? Icons.tune_rounded
                                        : Icons.horizontal_distribute_rounded,
                                    size: 13,
                                    color: const Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    state.rangeIndicatorPosition == RangeIndicatorPosition.blackKeySide
                                        ? s.blackKeySide
                                        : s.whiteKeySide,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: innerCardBorder, height: 12),

                      // 分轨开关
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: Text(s.separateRangeTracks, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                          value: state.separateRangeTracks,
                          activeThumbColor: const Color(0xFF00E5FF),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (_) => state.toggleSeparateRangeTracks(),
                        ),
                      ),
                      Divider(color: innerCardBorder, height: 12),

                      // 竖排模式切换
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: Text(
                            state.appLanguage == AppLanguage.zh
                                ? '使用竖排键盘布局'
                                : (state.appLanguage == AppLanguage.ja ? '縦型鍵盤レイアウト' : 'Vertical Piano Layout'),
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                          ),
                          value: state.pianoOrientation == Axis.vertical,
                          activeThumbColor: const Color(0xFF00E5FF),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (_) => state.togglePianoOrientation(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 4. 音区管理窗口纵向长度 =================
                _buildSectionHeader(Icons.vertical_align_bottom_rounded, s.rangeManagerHeightTitle),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.rangeManagerHeightTitle, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                          InkWell(
                            onTap: () => state.toggleRangeManagerHeightMode(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.14 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    state.rangeManagerHeightMode == 'auto'
                                        ? Icons.auto_mode_rounded
                                        : Icons.straighten_rounded,
                                    size: 13,
                                    color: const Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    state.rangeManagerHeightMode == 'auto' ? s.autoFit : s.customHeight,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (state.rangeManagerHeightMode == 'auto') ...[
                        Divider(color: innerCardBorder, height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.offsetFineTune, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                            Row(
                              children: [
                                Text(
                                  '${state.rangeManagerHeightOffset >= 0 ? '+' : ''}${state.rangeManagerHeightOffset.round()} px',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                _buildMiniResetBtn(context, onTap: () => state.setRangeManagerHeightOffset(0.0), text: s.reset),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: state.rangeManagerHeightOffset,
                          min: -80.0,
                          max: 80.0,
                          divisions: 32,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (v) => state.setRangeManagerHeightOffset(v),
                        ),
                      ] else ...[
                        Divider(color: innerCardBorder, height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.screenHeightRatio, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                            Row(
                              children: [
                                Text(
                                  '${(state.rangeManagerCustomRatio * 100).round()}%',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFFFB300), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                _buildMiniResetBtn(context, onTap: () => state.setRangeManagerCustomRatio(0.50), text: s.reset),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: state.rangeManagerCustomRatio,
                          min: 0.30,
                          max: 0.85,
                          divisions: 22,
                          activeColor: const Color(0xFFFFB300),
                          onChanged: (v) => state.setRangeManagerCustomRatio(v),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ================= 5. 音量与记谱偏好 =================
                _buildSectionHeader(
                  Icons.volume_up_rounded,
                  state.appLanguage == AppLanguage.zh
                      ? '音量与记谱偏好'
                      : (state.appLanguage == AppLanguage.ja ? '音量と記譜設定' : 'Volume & Notation'),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: innerCardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.appLanguage == AppLanguage.zh
                                ? '主音量'
                                : (state.appLanguage == AppLanguage.ja ? 'マスター音量' : 'Master Volume'),
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                          ),
                          Text(
                            '${(state.audioVolume * 100).round()}%',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: state.audioVolume,
                        min: 0.1,
                        max: 1.0,
                        activeColor: const Color(0xFF00E5FF),
                        onChanged: (v) => state.setAudioVolume(v),
                      ),
                      Divider(color: innerCardBorder, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.appLanguage == AppLanguage.zh
                                ? '临时记号偏好'
                                : (state.appLanguage == AppLanguage.ja ? '臨時記号' : 'Accidentals'),
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                          ),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('♯', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              ButtonSegment(value: false, label: Text('♭', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                            selected: {state.preferSharps},
                            onSelectionChanged: (set) => state.togglePreferSharps(),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vox v1.4',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-driven by taketo',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textTertiary(context).withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF00E5FF)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
    required Color innerCardBorder,
  }) {
    final isDark = AppTheme.isDark(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.12)
                : (isDark ? const Color(0xFF161922) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : innerCardBorder,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00E5FF) : AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.8) : AppTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTab(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color innerCardBorder,
  }) {
    final isDark = AppTheme.isDark(context);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.12)
                : (isDark ? const Color(0xFF161922) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : innerCardBorder,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00E5FF) : AppTheme.textPrimary(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniResetBtn(BuildContext context, {required VoidCallback onTap, required String text}) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary(context))),
      ),
    );
  }
}
