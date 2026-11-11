import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chordior_flutter/audio/audio_synth.dart';
import 'package:chordior_flutter/state/app_state.dart';

/// 设置中心屏：声部连接策略、八度移调、扫弦与演奏模式、发声音色与主音量
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final synth = AudioSynth.instance;
    final isDark = appState.isDarkMode;
    final cardBg = isDark ? const Color(0xFF141A28) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF242E42) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF475569);
    final subText = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E17) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('设置中心 (Settings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary)),
        backgroundColor: isDark ? const Color(0xFF111524) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: isDark ? '切换至明亮模式' : '切换至深色模式',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: const Color(0xFF38BDF8)),
            onPressed: () => appState.toggleThemeMode(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 声部连接策略 (Voice-Leading Strategy)
          _buildSectionHeader('🎼 声部连接策略 (Voicing Strategy)'),
          Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildRadioTile(
                    title: 'Voice-Leading Compact',
                    subtitle: '平滑紧凑+周期向心收缩回归 (推荐，防止声部过高漂移)',
                    value: 'Voice-Leading Compact',
                    groupValue: appState.voicingStrategy,
                    onChanged: (val) => appState.setVoicingStrategy(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Voice-Leading Guided',
                    subtitle: '以一前一后和弦声部最小移动为平滑导向',
                    value: 'Voice-Leading Guided',
                    groupValue: appState.voicingStrategy,
                    onChanged: (val) => appState.setVoicingStrategy(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Tonic-Root Base',
                    subtitle: '主和弦最低基准 (主调I级最沉稳，其他级数顺延向上)',
                    value: 'Tonic-Root Base',
                    groupValue: appState.voicingStrategy,
                    onChanged: (val) => appState.setVoicingStrategy(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Key-Anchored',
                    subtitle: '调式主音锚定阶梯排列 (按主音音阶台阶排列)',
                    value: 'Key-Anchored',
                    groupValue: appState.voicingStrategy,
                    onChanged: (val) => appState.setVoicingStrategy(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Strict Root',
                    subtitle: '严格原位基础排列 (最纯粹单调递增原位三度叠置)',
                    value: 'Strict Root',
                    groupValue: appState.voicingStrategy,
                    onChanged: (val) => appState.setVoicingStrategy(val!),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. 八度移调功能 (Octave Transposition)
          _buildSectionHeader('🎹 八度移调 (Octave Transposition)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('移调幅度:', style: TextStyle(color: textSecondary, fontSize: 13)),
                    Text(
                      appState.octaveShift == 0
                          ? '标准原位 (0)'
                          : (appState.octaveShift > 0 ? '+${appState.octaveShift} 个八度' : '${appState.octaveShift} 个八度'),
                      style: const TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [-2, -1, 0, 1, 2].map((shift) {
                    final isSel = (appState.octaveShift == shift);
                    final label = shift == 0 ? '0 标准' : (shift > 0 ? '+$shift' : '$shift');
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => appState.setOctaveShift(shift),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSel ? const Color(0xFF38BDF8) : cardBorder,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSel ? Colors.white : textSecondary,
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. 演奏模式 (含扫弦模式)
          _buildSectionHeader('🎸 演奏模式 (Performance Mode)'),
          Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildRadioTile(
                    title: 'Simultaneous (柱式齐奏)',
                    subtitle: '和弦各音同时齐奏发声，气势磅礴',
                    value: 'Simultaneous',
                    groupValue: appState.playMode,
                    onChanged: (val) => appState.setPlayMode(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Pop Strum (流行轻扫弦 - ${appState.strumSpeedMs}ms)',
                    subtitle: '模拟真实吉他或键盘下扫弦，极富现场律动感',
                    value: 'Pop Strum',
                    groupValue: appState.playMode,
                    onChanged: (val) => appState.setPlayMode(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Arp Up (向上分解琶音)',
                    subtitle: '从最低音至最高音依次逐音错开分解发声',
                    value: 'Arp Up',
                    groupValue: appState.playMode,
                    onChanged: (val) => appState.setPlayMode(val!),
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildRadioTile(
                    title: 'Arp Down (向下分解琶音)',
                    subtitle: '从最高音至最低音依次下行分解发声',
                    value: 'Arp Down',
                    groupValue: appState.playMode,
                    onChanged: (val) => appState.setPlayMode(val!),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          if (appState.playMode == 'Pop Strum') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '扫弦速度间隔 (Strum Speed)',
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${appState.strumSpeedMs} 毫秒 (默认35ms)',
                        style: const TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: appState.strumSpeedMs.toDouble(),
                    min: 15,
                    max: 90,
                    divisions: 15,
                    activeColor: const Color(0xFF0284C7),
                    inactiveColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    onChanged: (val) {
                      appState.setStrumSpeedMs(val.round());
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('15ms (极速切弦)', style: TextStyle(color: subText, fontSize: 11)),
                        Text('35ms (标准流行)', style: TextStyle(color: subText, fontSize: 11)),
                        Text('90ms (慵懒慢扫)', style: TextStyle(color: subText, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 4. 音色选择预制 (支持 7 种高保真乐器音色，点击瞬时刷新)
          _buildSectionHeader('🎹 发声音色预制 (Timbre Presets)'),
          Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Acoustic Guitar',
                    desc: '原声木吉他 (清脆透亮拨弦，7级泛音物理建模 - 推荐)',
                    icon: Icons.music_note,
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Concert Grand',
                    desc: '音乐会大三角钢琴 (浑厚低音与柔润毛毡击弦木质共鸣)',
                    icon: Icons.piano,
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Fender Rhodes',
                    desc: '经典调频电钢琴 (70年代复古温暖晶体管质感)',
                    icon: Icons.album,
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Warm Synth Pad',
                    desc: '温暖氛围合成器 (超宽立体声微失谐梦幻铺底延音)',
                    icon: Icons.waves,
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Church Organ',
                    desc: '宏伟教堂管风琴 (16\'/8\'/4\'/2\' 复合风管持续鸣响)',
                    icon: Icons.church,
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Nylon Guitar',
                    desc: '古典尼龙弦吉他 (高频温润暗沉，指腹触弦木箱共鸣)',
                    icon: Icons.audiotrack,
                    isDark: isDark,
                  ),
                  Divider(color: cardBorder, height: 1),
                  _buildTimbreTile(
                    appState: appState,
                    timbre: 'Celesta & Bells',
                    desc: '钢片琴与音乐盒 (清亮晶莹金属音，空灵梦幻)',
                    icon: Icons.notifications_active,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 5. 主音量
          _buildSectionHeader('🔊 主音量控制 (Master Volume)'),
          StatefulBuilder(
            builder: (context, setVolState) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.volume_down, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    Expanded(
                      child: Slider(
                        value: synth.volume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFF0284C7),
                        inactiveColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        onChanged: (val) {
                          synth.volume = val;
                          setVolState(() {});
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Text(
                      '${(synth.volume * 100).toInt()}%',
                      style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 6. 发声延音时长
          _buildSectionHeader('⏱️ 发声延音时长 (Sustain Duration)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: isDark ? Colors.white60 : const Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${appState.sustainDuration.toStringAsFixed(1)} 秒 (声学指数阻尼自然消隐)',
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      appState.sustainDuration <= 1.2
                          ? '断音/跳音风格'
                          : (appState.sustainDuration >= 3.0 ? '长延音/踏板风格' : '自然弹奏风格'),
                      style: TextStyle(
                        color: appState.sustainDuration <= 1.2
                            ? Colors.amber
                            : (appState.sustainDuration >= 3.0 ? const Color(0xFF0284C7) : textSecondary),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: appState.sustainDuration,
                  min: 0.8,
                  max: 4.0,
                  divisions: 32,
                  activeColor: const Color(0xFF0284C7),
                  inactiveColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  onChanged: (val) {
                    appState.setSustainDuration(val);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.8s (紧凑干脆)', style: TextStyle(color: subText, fontSize: 11)),
                      Text('2.0s (标准自然)', style: TextStyle(color: subText, fontSize: 11)),
                      Text('4.0s (悠长空灵)', style: TextStyle(color: subText, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 7. 换和弦柔和消音 (Auto-Damp Previous Chord)
          _buildSectionHeader('🌊 换和弦平滑阻尼 (Chord Transition Damping)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '换和弦柔和消音 (推荐开启)',
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击新和弦时，对上一个和弦的余音施加 160ms 柔和阻尼淡出，防止不同和弦声音交错堆叠浑浊',
                        style: TextStyle(color: subText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: appState.dampPreviousChord,
                  activeColor: const Color(0xFF0284C7),
                  activeTrackColor: const Color(0xFF0369A1),
                  inactiveThumbColor: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                  inactiveTrackColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    appState.setDampPreviousChord(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 8. 吉他指板根音显示设置 (Guitar Fretboard Roots)
          _buildSectionHeader('🎸 吉他指板根音显示设置 (Guitar Fretboard Roots)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                // 1. 高亮和弦根音
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.radio_button_checked, color: Color(0xFFFB923C), size: 22),
                  title: Text('高亮和弦根音 (Chord Root)', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('选中的和弦根音使用方案专属高亮色醒目标注。关闭后与普通和弦音保持相同颜色。', style: TextStyle(color: subText, fontSize: 11)),
                  value: appState.highlightChordRoot,
                  activeColor: const Color(0xFF0284C7),
                  activeTrackColor: const Color(0xFF0369A1),
                  onChanged: (val) => appState.setHighlightChordRoot(val),
                ),
                Divider(color: cardBorder, height: 1),
                // 2. 高亮调式根音/主音
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 22),
                  title: Text('高亮调式主音 (Scale Tonic)', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('在指板全把位中为当前调式的主音标出专属高光光环，亮度受调式音显色强度调节。', style: TextStyle(color: subText, fontSize: 11)),
                  value: appState.highlightScaleRoot,
                  activeColor: const Color(0xFF0284C7),
                  activeTrackColor: const Color(0xFF0369A1),
                  onChanged: (val) => appState.setHighlightScaleRoot(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 9. 乐器视觉排版与配色方案 (来自原项目色彩与显示功能)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('🎨 乐器视觉与色彩方案 (Instrument Visual & Colors)'),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('恢复默认配色', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  appState.resetColorScheme(appState.colorScheme);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已恢复 [ ${appState.colorScheme} ] 为官方默认色彩'),
                      duration: const Duration(milliseconds: 700),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 缩放比例
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('乐器视图缩放比例 (Zoom)', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${(appState.instrumentZoom * 100).round()}%', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('缩小可一次性看完整把吉他指板与多达36个琴键，且降低垂直高度提升排版效率', style: TextStyle(color: subText, fontSize: 11)),
                Slider(
                  value: appState.instrumentZoom,
                  min: 0.3,
                  max: 1.2,
                  divisions: 18,
                  activeColor: const Color(0xFF0284C7),
                  inactiveColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  onChanged: (val) => appState.setInstrumentZoom(val),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildZoomButton(appState, 0.35, '35% 全景宽屏', isDark),
                    _buildZoomButton(appState, 0.65, '65% 紧凑便携', isDark),
                    _buildZoomButton(appState, 1.0, '100% 标准大键盘', isDark),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: cardBorder, height: 1),
                const SizedBox(height: 16),

                // 2. 调式音显色强度
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('调式音显色强度 (Scale Notes Glow)', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${(appState.scaleGlowIntensity * 100).round()}%', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('同步控制琴键弱光底衬、指板调式音及调式主音的柔和显色对比度', style: TextStyle(color: subText, fontSize: 11)),
                Slider(
                  value: appState.scaleGlowIntensity,
                  min: 0.2,
                  max: 1.0,
                  divisions: 8,
                  activeColor: const Color(0xFF0284C7),
                  inactiveColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  onChanged: (val) => appState.setScaleGlowIntensity(val),
                ),

                const SizedBox(height: 16),
                Divider(color: cardBorder, height: 1),
                const SizedBox(height: 14),

                // 3. 配色方案预设与自定义入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('配色方案预设 (Color Schemes)', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('点击色块可自定义颜色', style: TextStyle(color: subText, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildSchemeOption(
                      context: context,
                      appState: appState,
                      schemeName: 'Sky Blue & Gold',
                      label: '经典天蓝与香槟金 (原版默认高光)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildSchemeOption(
                      context: context,
                      appState: appState,
                      schemeName: 'Cyber Neon',
                      label: '赛博霓虹 (电光青翠绿与洋红粉)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildSchemeOption(
                      context: context,
                      appState: appState,
                      schemeName: 'Luxury Gold',
                      label: '奢华黑金 (典雅亮金与赤红橙)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildSchemeOption(
                      context: context,
                      appState: appState,
                      schemeName: 'Violet Sunset',
                      label: '紫罗兰境 (落日深紫与明流金)',
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // 4. 当前选中配色方案的 5 色自定义卡片
                _buildActiveSchemeCustomizer(context, appState, isDark),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 底部弱化显色的制作者署名
          Center(
            child: Text(
              'AI-driven by: taketo',
              style: TextStyle(
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildZoomButton(AppState appState, double zoom, String label, bool isDark) {
    final isSelected = ((appState.instrumentZoom - zoom).abs() < 0.04);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? const Color(0xFF0284C7) : (isDark ? Colors.white70 : const Color(0xFF475569)),
        side: BorderSide(color: isSelected ? const Color(0xFF0284C7) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        backgroundColor: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.15) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        textStyle: const TextStyle(fontSize: 11),
      ),
      onPressed: () => appState.setInstrumentZoom(zoom),
      child: Text(label),
    );
  }

  Widget _buildSchemeOption({
    required BuildContext context,
    required AppState appState,
    required String schemeName,
    required String label,
    required bool isDark,
  }) {
    final isSelected = (appState.colorScheme == schemeName);
    final colors = appState.getSchemeColors(schemeName);

    return InkWell(
      onTap: () => appState.setColorScheme(schemeName),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1A2234) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0284C7)
                : (isDark ? const Color(0xFF242E42) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[0], shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[1], shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[2], shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[3], shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[4], shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF0284C7)),
          ],
        ),
      ),
    );
  }

  /// 构建当前选中配色方案的 5 块颜色自定义卡片
  Widget _buildActiveSchemeCustomizer(BuildContext context, AppState appState, bool isDark) {
    final colors = appState.getSchemeColors(appState.colorScheme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D121D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '当前方案自定义: ${appState.colorScheme}',
                style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => appState.resetColorScheme(appState.colorScheme),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      const SizedBox(width: 2),
                      Text('重置此方案', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildColorTile(
                  context: context,
                  appState: appState,
                  title: '和弦主色',
                  color: colors[0],
                  index: 0,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildColorTile(
                  context: context,
                  appState: appState,
                  title: '调式底色',
                  color: colors[1],
                  index: 1,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildColorTile(
                  context: context,
                  appState: appState,
                  title: '调内重叠',
                  color: colors[2],
                  index: 2,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildColorTile(
                  context: context,
                  appState: appState,
                  title: '和弦根音高亮',
                  color: colors[3],
                  index: 3,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildColorTile(
                  context: context,
                  appState: appState,
                  title: '调式主音高亮',
                  color: colors[4],
                  index: 4,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorTile({
    required BuildContext context,
    required AppState appState,
    required String title,
    required Color color,
    required int index,
    required bool isDark,
  }) {
    final hexString = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return InkWell(
      onTap: () => _showColorPickerDialog(context, appState, appState.colorScheme, index, color, title, isDark),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A28) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? const Color(0xFF283248) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              hexString,
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹出自定义颜色拾取器对话框
  void _showColorPickerDialog(
    BuildContext context,
    AppState appState,
    String schemeName,
    int colorIndex,
    Color currentColor,
    String colorTitle,
    bool isDark,
  ) {
    // 24 种极具音乐与乐器视觉高级感的调色板候选
    const palette = [
      Color(0xFF38BDF8), Color(0xFF0EA5E9), Color(0xFF0284C7), Color(0xFF06B6D4),
      Color(0xFF10B981), Color(0xFF22C55E), Color(0xFF14B8A6), Color(0xFF84CC16),
      Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFF97316), Color(0xFFEF4444),
      Color(0xFFF43F5E), Color(0xFFEC4899), Color(0xFFD946EF), Color(0xFFA855F7),
      Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFFE2E8F0),
      Color(0xFFCBD5E1), Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFFFFFFFF),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF151926) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            '自定义 $colorTitle',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '方案: $schemeName',
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: palette.map((col) {
                    final isCurrent = (col.value == currentColor.value);
                    return InkWell(
                      onTap: () {
                        appState.updateCustomColor(schemeName, colorIndex, col);
                        Navigator.pop(dialogCtx);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            width: isCurrent ? 2.8 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: col.withValues(alpha: 0.4),
                              blurRadius: isCurrent ? 8 : 4,
                            ),
                          ],
                        ),
                        child: isCurrent ? Icon(Icons.check, size: 18, color: isDark ? Colors.white : Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('取消', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final isSelected = (value == groupValue);
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.12) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF0284C7) : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimbreTile({
    required AppState appState,
    required String timbre,
    required String desc,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = (appState.timbre == timbre);
    return InkWell(
      onTap: () {
        appState.setTimbre(timbre);
      },
      child: Container(
        color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.12) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0284C7) : (isDark ? Colors.white60 : const Color(0xFF64748B)), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timbre,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0284C7), size: 19)
            else
              Icon(Icons.circle_outlined, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), size: 19),
          ],
        ),
      ),
    );
  }
}
