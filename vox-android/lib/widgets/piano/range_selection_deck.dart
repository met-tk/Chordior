import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/music_theory.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

/// 钢琴键盘上方：音区信息展示与确认操作台 (RangeSelectionDeck)
/// 用户直接在下方钢琴键盘上拖拽实体把手调节范围，此处实时显示参数并提供确认保存操作
class RangeSelectionDeck extends StatefulWidget {
  final VocalMasterState state;
  final VoidCallback onSaveRange;

  const RangeSelectionDeck({
    super.key,
    required this.state,
    required this.onSaveRange,
  });

  @override
  State<RangeSelectionDeck> createState() => _RangeSelectionDeckState();
}

class _RangeSelectionDeckState extends State<RangeSelectionDeck> {
  late TextEditingController _nameController;
  late VocalRangeType _selectedType;
  late Color _selectedColor;
  late RangeIndicatorPosition _selectedPosition;

  static const List<Color> _palette = [
    Color(0xFFFF1744), // 珊瑚绯红
    Color(0xFFFF2A6D), // 极客霓红
    Color(0xFFF50057), // 玫瑰艳红
    Color(0xFFE040FB), // 梦幻洋红
    Color(0xFF7C4DFF), // 深邃星紫
    Color(0xFF651FFF), // 炫彩靛蓝
    Color(0xFF2979FF), // 经典宝蓝
    Color(0xFF00B0FF), // 天空亮蓝
    Color(0xFF00E5FF), // 极光霓青
    Color(0xFF1DE9B6), // 薄荷海青
    Color(0xFF00E676), // 翡翠翠绿
    Color(0xFF76FF03), // 荧光青绿
    Color(0xFFAEEA00), // 青柠炫黄
    Color(0xFFFFEA00), // 纯亮柠檬
    Color(0xFFFFB300), // 琥珀纯金
    Color(0xFFFF6D00), // 活力暖橙
    Color(0xFFFF3D00), // 炽热橙红
    Color(0xFF78909C), // 沉静蓝灰
  ];

  double _startOpacity = 0.70;
  double _endOpacity = 0.05;
  bool _gradientReversed = false;
  VocalRangeItem? _lastEditingRange;
  Timer? _playbackReleaseTimer;

  @override
  void initState() {
    super.initState();
    final editing = widget.state.editingRange;
    _lastEditingRange = editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _selectedType = editing?.type ?? VocalRangeType.custom;
    _selectedColor = editing?.color ?? const Color(0xFF00E5FF);
    _selectedPosition = editing?.indicatorPosition ?? RangeIndicatorPosition.blackKeySide;
    _startOpacity = editing?.startOpacity ?? 0.70;
    _endOpacity = editing?.endOpacity ?? 0.05;
    _gradientReversed = editing?.gradientReversed ?? false;
  }

  @override
  void didUpdateWidget(covariant RangeSelectionDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.editingRange != oldWidget.state.editingRange) {
      final editing = widget.state.editingRange;
      _lastEditingRange = editing;
      _nameController.text = editing?.name ?? '';
      _selectedType = editing?.type ?? VocalRangeType.custom;
      _selectedColor = editing?.color ?? const Color(0xFF00E5FF);
      _selectedPosition = editing?.indicatorPosition ?? RangeIndicatorPosition.blackKeySide;
      _startOpacity = editing?.startOpacity ?? 0.70;
      _endOpacity = editing?.endOpacity ?? 0.05;
      _gradientReversed = editing?.gradientReversed ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _playbackReleaseTimer?.cancel();
    super.dispose();
  }

