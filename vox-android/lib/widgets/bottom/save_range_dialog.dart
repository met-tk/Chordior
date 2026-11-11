import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/music_theory.dart';
import '../../models/vocal_range_model.dart';
import '../../state/vocal_master_state.dart';

/// 保存自定义划定音区对话框
class SaveRangeDialog extends StatefulWidget {
  final int startMidi;
  final int endMidi;
  final Function({
    required String name,
    required VocalRangeType type,
    required Color color,
    required String description,
  }) onSave;

  const SaveRangeDialog({
    super.key,
    required this.startMidi,
    required this.endMidi,
    required this.onSave,
  });

  @override
  State<SaveRangeDialog> createState() => _SaveRangeDialogState();
}

class _SaveRangeDialogState extends State<SaveRangeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  VocalRangeType _selectedType = VocalRangeType.mixVoice;
  Color _selectedColor = const Color(0xFFAB47BC); // 紫罗兰

  final List<Color> _presetColors = [
    const Color(0xFFFF1744), // 珊瑚绯红
    const Color(0xFFFF2A6D), // 极客霓红
    const Color(0xFFF50057), // 玫瑰艳红
    const Color(0xFFE040FB), // 梦幻洋红
    const Color(0xFF7C4DFF), // 深邃星紫
    const Color(0xFF651FFF), // 炫彩靛蓝
    const Color(0xFF2979FF), // 经典宝蓝
    const Color(0xFF00B0FF), // 天空亮蓝
    const Color(0xFF00E5FF), // 极光霓青
    const Color(0xFF1DE9B6), // 薄荷海青
    const Color(0xFF00E676), // 翡翠翠绿
    const Color(0xFF76FF03), // 荧光青绿
    const Color(0xFFAEEA00), // 青柠炫黄
    const Color(0xFFFFEA00), // 纯亮柠檬
    const Color(0xFFFFB300), // 琥珀纯金
    const Color(0xFFFF6D00), // 活力暖橙
    const Color(0xFFFF3D00), // 炽热橙红
    const Color(0xFF78909C), // 沉静蓝灰
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '混声区');
    _descController = TextEditingController(
      text: MusicTheory.getVoiceRangeDescription('混声区', widget.startMidi, widget.endMidi),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onTypeChanged(VocalRangeType type) {
    setState(() {
      _selectedType = type;
      switch (type) {
        case VocalRangeType.mainRange:
          _nameController.text = '主要音区';
          _selectedColor = const Color(0xFF00E5FF);
          break;
        case VocalRangeType.chestVoice:
          _nameController.text = '真声区';
          _selectedColor = const Color(0xFFFFB300);
          break;
        case VocalRangeType.mixVoice:
          _nameController.text = '混声区';
          _selectedColor = const Color(0xFFAB47BC);
          break;
        case VocalRangeType.headVoice:
          _nameController.text = '假声/头声区';
          _selectedColor = const Color(0xFF42A5F5);
          break;
        case VocalRangeType.focusPractice:
          _nameController.text = '重点练习区域';
          _selectedColor = const Color(0xFFFF5252);
          break;
        case VocalRangeType.custom:
          _nameController.text = '个性特色音区';
          _selectedColor = const Color(0xFF69F0AE);
          break;
      }
      _descController.text = MusicTheory.getVoiceRangeDescription(_nameController.text, widget.startMidi, widget.endMidi);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final startNote = MusicTheory.getFormattedNote(widget.startMidi, octaveNotation: state.octaveNotation).displayName;
    final endNote = MusicTheory.getFormattedNote(widget.endMidi, octaveNotation: state.octaveNotation).displayName;
    final semitones = (widget.endMidi - widget.startMidi).abs() + 1;

    return Dialog(
      backgroundColor: const Color(0xFF161922),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题与范围信息
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: _selectedColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '保存为音区对象',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _selectedColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '$startNote ~ $endNote ($semitones 半音)',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _selectedColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 快速分类模板按钮组
              const Text('快速选择音区类别:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  _buildTypeChip('主要音区', VocalRangeType.mainRange),
                  _buildTypeChip('真声区', VocalRangeType.chestVoice),
                  _buildTypeChip('混声区', VocalRangeType.mixVoice),
                  _buildTypeChip('假声区', VocalRangeType.headVoice),
                  _buildTypeChip('重点练习区', VocalRangeType.focusPractice),
                  _buildTypeChip('自定义', VocalRangeType.custom),
                ],
              ),

              const SizedBox(height: 10),

              // 音区名称输入框
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                decoration: InputDecoration(
                  labelText: '音区名称',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                  filled: true,
                  isDense: true,
                  fillColor: const Color(0xFF1E2230),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _selectedColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 10),

              // 专属主题色彩选择 (水平可滑动列表，既节省空间又容纳更多色彩)
              const Text('专属主题色彩 (用于多轨与重叠展示):', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _presetColors.map((color) {
                      final isSelected = _selectedColor.toARGB32() == color.toARGB32();
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
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.0,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 描述/声乐建议
              TextField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                decoration: InputDecoration(
                  labelText: '声乐机理与练习心得',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                  filled: true,
                  isDense: true,
                  fillColor: const Color(0xFF1E2230),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 12),

              // 确认与取消按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('取消', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty) {
                        widget.onSave(
                          name: name,
                          type: _selectedType,
                          color: _selectedColor,
                          description: _descController.text.trim(),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('保 存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, VocalRangeType type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10.5, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      selectedColor: _selectedColor,
      backgroundColor: const Color(0xFF1E2230),
      onSelected: (_) => _onTypeChanged(type),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
