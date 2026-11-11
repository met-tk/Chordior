import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/vocal_master_state.dart';
import '../../models/trainer_models.dart';
import '../../core/music_theory.dart';

/// 琶音练习控制面板组件 (自适应明暗双主题，优化基音与BPM空间分配，全多语言支持)
class SingAlongControllerView extends StatelessWidget {
  const SingAlongControllerView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final s = state.strings;
    final rootNote = MusicTheory.getFormattedNote(
      state.trainerRootMidi,
      preferSharp: state.preferSharps,
      octaveNotation: state.octaveNotation,
    );
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：曲目预设下拉 + 紧凑型基音调节胶囊 + 建议发声母音
          Row(
            children: [
              const Icon(Icons.music_note_rounded, color: Color(0xFF00E5FF), size: 17),
              const SizedBox(width: 6),
              // 曲目模板下拉 (根据字符串长度动态自适应字号 + FittedBox 缩放，彻底消除文字被遮挡截断)
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.trainerPattern.id,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: AppTheme.cardBg(context),
                    selectedItemBuilder: (BuildContext ctx) {
                      return TrainerPattern.presets.map((p) {
                        final title = s.trainerPatternTitle(p.id, p.title);
                        final fontSize = (title.length <= 8)
                            ? 12.5
                            : (title.length <= 13)
                                ? 11.2
                                : (title.length <= 18)
                                    ? 10.0
                                    : 8.8;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(ctx),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: TrainerPattern.presets.map((p) {
                      final title = s.trainerPatternTitle(p.id, p.title);
                      final fontSize = (title.length <= 8)
                          ? 12.5
                          : (title.length <= 13)
                              ? 11.2
                              : (title.length <= 18)
                                  ? 10.0
                                  : 8.8;
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found = TrainerPattern.presets.firstWhere((p) => p.id == id);
                        state.setTrainerPattern(found);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 紧凑基音胶囊：自适应防溢出
              Flexible(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (state.trainerRootMidi > 36) {
                            state.setTrainerRootMidi(state.trainerRootMidi - 1);
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Icon(Icons.chevron_left_rounded, size: 15, color: AppTheme.textSecondary(context)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${s.rootNote}:${rootNote.displayName}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (state.trainerRootMidi < 80) {
                            state.setTrainerRootMidi(state.trainerRootMidi + 1);
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Icon(Icons.chevron_right_rounded, size: 15, color: AppTheme.textSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 建议母音标签：自适应防挤压
              Flexible(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.5)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${s.suggestedVowel}:${state.trainerPattern.vocalVowel}',
                      style: TextStyle(
                        fontSize: 10.0,
                        color: isDark ? const Color(0xFFD1C4E9) : const Color(0xFF5E35B1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 第二行：全宽广阔 BPM 速度滑块 + 播放/暂停控制大按钮
          Row(
            children: [
              // BPM 速度调节区 (获得广阔拉伸空间，彻底消除挤压)
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      child: Text(
                        '${state.trainerBpm} BPM',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: const Color(0xFF00E5FF),
                          inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                          thumbColor: const Color(0xFF00E5FF),
                        ),
                        child: Slider(
                          value: state.trainerBpm.toDouble(),
                          min: 50,
                          max: 130,
                          onChanged: (v) => state.setTrainerBpm(v.round()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 播放 / 暂停按钮 (文案按需求改为"播放"/"暂停"，多语言联动)
              ElevatedButton.icon(
                icon: Icon(
                  state.isPlayingTrainer ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 17,
                ),
                label: Text(
                  state.isPlayingTrainer ? s.pause : s.play,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isPlayingTrainer ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                onPressed: () {
                  if (state.isPlayingTrainer) {
                    state.stopTrainer();
                  } else {
                    state.startTrainer();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