  /// 弹出自定义起始与终止色彩浓度微调面板
  void _showOpacitySettings(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '渐变起始与终止色彩浓度自定义',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 实时效果预览色条
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            _selectedColor.withValues(alpha: _startOpacity),
                            _selectedColor.withValues(alpha: _startOpacity * 0.5),
                            _selectedColor.withValues(alpha: _endOpacity),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '琴键渐变效果预览: ${(_startOpacity * 100).round()}% ⟶ ${(_endOpacity * 100).round()}%',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 起始色彩浓度滑块
                    Row(
                      children: [
                        Text(
                          '起始端浓度 (强光端): ',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(_startOpacity * 100).round()}%',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _selectedColor),
                        ),
                      ],
                    ),
                    Slider(
                      value: _startOpacity,
                      min: 0.15,
                      max: 1.0,
                      divisions: 17,
                      activeColor: _selectedColor,
                      onChanged: (v) {
                        setSheetState(() => _startOpacity = v);
                        setState(() => _startOpacity = v);
                      },
                    ),

                    // 终止色彩浓度滑块
                    Row(
                      children: [
                        Text(
                          '终止端浓度 (渐隐端): ',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(_endOpacity * 100).round()}%',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _selectedColor),
                        ),
                      ],
                    ),
                    Slider(
                      value: _endOpacity,
                      min: 0.0,
                      max: 0.45,
                      divisions: 9,
                      activeColor: _selectedColor,
                      onChanged: (v) {
                        setSheetState(() => _endOpacity = v);
                        setState(() => _endOpacity = v);
                      },
                    ),

                    const SizedBox(height: 10),
                    // 快捷预设模版
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('高反差 (85% ⟶ 0%)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              _startOpacity = 0.85;
                              _endOpacity = 0.0;
                            });
                            setState(() {
                              _startOpacity = 0.85;
                              _endOpacity = 0.0;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('标准自然 (70% ⟶ 5%)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              _startOpacity = 0.70;
                              _endOpacity = 0.05;
                            });
                            setState(() {
                              _startOpacity = 0.70;
                              _endOpacity = 0.05;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('通透柔和 (50% ⟶ 10%)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              _startOpacity = 0.50;
                              _endOpacity = 0.10;
                            });
                            setState(() {
                              _startOpacity = 0.50;
                              _endOpacity = 0.10;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        if (state.editingRange != _lastEditingRange) {
          _lastEditingRange = state.editingRange;
          final editing = state.editingRange;
          _nameController.text = editing?.name ?? '';
          _selectedType = editing?.type ?? VocalRangeType.custom;
          _selectedColor = editing?.color ?? const Color(0xFF00E5FF);
          _startOpacity = editing?.startOpacity ?? 0.70;
          _endOpacity = editing?.endOpacity ?? 0.05;
          _gradientReversed = editing?.gradientReversed ?? false;
        }

        final isEditing = state.editingRange != null;
        final editingRange = state.editingRange;
        final isDark = AppTheme.isDark(context);

        final startMidi = state.selectionStartMidi ?? 60;
        final endMidi = state.selectionEndMidi ?? 67;

        final lowMidi = startMidi < endMidi ? startMidi : endMidi;
        final highMidi = startMidi > endMidi ? startMidi : endMidi;
        final lowNote = MusicTheory.getFormattedNote(lowMidi, preferSharp: state.preferSharps, octaveNotation: state.octaveNotation);
        final highNote = MusicTheory.getFormattedNote(highMidi, preferSharp: state.preferSharps, octaveNotation: state.octaveNotation);
        final spanText = MusicTheory.calculateRangeSpan(lowMidi, highMidi);

        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < 450;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 14, vertical: isNarrow ? 6 : 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEditing
                  ? _selectedColor.withValues(alpha: 0.7)
                  : const Color(0xFFFFB300).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 第一行：音区名、黑键侧与白键侧的切换按钮、取消与保存按钮（叉和勾）
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 第一项：音区名称输入框
                  SizedBox(
                    width: isNarrow ? 85 : 105,
                    height: 28,
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                      decoration: InputDecoration(
                        hintText: isEditing ? '音区名称' : '新音区名称',
                        hintStyle: TextStyle(fontSize: 11, color: AppTheme.textTertiary(context)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      ),
                    ),
                  ),

                  SizedBox(width: isNarrow ? 5 : 8),

                  // 第二项：黑键侧与白键侧的切换按钮
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPosition = _selectedPosition == RangeIndicatorPosition.blackKeySide
                            ? RangeIndicatorPosition.whiteKeySide
                            : RangeIndicatorPosition.blackKeySide;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: _selectedPosition == RangeIndicatorPosition.blackKeySide
                            ? const Color(0xFF673AB7).withValues(alpha: 0.22)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _selectedPosition == RangeIndicatorPosition.blackKeySide
                              ? const Color(0xFF9C27B0)
                              : const Color(0xFF00E5FF),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedPosition == RangeIndicatorPosition.blackKeySide
                                ? Icons.piano_rounded
                                : Icons.wb_sunny_rounded,
                            size: 13,
                            color: _selectedPosition == RangeIndicatorPosition.blackKeySide
                                ? const Color(0xFFBA68C8)
                                : const Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedPosition == RangeIndicatorPosition.blackKeySide
                                ? '黑键侧 ⇄'
                                : '白键侧 ⇄',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedPosition == RangeIndicatorPosition.blackKeySide
                                  ? const Color(0xFFE1BEE7)
                                  : const Color(0xFF80DEEA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 第三项：取消按钮 (优化为叉号图标)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('range_deck_cancel_button'),
                      onTap: () {
                        if (isEditing) {
                          state.cancelEditingRange();
                        } else {
                          state.clearSelection();
                          state.setMode(StudioMode.freePlay);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12,
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 第四项：保存按钮 (优化为勾号发光保存按钮)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('range_deck_save_button'),
                      onTap: () {
                        if (isEditing) {
                          state.saveEditedRange(
                            name: _nameController.text.trim().isNotEmpty
                                ? _nameController.text.trim()
                                : editingRange!.name,
                            type: _selectedType,
                            color: _selectedColor,
                            indicatorPosition: _selectedPosition,
                            gradientReversed: _gradientReversed,
                            startOpacity: _startOpacity,
                            endOpacity: _endOpacity,
                          );
                        } else {
                          final chosenName = _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : '自定义音区';
                          state.saveCurrentSelectionAsRange(
                            name: chosenName,
                            type: _selectedType,
                            color: _selectedColor,
                            indicatorPosition: _selectedPosition,
                            gradientReversed: _gradientReversed,
                            startOpacity: _startOpacity,
                            endOpacity: _endOpacity,
                          );
                        }
                        widget.onSaveRange();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

              Divider(color: AppTheme.dividerColor(context), height: 10),

              // 2. 第二行：显示八度及半音范围的文本、可点击播放的最低音和最高音、调整渐变起始与终止色彩浓度按钮、渐变方向按钮、可滑动的颜色选项
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 第一项：显示八度以及半音范围的文本元素
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 3.5 : 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isNarrow ? spanText.replaceAll('个', '') : spanText,
                      style: TextStyle(
                        fontSize: isNarrow ? 9.5 : 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),

                  SizedBox(width: isNarrow ? 3.5 : 5),

                  // 第二项：可以点击播放的最低音和最高音的元素
                  _buildNoteDisplayChip(
                    context: context,
                    note: lowNote,
                    midi: lowMidi,
                    accentColor: const Color(0xFF00E5FF),
                    isDark: isDark,
                    isCompact: isNarrow,
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 1.0 : 2.5),
                    child: Icon(Icons.arrow_forward_rounded, size: isNarrow ? 9 : 12, color: AppTheme.textTertiary(context)),
                  ),

                  _buildNoteDisplayChip(
                    context: context,
                    note: highNote,
                    midi: highMidi,
                    accentColor: const Color(0xFFFFB300),
                    isDark: isDark,
                    isCompact: isNarrow,
                  ),

                  SizedBox(width: isNarrow ? 3.5 : 5),

                  // 第三项：调整渐变起始与终止色彩浓度的按钮
                  InkWell(
                    onTap: () => _showOpacitySettings(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 3.5 : 5.5, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _selectedColor.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.opacity_rounded, size: isNarrow ? 10.5 : 12, color: _selectedColor),
                          const SizedBox(width: 2),
                          Text(
                            isNarrow
                                ? '${(_startOpacity * 100).round()}%→${(_endOpacity * 100).round()}%'
                                : '${(_startOpacity * 100).round()}%⟶${(_endOpacity * 100).round()}%',
                            style: TextStyle(
                              fontSize: isNarrow ? 9 : 10,
                              fontWeight: FontWeight.bold,
                              color: _selectedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: isNarrow ? 3.5 : 5),

                  // 第四项：渐变方向按钮
                  InkWell(
                    onTap: () {
                      setState(() => _gradientReversed = !_gradientReversed);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 3.5 : 5.5, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _gradientReversed
                            ? const Color(0xFFE040FB).withValues(alpha: 0.18)
                            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _gradientReversed ? const Color(0xFFE040FB) : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Text(
                        _gradientReversed ? (isNarrow ? '反 ⇄' : '反向 ⇄') : (isNarrow ? '正 ⇄' : '正向 ⇄'),
                        style: TextStyle(
                          fontSize: isNarrow ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: _gradientReversed ? const Color(0xFFE040FB) : AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: isNarrow ? 4 : 6),

                  // 第五项：可滑动的颜色选项 (Expanded 自适应填满剩余空间，支持平滑滚动)
                  Expanded(
                    child: SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _palette.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4.5),
                        itemBuilder: (context, index) {
                          final c = _palette[index];
                          final isSelected = _selectedColor.toARGB32() == c.toARGB32();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Center(
                              child: Container(
                                width: isNarrow ? 18 : 20,
                                height: isNarrow ? 18 : 20,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: AppTheme.textPrimary(context), width: 2.0)
                                      : Border.all(color: isDark ? Colors.white24 : Colors.black26, width: 1),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: c.withValues(alpha: 0.8), blurRadius: 5)]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(Icons.check, size: isNarrow ? 10 : 12, color: Colors.white)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建规范科学记谱音名芯片 (对标左上角 ScientificNoteCard 视觉风格，并支持点击直接发音试听)
  Widget _buildNoteDisplayChip({
    required BuildContext context,
    required FormattedNote note,
    required int midi,
    required Color accentColor,
    required bool isDark,
    bool isCompact = false,
  }) {
    return Tooltip(
      message: '播放: ${note.displayName} (${note.solfege})',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.state.onPianoKeyPressed(midi);
            _playbackReleaseTimer?.cancel();
            _playbackReleaseTimer = Timer(const Duration(milliseconds: 350), () {
              if (mounted) {
                widget.state.onPianoKeyReleased(midi);
              }
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 7, vertical: isCompact ? 2.5 : 3.5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.65),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 试听发音提示图标
                Icon(
                  Icons.volume_up_rounded,
                  size: isCompact ? 10 : 11.5,
                  color: accentColor.withValues(alpha: 0.85),
                ),
                SizedBox(width: isCompact ? 2 : 4),

                // 基音大写字母
                Text(
                  note.baseNote,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),

                // 升降号与八度下标规范垂直排布 (与左上角科学音名卡片对齐一致)
                if (note.accidental.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 1.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 右上角：升降号上标
                        Text(
                          note.accidental,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 8.5 : 9.5,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 0.5),
                        // 右下角：八度数字下标
                        Text(
                          '${note.octave}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 7.5 : 8.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor.withValues(alpha: 0.9),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // 无升降号时：八度数字作为经典右下标自然下沉
                  Padding(
                    padding: EdgeInsets.only(left: 1.0, top: isCompact ? 2.0 : 4.0),
                    child: Text(
                      '${note.octave}',
                      style: TextStyle(
                        fontSize: isCompact ? 9.5 : 10.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor.withValues(alpha: 0.85),
                        height: 1.0,
                      ),
                    ),
                  ),

                // 仅在非紧凑模式下显示唱名胶囊
                if (!isCompact) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${note.solfege})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor.withValues(alpha: 0.85),
                      height: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

