import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chordior_flutter/core/harmonic_presets.dart';
import 'package:chordior_flutter/state/app_state.dart';

/// 和弦工坊屏：和弦进行编排、拍数分配、BPM试听、拖拽重排、全局同步与预设存取
class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  /// 保存当前进行为预设弹窗
  void _showSavePresetDialog(BuildContext context, AppState appState) {
    if (appState.progression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前和弦进行为空，无法保存'),
          duration: Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: '我的和弦进行 ${appState.userPresets.length + 1}',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = appState.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141A28) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            '保存和弦进行为预设',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('请输入预设名称:', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9),
                  hintText: '例如：流行抒情 4536251',
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '包含 ${appState.progression.length} 个和弦 (${appState.progression.map((c) => c.label).join(" ➔ ")})',
                style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  appState.saveCurrentProgressionAsPreset(name);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已成功保存预设: $name'),
                      duration: const Duration(milliseconds: 900),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  /// 载入预设弹窗（支持用户自定义预设与经典预设）
  void _showPresetsDialog(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141A28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allPresets = [...appState.userPresets, ...kProgressionPresets];

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '和弦进行预设库 (含用户自定义)',
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: allPresets.length,
                      separatorBuilder: (_, _) => Divider(color: isDark ? const Color(0xFF242E42) : const Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final p = allPresets[index];
                        final isUser = p.category.contains('User');

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isUser ? Icons.bookmark : Icons.library_music,
                            color: isUser ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
                          ),
                          title: Text(
                            p.name,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${p.category} • ${p.bpm} BPM\n${p.chords.map((c) => c.label).join(" - ")}',
                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isUser) ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  tooltip: '删除此预设',
                                  onPressed: () {
                                    appState.deleteUserPreset(p);
                                    setModalState(() {});
                                  },
                                ),
                                const SizedBox(width: 4),
                              ],
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  appState.loadPreset(p);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('载入'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E17) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '和弦工坊 (${appState.progression.length} 个和弦)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        backgroundColor: isDark ? const Color(0xFF111524) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            tooltip: isDark ? '切换至明亮模式' : '切换至深色模式',
            onPressed: () => appState.toggleThemeMode(),
          ),
          // 保存为自定义预设
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFFF59E0B)),
            tooltip: '保存当前进行为预设',
            onPressed: () => _showSavePresetDialog(context, appState),
          ),
          // 载入预设库
          IconButton(
            icon: const Icon(Icons.library_music, color: Color(0xFF38BDF8)),
            tooltip: '载入预设库',
            onPressed: () => _showPresetsDialog(context, appState),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. 和弦卡片时间轴列表 (修复默认手柄重叠，使用独立左侧手柄拖拽)
          Expanded(
            child: appState.progression.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.queue_music, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          '工坊进行暂无和弦',
                          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '在“调式罗盘”或“乐器探索”中点击加号添加',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () => _showPresetsDialog(context, appState),
                          icon: const Icon(Icons.library_music, size: 16),
                          label: const Text('从预设库中载入'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false, // 彻底关闭系统在最右侧注入的默认拖动手柄，杜绝重叠！
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: appState.progression.length,
                    onReorder: appState.reorderProgression,
                    itemBuilder: (context, index) {
                      final chord = appState.progression[index];
                      final isPlaying = (appState.isPlaying && appState.currentPlayingIndex == index);

                      return Container(
                        key: ValueKey('chord_$index'),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.20)
                              : (isDark ? const Color(0xFF161B29) : Colors.white),
                          border: Border.all(
                            color: isPlaying
                                ? const Color(0xFF0284C7)
                                : (isDark ? const Color(0xFF283042) : const Color(0xFFE2E8F0)),
                            width: isPlaying ? 2.0 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isPlaying
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // 独立左侧拖动手柄 (带专属监听器，手感流畅且与右侧按钮零干扰)
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2536) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.drag_indicator, color: isDark ? Colors.white54 : const Color(0xFF64748B), size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 序号徽章
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF232B3E) : const Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 和弦名与音符
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chord.label,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    chord.notes.join(' · '),
                                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // 拍数选择器 (Beats)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF232B3E) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButton<int>(
                                value: chord.beats,
                                underline: const SizedBox(),
                                dropdownColor: isDark ? const Color(0xFF1E2333) : Colors.white,
                                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w600),
                                items: [1, 2, 3, 4].map((b) {
                                  return DropdownMenuItem<int>(
                                    value: b,
                                    child: Text('$b 拍'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    appState.updateChordBeats(index, val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),

                            // 单张试听按钮 (兼具全局同步到其他界面)
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline, color: Color(0xFF0284C7), size: 22),
                              tooltip: '试听并同步为当前和弦',
                              onPressed: () {
                                appState.selectChordCardItem(chord);
                              },
                            ),

                            // 独立删除按钮
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: isDark ? Colors.white38 : const Color(0xFF94A3B8), size: 20),
                              tooltip: '从工坊中移除',
                              onPressed: () => appState.removeChordFromProgression(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 2. 底部常驻试听控制器面板 (Bottom Playback Console)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111524) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // BPM 速度调节滑块
                  Row(
                    children: [
                      const Text('BPM', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${appState.bpm}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: appState.bpm.toDouble(),
                          min: 40,
                          max: 240,
                          activeColor: const Color(0xFF0284C7),
                          inactiveColor: const Color(0xFF334155),
                          onChanged: (val) => appState.setBpm(val.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white60, size: 18),
                        onPressed: () => appState.setBpm(appState.bpm - 2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white60, size: 18),
                        onPressed: () => appState.setBpm(appState.bpm + 2),
                      ),
                    ],
                  ),

                  // 循环播放主控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appState.isPlaying ? const Color(0xFFE11D48) : const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          if (appState.isPlaying) {
                            appState.stopPlayback();
                          } else {
                            appState.startPlayback();
                          }
                        },
                        icon: Icon(appState.isPlaying ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          appState.isPlaying ? '停止播放' : '循环试听进行',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
