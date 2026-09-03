import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chordior_flutter/core/theory_engine.dart';
import 'package:chordior_flutter/state/app_state.dart';
import 'package:chordior_flutter/widgets/circle_of_fifths_view.dart';
import 'package:chordior_flutter/widgets/guitar_view.dart';
import 'package:chordior_flutter/widgets/piano_view.dart';

/// 调式罗盘屏：自适应 7 个顺阶和弦 + 和弦深度切换 + 左右双列调式全量匹配 + 嵌入式乐器 + 右上角五度圈与和弦自选器
class CompassScreen extends StatelessWidget {
  const CompassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final harmonics = appState.currentHarmonics;
    final matchedScales = appState.matchingScales;
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E17) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appState.currentChordName.isEmpty ? '未选和弦' : appState.currentChordName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                Text(
                  appState.currentKey == 'None'
                      ? '未选调式'
                      : '${appState.currentKey} ${appState.currentMode.split('(').first.trim()}',
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            // 上方中间左边按键：用来播放当前所选择的和弦组成音 (纯图标，与右侧保持一致)
            IconButton(
              icon: Icon(
                Icons.play_circle_fill_rounded,
                size: 26,
                color: appState.currentChordNotes.isEmpty
                    ? (isDark ? Colors.white24 : const Color(0xFFCBD5E1))
                    : const Color(0xFF38BDF8),
              ),
              tooltip: '播放当前所选和弦组成音',
              visualDensity: VisualDensity.compact,
              onPressed: appState.currentChordNotes.isEmpty
                  ? null
                  : () => appState.playCurrentChord(),
            ),
            const SizedBox(width: 4),
            // 上方中间右边按键：用来清除所选择的所有音 (纯图标，与右侧保持一致)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                size: 25,
                color: Color(0xFFF87171),
              ),
              tooltip: '清除所选择的所有音 (包括和弦音与调式音)',
              visualDensity: VisualDensity.compact,
              onPressed: () => appState.clearAllSelectedNotes(),
            ),
            const Spacer(),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF111524) : Colors.white,
        elevation: 0,
        actions: [
          // 1. 右上角乐器插入切换按钮：单键在 3 状态中循环切换 (仅钢琴 -> 仅吉他 -> 钢琴+吉他)
          IconButton(
            icon: Icon(
              appState.instrumentInsertMode == 'guitar'
                  ? Icons.music_note
                  : (appState.instrumentInsertMode == 'both' ? Icons.layers : Icons.piano),
              color: const Color(0xFF38BDF8),
            ),
            tooltip: '乐器视图: ${_getInsertModeLabel(appState.instrumentInsertMode == 'none' ? 'piano' : appState.instrumentInsertMode)} (点击直接切换)',
            onPressed: () {
              final nextMode = switch (appState.instrumentInsertMode) {
                'piano' => 'guitar',
                'guitar' => 'both',
                _ => 'piano',
              };
              appState.setInstrumentInsertMode(nextMode);
            },
          ),
          // 2. 自选和弦根音与类型按钮
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF38BDF8)),
            tooltip: '自选和弦 (根音/类型)',
            onPressed: () => _showChordSelectorSheet(context, appState),
          ),
          // 3. 将当前和弦添加到工坊
          IconButton(
            icon: Icon(Icons.playlist_add, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            tooltip: '加入和弦工坊',
            onPressed: () {
              appState.addCurrentChordToProgression();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已将 ${appState.currentChordName} 添加到工坊'),
                  duration: const Duration(milliseconds: 900),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // 1. 顺阶和弦控制头部：标题 + 和弦深度选择胶囊 (三和弦 / 七和弦 / 九和弦)
          Row(
            children: [
              Text(
                '顺阶和弦 (${harmonics.length}个)',
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildDepthChip(appState, 'Triad', '三和弦 (3音)', isDark),
              const SizedBox(width: 4),
              _buildDepthChip(appState, '7th', '七和弦 (4音)', isDark),
              const SizedBox(width: 4),
              _buildDepthChip(appState, '9th', '九和弦 (5音)', isDark),
            ],
          ),

          const SizedBox(height: 8),

          // 2. 顺阶和弦行：一次性展示所有顺阶和弦（无需横向滑动，自适应平铺）
          _buildAllHarmonicsRow(context, appState, harmonics, isDark),

          // 3. 动态插入乐器区域 (插入在顺阶和弦与所属调式之间)
          if (appState.instrumentInsertMode != 'none') ...[
            const SizedBox(height: 10),
            // 顶部乐器视图工具栏：标题与缩放控制
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appState.instrumentInsertMode == 'both'
                            ? '🎹 钢琴键盘 + 🎸 吉他指板'
                            : (appState.instrumentInsertMode == 'guitar' ? '🎸 6弦21品吉他指板' : '🎹 48键大钢琴键盘'),
                        style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '已选 ${appState.selectedPianoIndices.length} 音',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10),
                      ),
                    ],
                  ),
                  // 缩放控制器：支持缩小以看到更多琴键/品格并节约垂直高度
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in, size: 14, color: Colors.white38),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () => appState.setInstrumentZoom(appState.instrumentZoom - 0.1),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.remove, size: 14, color: Color(0xFF38BDF8)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${(appState.instrumentZoom * 100).round()}%',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () => appState.setInstrumentZoom(appState.instrumentZoom + 0.1),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.add, size: 14, color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (appState.instrumentInsertMode == 'piano' || appState.instrumentInsertMode == 'both') ...[
              PianoView(
                selectedIndices: appState.selectedPianoIndices,
                scalePitchClasses: appState.currentScalePitchClasses,
                onKeyToggled: appState.togglePianoKey,
                zoom: appState.instrumentZoom,
                chordColor: appState.chordColor,
                scaleColor: appState.scaleColor,
                bothAccentColor: appState.bothAccentColor,
                scaleGlowIntensity: appState.scaleGlowIntensity,
              ),
              const SizedBox(height: 8),
            ],
            if (appState.instrumentInsertMode == 'guitar' || appState.instrumentInsertMode == 'both') ...[
              GuitarView(
                selectedIndices: appState.selectedPianoIndices,
                scalePitchClasses: appState.currentScalePitchClasses,
                rootPitchClass: appState.currentRootPitchClass,
                scaleRootPitchClass: appState.currentScaleRootPitchClass,
                highlightChordRoot: appState.highlightChordRoot,
                highlightScaleRoot: appState.highlightScaleRoot,
                onFretToggled: appState.toggleGuitarFret,
                zoom: appState.instrumentZoom,
                chordColor: appState.chordColor,
                scaleColor: appState.scaleColor,
                bothAccentColor: appState.bothAccentColor,
                chordRootColor: appState.chordRootColor,
                scaleRootColor: appState.scaleRootColor,
                scaleGlowIntensity: appState.scaleGlowIntensity,
              ),
              const SizedBox(height: 8),
            ],
          ],

          Divider(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), height: 22),

          // 3. 所属可能调式标题栏：左侧精简标题 + 五度圈调式罗盘入口 + 分组模式切换 (按主音 / 按调式)
          Row(
            children: [
              Expanded(
                child: Text(
                  '[ ${appState.currentChordName.isEmpty ? "未选和弦" : appState.currentChordName} ] 所属调式可能',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 五度圈调式罗盘按钮 (移动至按主音/按调式左侧，节省顶部空间并贴合调式功能)
              InkWell(
                onTap: () => _showCircleOfFifthsSheet(context, appState),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141A28) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF283042) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.album_outlined, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        '五度圈',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 分组切换胶囊
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141A28) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF283042) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    _buildGroupTab(
                      label: '按主音',
                      isSelected: appState.scaleGroupingMode == 'byRoot',
                      onTap: () => appState.setGroupingMode('byRoot'),
                    ),
                    _buildGroupTab(
                      label: '按调式',
                      isSelected: appState.scaleGroupingMode == 'byMode',
                      onTap: () => appState.setGroupingMode('byMode'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. 水平切一刀划分为左右双列区域 (Two-Column Split Layout)，极大提升单次展示量
          if (matchedScales.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '未找到包含当前选音的调式音阶',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            )
          else if (appState.scaleGroupingMode == 'byRoot')
            _buildSplitByRootView(context, appState, matchedScales, isDark)
          else
            _buildSplitByModeView(context, appState, matchedScales, isDark),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 顺阶和弦深度切换 Chip
  // --------------------------------------------------------------------------
  Widget _buildDepthChip(AppState appState, String depth, String label, bool isDark) {
    final isSelected = (appState.harmonicDepth == depth);
    return GestureDetector(
      onTap: () => appState.setHarmonicDepth(depth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : (isDark ? const Color(0xFF161B29) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : (isDark ? const Color(0xFF283042) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 一次性展示所有顺阶和弦 (最多7个，自适应Row平铺，无需横向滚动)
  // --------------------------------------------------------------------------
  Widget _buildAllHarmonicsRow(
    BuildContext context,
    AppState appState,
    List<HarmonicDegreeInfo> harmonics,
    bool isDark,
  ) {
    if (harmonics.isEmpty) return const SizedBox.shrink();

    return Row(
      children: harmonics.map((h) {
        final isSelected = (h.name == appState.currentChordName);

        return Expanded(
          child: GestureDetector(
            onTap: () => appState.selectHarmonicChord(h),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.20)
                    : (isDark ? const Color(0xFF161B29) : Colors.white),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : (isDark ? const Color(0xFF283042) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.8 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 罗马数字级数
                  Text(
                    h.roman,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 和弦名称
                  Text(
                    h.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: harmonics.length > 7 ? 10 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 构成音 (清晰圆点分隔，避免黏连)
                  Text(
                    h.notes.join(' · '),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 8.0,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // 左右双列分区：按主音分组 (By Root)
  // --------------------------------------------------------------------------
  Widget _buildSplitByRootView(
    BuildContext context,
    AppState appState,
    List<MatchedScaleInfo> matchedList,
    bool isDark,
  ) {
    // 聚合分组
    final Map<String, List<MatchedScaleInfo>> groups = {};
    for (final item in matchedList) {
      groups.putIfAbsent(item.root, () => []).add(item);
    }

    final groupEntries = groups.entries.toList();
    final leftGroups = <MapEntry<String, List<MatchedScaleInfo>>>[];
    final rightGroups = <MapEntry<String, List<MatchedScaleInfo>>>[];

    // 左右交替切分
    for (int i = 0; i < groupEntries.length; i++) {
      if (i % 2 == 0) {
        leftGroups.add(groupEntries[i]);
      } else {
        rightGroups.add(groupEntries[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRootColumn(context, appState, leftGroups, isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildRootColumn(context, appState, rightGroups, isDark)),
      ],
    );
  }

  Widget _buildRootColumn(
    BuildContext context,
    AppState appState,
    List<MapEntry<String, List<MatchedScaleInfo>>> groupList,
    bool isDark,
  ) {
    return Column(
      children: groupList.map((entry) {
        final root = entry.key;
        final items = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131724) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF222B3D) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分组头部
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181F30) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    Text(
                      '🎵 $root 调',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length}个',
                      style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
              // 调式项目
              ...items.map((item) {
                final isCurrentScale = (item.root == appState.currentKey && item.mode == appState.currentMode);
                final modeColor = _parseModeColor(item.colorHex);
                final modeClean = item.mode.split('(').first.trim();

                return InkWell(
                  onTap: () {
                    appState.selectMatchedScale(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E2638).withValues(alpha: 0.5) : const Color(0xFFE2E8F0))),
                      color: isCurrentScale ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.10) : null,
                    ),
                    child: Row(
                      children: [
                        // 顺阶级数徽章
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: modeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: modeColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            item.degree.isNotEmpty ? item.degree : '顺阶',
                            style: TextStyle(color: modeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 调式名 (严格遵循原项目色彩体系)
                        Expanded(
                          child: Text(
                            modeClean,
                            style: TextStyle(
                              color: modeColor,
                              fontSize: 11,
                              fontWeight: isCurrentScale ? FontWeight.bold : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // 左右双列分区：按调式分组 (By Mode)
  // --------------------------------------------------------------------------
  Widget _buildSplitByModeView(
    BuildContext context,
    AppState appState,
    List<MatchedScaleInfo> matchedList,
    bool isDark,
  ) {
    final Map<String, List<MatchedScaleInfo>> groups = {};
    for (final item in matchedList) {
      groups.putIfAbsent(item.mode, () => []).add(item);
    }

    final groupEntries = groups.entries.toList();
    final leftGroups = <MapEntry<String, List<MatchedScaleInfo>>>[];
    final rightGroups = <MapEntry<String, List<MatchedScaleInfo>>>[];

    for (int i = 0; i < groupEntries.length; i++) {
      if (i % 2 == 0) {
        leftGroups.add(groupEntries[i]);
      } else {
        rightGroups.add(groupEntries[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildModeColumn(context, appState, leftGroups, isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildModeColumn(context, appState, rightGroups, isDark)),
      ],
    );
  }

  Widget _buildModeColumn(
    BuildContext context,
    AppState appState,
    List<MapEntry<String, List<MatchedScaleInfo>>> groupList,
    bool isDark,
  ) {
    return Column(
      children: groupList.map((entry) {
        final mode = entry.key;
        final items = entry.value;
        final modeColor = _parseModeColor(items.first.colorHex);
        final modeClean = mode.split('(').first.trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131724) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF222B3D) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分组头部
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181F30) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🎼 $modeClean',
                        style: TextStyle(color: modeColor, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${items.length}个',
                      style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
              // 主音与级数列表
              ...items.map((item) {
                final isCurrentScale = (item.root == appState.currentKey && item.mode == appState.currentMode);

                return InkWell(
                  onTap: () {
                    appState.selectMatchedScale(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E2638).withValues(alpha: 0.5) : const Color(0xFFE2E8F0))),
                      color: isCurrentScale ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.10) : null,
                    ),
                    child: Row(
                      children: [
                        // 主音徽章
                        Container(
                          width: 28,
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF232B3E) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            item.root.split('/').first,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 级数与调式色彩文字
                        Expanded(
                          child: Text(
                            '${item.degree.isNotEmpty ? item.degree : ""} 级和弦',
                            style: TextStyle(
                              color: modeColor,
                              fontSize: 10.5,
                              fontWeight: isCurrentScale ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _parseModeColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF38BDF8);
    }
  }

  // --------------------------------------------------------------------------
  // 弹窗 1：五度圈罗盘底部抽屉 (释放纵向空间)
  // --------------------------------------------------------------------------
  void _showCircleOfFifthsSheet(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111524) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.album_outlined, color: Color(0xFF0284C7), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '五度圈调式罗盘 (${appState.currentKey} ${appState.isMinor ? "小调" : "大调"})',
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 310,
                      child: CircleOfFifthsView(
                        currentKey: appState.currentKey,
                        isMinor: appState.isMinor,
                        onKeyChanged: (key) {
                          appState.setKey(key, isMinor: appState.isMinor);
                          setSheetState(() {});
                        },
                        onMinorChanged: (isMinor) {
                          appState.setKey(appState.currentKey, isMinor: isMinor);
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // 弹窗 2：自选和弦 (根音 + 和弦类型) 抽屉
  // --------------------------------------------------------------------------
  void _showChordSelectorSheet(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    const rootNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final categories = ['全部', ...kChordCategories.keys];

    String selectedRoot = appState.currentChordNotes.isNotEmpty ? appState.currentChordNotes.first.split('/').first : 'C';
    String selectedType = 'Maj';
    String selectedCategory = '全部';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111524) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // 根据分类筛选和弦列表
            final List<ChordDef> displayChords = [];
            if (selectedCategory == '全部') {
              for (final list in kChordCategories.values) {
                displayChords.addAll(list);
              }
            } else {
              displayChords.addAll(kChordCategories[selectedCategory] ?? []);
            }

            final notes = getChordNotes(selectedRoot, selectedType);

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部把手与标题
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '自选和弦与调式反查 (42种和弦库)',
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text('1. 选择根音 (Root):', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  // 12 个根音选择网格
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: rootNotes.map((r) {
                        final isSel = (r == selectedRoot);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(r),
                            selected: isSel,
                            selectedColor: const Color(0xFF0284C7),
                            backgroundColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setSheetState(() {
                                selectedRoot = r;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),
                  // 和弦类别切换 Tab
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2. 和弦类型分类 (Type):', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${displayChords.length} 种和弦', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSel = (cat == selectedCategory);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: const Color(0xFF0284C7),
                            backgroundColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setSheetState(() {
                                selectedCategory = cat;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // 和弦类型网格 (42 种完整和弦，带中文描述)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141926) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF222B3D) : const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: displayChords.map((chordDef) {
                            final isSel = (chordDef.name == selectedType);
                            return Tooltip(
                              message: '${chordDef.name}: ${chordDef.description}',
                              child: ChoiceChip(
                                label: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chordDef.name,
                                      style: TextStyle(
                                        color: isSel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      chordDef.description,
                                      style: TextStyle(
                                        color: isSel ? Colors.white70 : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSel,
                                selectedColor: const Color(0xFF0284C7),
                                backgroundColor: isDark ? const Color(0xFF1A2234) : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSel ? const Color(0xFF0284C7) : (isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                onSelected: (_) {
                                  setSheetState(() {
                                    selectedType = chordDef.name;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                    // 实时预览与确认设置按钮
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF182032) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF283248) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$selectedRoot $selectedType',
                                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '构成音: ${notes.join(" - ")}',
                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('确定选定', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              appState.setChordByRootAndType(selectedRoot, selectedType);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已设定为 $selectedRoot $selectedType 并开始反查调式'),
                                  duration: const Duration(milliseconds: 800),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
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

  String _getInsertModeLabel(String mode) {
    switch (mode) {
      case 'piano':
        return '仅插入钢琴键盘';
      case 'guitar':
        return '仅插入吉他指板';
      case 'both':
        return '同时插入钢琴与吉他';
      default:
        return '隐藏乐器视图';
    }
  }
}
