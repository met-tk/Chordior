import 'package:flutter/material.dart';
import '../../core/music_theory.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

/// 音区对象自定义颜色与双滑块范围编辑弹窗
class RangeEditorDialog extends StatefulWidget {
  final VocalRangeItem range;
  final VocalMasterState state;

  const RangeEditorDialog({
    super.key,
    required this.range,
    required this.state,
  });

  @override
  State<RangeEditorDialog> createState() => _RangeEditorDialogState();
}

class _RangeEditorDialogState extends State<RangeEditorDialog> {
  late TextEditingController _nameController;
  late VocalRangeType _selectedType;
  late Color _selectedColor;
  late int _startMidi;
  late int _endMidi;

  // 18 种专业声乐高饱和度质感调色板 (水平平滑横向滚动，容纳丰富色彩)
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.range.name);
    _selectedType = widget.range.type;
    _selectedColor = widget.range.color;
    _startMidi = widget.range.startMidi;
    _endMidi = widget.range.endMidi;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowMidi = _startMidi < _endMidi ? _startMidi : _endMidi;
    final highMidi = _startMidi > _endMidi ? _startMidi : _endMidi;

    final lowNote = MusicTheory.getFormattedNote(lowMidi, preferSharp: widget.state.preferSharps, octaveNotation: widget.state.octaveNotation);
    final highNote = MusicTheory.getFormattedNote(highMidi, preferSharp: widget.state.preferSharps, octaveNotation: widget.state.octaveNotation);
    final spanStr = MusicTheory.calculateRangeSpan(lowMidi, highMidi);

    return Dialog(
      backgroundColor: const Color(0xFF141722),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _selectedColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 第一行：命名输入框 + 起止音(点击发声) + 精简跨度 + 关闭按钮 (极速紧凑单行排布)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 第一项：音区名称输入框
                  SizedBox(
                    width: 95,
                    height: 32,
                    child: TextField(
                      controller: _nameController,
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '音区名称',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF1B202E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: _selectedColor, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 起止音卡片 + 跨度徽章 (规范科学音名排版，点击即发音)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNoteChip(
                            note: lowNote,
                            midi: lowMidi,
                            color: const Color(0xFF00E5FF),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white38),
                          ),
                          _buildNoteChip(
                            note: highNote,
                            midi: highMidi,
                            color: const Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 5),
                          // 精简跨度徽章
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _selectedColor.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Text(
                              spanStr,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: _selectedColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // 关闭按钮
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 2. 第二行：颜色选项 (水平可滑动列表，节约纵向空间并容纳更多丰富颜色)
              SizedBox(
                height: 26,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _palette.map((color) {
                      final isChosen = _selectedColor.toARGB32() == color.toARGB32();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChosen ? Colors.white : Colors.transparent,
                                width: 2.0,
                              ),
                              boxShadow: [
                                if (isChosen)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                              ],
                            ),
                            child: isChosen
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. 第三行：双滑块音区范围微调器 (RangeSlider)
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.5,
                  activeTrackColor: _selectedColor,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: _selectedColor,
                  overlayColor: _selectedColor.withValues(alpha: 0.2),
                  rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6.5),
                ),
                child: RangeSlider(
                  values: RangeValues(lowMidi.toDouble(), highMidi.toDouble()),
                  min: 36.0,
                  max: 96.0,
                  divisions: 60,
                  onChanged: (RangeValues vals) {
                    setState(() {
                      _startMidi = vals.start.round();
                      _endMidi = vals.end.round();
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 4. 底部操作按钮：左侧删除 + 右侧取消与保存 (防挤压设计)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      widget.state.deleteRange(widget.range.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                    label: const Text('删除音区', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white60,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('取消', style: TextStyle(fontSize: 11.5)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          final newName = _nameController.text.trim();
                          final updated = widget.range.copyWith(
                            name: newName.isNotEmpty ? newName : widget.range.name,
                            type: _selectedType,
                            color: _selectedColor,
                            startMidi: lowMidi,
                            endMidi: highMidi,
                          );
                          widget.state.updateRange(updated);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建规范科学记谱音名芯片 (支持点击直接发音)
  Widget _buildNoteChip({
    required FormattedNote note,
    required int midi,
    required Color color,
  }) {
    return Tooltip(
      message: '播放: ${note.displayName} (${note.solfege})',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.state.onPianoKeyPressed(midi);
            Future.delayed(const Duration(milliseconds: 350), () {
              widget.state.onPianoKeyReleased(midi);
            });
          },
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 0.9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up_rounded, size: 10, color: color),
                const SizedBox(width: 2.5),
                Text(
                  note.baseNote,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color, height: 1.0),
                ),
                if (note.accidental.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(note.accidental, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, height: 1.0)),
                        const SizedBox(height: 0.5),
                        Text('${note.octave}', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: color, height: 1.0)),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 1, top: 2),
                    child: Text('${note.octave}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, height: 1.0)),
                  ),
                const SizedBox(width: 2),
                Text('(${note.solfege})', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
