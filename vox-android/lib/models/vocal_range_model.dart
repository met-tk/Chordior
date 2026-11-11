import 'package:flutter/material.dart';
import '../core/music_theory.dart';

/// 音区类型枚举
enum VocalRangeType {
  mainRange,      // 主要音区
  chestVoice,     // 真声区
  mixVoice,       // 混声区
  headVoice,      // 假声/头声区
  focusPractice,  // 重点练习区域
  custom,         // 自定义音区
}

/// 音区括线与标签在钢琴键盘上的呈现方位 (作为单个音区对象的独立属性)
enum RangeIndicatorPosition {
  blackKeySide, // 黑键侧 (横排在琴键上方，竖排在琴键左侧)
  whiteKeySide, // 白键侧 (横排在琴键下方，竖排在琴键右侧)
}

/// 音区对象模型 (允许范围重叠，作为独立交互实体)
class VocalRangeItem {
  final String id;
  String name;
  VocalRangeType type;
  int startMidi;
  int endMidi;
  Color color;
  String description;
  bool isVisible;
  RangeIndicatorPosition indicatorPosition;
  int gradientSteps;
  bool gradientReversed;
  double startOpacity; // 起始色彩浓度 (0.1 ~ 1.0，默认 0.70)
  double endOpacity;   // 终止色彩浓度 (0.0 ~ 0.5，默认 0.05)
  String? trackGroupId; // 自定义轨道排组ID (属于同一组且互不重叠的音区强制排布在同一行)
  int trackOrder;       // 排道显示次序 (在同侧排组中从0开始升序，决定物理远离/靠近键盘的层级)

  VocalRangeItem({
    required this.id,
    required this.name,
    required this.type,
    required this.startMidi,
    required this.endMidi,
    required this.color,
    this.description = '',
    this.isVisible = true,
    this.indicatorPosition = RangeIndicatorPosition.blackKeySide,
    this.gradientSteps = 6,
    this.gradientReversed = false,
    this.startOpacity = 0.70,
    this.endOpacity = 0.05,
    this.trackGroupId,
    this.trackOrder = 0,
  }) {
    if (startMidi > endMidi) {
      final temp = startMidi;
      startMidi = endMidi;
      endMidi = temp;
    }
  }

  VocalRangeItem copyWith({
    String? id,
    String? name,
    VocalRangeType? type,
    int? startMidi,
    int? endMidi,
    Color? color,
    String? description,
    bool? isVisible,
    RangeIndicatorPosition? indicatorPosition,
    int? gradientSteps,
    bool? gradientReversed,
    double? startOpacity,
    double? endOpacity,
    String? trackGroupId,
    bool clearTrackGroupId = false,
    int? trackOrder,
  }) {
    return VocalRangeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startMidi: startMidi ?? this.startMidi,
      endMidi: endMidi ?? this.endMidi,
      color: color ?? this.color,
      description: description ?? this.description,
      isVisible: isVisible ?? this.isVisible,
      indicatorPosition: indicatorPosition ?? this.indicatorPosition,
      gradientSteps: gradientSteps ?? this.gradientSteps,
      gradientReversed: gradientReversed ?? this.gradientReversed,
      startOpacity: startOpacity ?? this.startOpacity,
      endOpacity: endOpacity ?? this.endOpacity,
      trackGroupId: clearTrackGroupId ? null : (trackGroupId ?? this.trackGroupId),
      trackOrder: trackOrder ?? this.trackOrder,
    );
  }

  /// 半音跨度
  int get semitones => endMidi - startMidi + 1;

  /// 起止音名显示文本 (支持 SPN 与 Yamaha 八度记谱法标准)
  String formatRangeLabel([OctaveNotation octaveNotation = OctaveNotation.spn]) {
    final startNote = MusicTheory.getFormattedNote(startMidi, octaveNotation: octaveNotation).displayName;
    final endNote = MusicTheory.getFormattedNote(endMidi, octaveNotation: octaveNotation).displayName;
    return '$startNote ~ $endNote';
  }

  /// 默认 SPN 记谱起止文本 (向后兼容)
  String get rangeLabel => formatRangeLabel(OctaveNotation.spn);

  /// 跨度描述
  String get spanDescription => MusicTheory.calculateRangeSpan(startMidi, endMidi);

  /// 检查某音符是否在此音区内
  bool containsMidi(int midi) => midi >= startMidi && midi <= endMidi;

  /// 检查是否与另一个音区有重叠
  bool overlapsWith(VocalRangeItem other) {
    return startMidi <= other.endMidi && endMidi >= other.startMidi;
  }

  /// 检查是否可以与目标音区列表在同一排（充要条件：同属一侧 且 与列表中所有其他音区均无重叠）
  bool canShareTrackWithAll(Iterable<VocalRangeItem> others) {
    for (final other in others) {
      if (other.id != id) {
        // 充要条件1：必须同属一侧（同属黑键侧或同属白键侧）
        if (other.indicatorPosition != indicatorPosition) {
          return false;
        }
        // 充要条件2：音域范围绝对不能重叠
        if (overlapsWith(other)) {
          return false;
        }
      }
    }
    return true;
  }

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'startMidi': startMidi,
    'endMidi': endMidi,
    'color': color.toARGB32(),
    'description': description,
    'isVisible': isVisible,
    'indicatorPosition': indicatorPosition.name,
    'gradientSteps': gradientSteps,
    'gradientReversed': gradientReversed,
    'startOpacity': startOpacity,
    'endOpacity': endOpacity,
    'trackGroupId': trackGroupId,
    'trackOrder': trackOrder,
  };

  /// JSON 反序列化
  factory VocalRangeItem.fromJson(Map<String, dynamic> json) => VocalRangeItem(
    id: json['id'] as String,
    name: json['name'] as String,
    type: VocalRangeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => VocalRangeType.custom,
    ),
    startMidi: json['startMidi'] as int,
    endMidi: json['endMidi'] as int,
    color: Color(json['color'] as int),
    description: json['description'] as String? ?? '',
    isVisible: json['isVisible'] as bool? ?? true,
    indicatorPosition: json['indicatorPosition'] != null
        ? RangeIndicatorPosition.values.firstWhere(
            (p) => p.name == json['indicatorPosition'],
            orElse: () => RangeIndicatorPosition.blackKeySide,
          )
        : RangeIndicatorPosition.blackKeySide,
    gradientSteps: (json['gradientSteps'] as int?) ?? 6,
    gradientReversed: (json['gradientReversed'] as bool?) ?? false,
    startOpacity: (json['startOpacity'] as num?)?.toDouble() ?? 0.70,
    endOpacity: (json['endOpacity'] as num?)?.toDouble() ?? 0.05,
    trackGroupId: json['trackGroupId'] as String?,
    trackOrder: (json['trackOrder'] as int?) ?? 0,
  );

  /// 常用声乐默认预设音区库 (供初次使用与快速套用)
  static List<VocalRangeItem> getDefaultPresets() {
    return [
      VocalRangeItem(
        id: 'preset_main',
        name: '主要音区',
        type: VocalRangeType.mainRange,
        startMidi: 53, // F3
        endMidi: 69,   // A4
        color: const Color(0xFF00E5FF), // 极光亮青
        description: '演唱最自如从容、表现力最稳定饱满的核心歌唱区间。',
        indicatorPosition: RangeIndicatorPosition.blackKeySide,
      ),
      VocalRangeItem(
        id: 'preset_chest',
        name: '真声区',
        type: VocalRangeType.chestVoice,
        startMidi: 48, // C3
        endMidi: 64,   // E4
        color: const Color(0xFFFFB300), // 琥珀深金
        description: '声带全层振动，具有厚实质感与胸腔共鸣。',
        indicatorPosition: RangeIndicatorPosition.blackKeySide,
      ),
      VocalRangeItem(
        id: 'preset_mix',
        name: '混声区',
        type: VocalRangeType.mixVoice,
        startMidi: 62, // D4 (与真声区重叠 D4~E4)
        endMidi: 72,   // C5
        color: const Color(0xFFAB47BC), // 高贵紫罗兰
        description: '胸头声混合连接区，渡过第一和第二换声点 (Passaggio) 的关键。',
        indicatorPosition: RangeIndicatorPosition.whiteKeySide, // 默认置于白键侧，与真声区交相呼应不冲突！
      ),
      VocalRangeItem(
        id: 'preset_head',
        name: '假声/头声区',
        type: VocalRangeType.headVoice,
        startMidi: 70, // Bb4 (与混声区重叠 Bb4~C5)
        endMidi: 81,   // A5
        color: const Color(0xFF42A5F5), // 空灵天蓝
        description: '声带边缘振动，头腔高频泛音丰富。',
        indicatorPosition: RangeIndicatorPosition.blackKeySide,
      ),
      VocalRangeItem(
        id: 'preset_focus',
        name: '重点练习区域',
        type: VocalRangeType.focusPractice,
        startMidi: 64, // E4
        endMidi: 69,   // A4 (重点突破换声点)
        color: const Color(0xFFFF5252), // 活力珊瑚红
        description: '当前跟唱攻坚突破音段，建议重点进行琶音与哼鸣跟唱打磨。',
        indicatorPosition: RangeIndicatorPosition.whiteKeySide, // 默认置于白键侧，清晰独立
      ),
    ];
  }
}

/// 区间图着色贪心分轨算法 (支持用户自定义轨道组与智能避让)
/// 计算音区在钢琴键盘边缘的分层分配：
/// 1. 若用户通过拖拽分配了 trackGroupId，同组内无重叠音区严格独占/共享该排
/// 2. 未指定分组的音区自动使用贪心区间排布填补可用空闲泳道
class RangeLaneAllocation {
  final Map<String, int> rangeIdToLane;
  final int totalLanes;

  const RangeLaneAllocation(this.rangeIdToLane, this.totalLanes);

  /// 检查两个音区是否可以合并在同一排（充要条件：同属一侧 且 不存在范围重叠）
  static bool canMerge(VocalRangeItem a, VocalRangeItem b) {
    if (a.indicatorPosition != b.indicatorPosition) return false;
    return !a.overlapsWith(b);
  }

  /// 检查候选音区是否能并入已有音区排（充要条件：同属一侧 且 与该排中所有现有音区均无重叠）
  static bool canAddToGroup(VocalRangeItem candidate, Iterable<VocalRangeItem> groupRanges) {
    return candidate.canShareTrackWithAll(groupRanges);
  }

  static RangeLaneAllocation compute(List<VocalRangeItem> ranges) {
    if (ranges.isEmpty) {
      return const RangeLaneAllocation({}, 0);
    }

    final List<List<VocalRangeItem>> lanes = [];
    final Map<String, int> allocation = {};

    // 1. 处理已拥有明确 trackGroupId 的自定义分组
    final Map<String, List<VocalRangeItem>> groupedRanges = {};
    final List<VocalRangeItem> ungroupedRanges = [];

    for (final r in ranges) {
      if (r.trackGroupId != null && r.trackGroupId!.isNotEmpty) {
        groupedRanges.putIfAbsent(r.trackGroupId!, () => []).add(r);
      } else {
        ungroupedRanges.add(r);
      }
    }

    // 依次为每个手动组分配独立泳道 (严格按照用户指定的 trackOrder 升序分配，若相同则保持稳定)
    final sortedGroups = groupedRanges.values.toList()
      ..sort((a, b) {
        final orderComp = a.first.trackOrder.compareTo(b.first.trackOrder);
        if (orderComp != 0) return orderComp;
        return a.first.startMidi.compareTo(b.first.startMidi);
      });

    for (final group in sortedGroups) {
      // 组内音区按音高起始排序
      group.sort((a, b) => a.startMidi.compareTo(b.startMidi));
      final groupLane = lanes.length;
      lanes.add(List<VocalRangeItem>.from(group));
      for (final item in group) {
        allocation[item.id] = groupLane;
      }
    }

    final int manualLanesCount = lanes.length; // 手动排组占用的独立泳道数

    // 2. 对未分组的音区使用贪心区间分配 (优先按 trackOrder 升序，次按 startMidi 升序)
    // 仅在未分组泳道（i >= manualLanesCount）中复用，绝不自动侵入污染用户的手动专属排组
    final sortedUngrouped = List<VocalRangeItem>.from(ungroupedRanges)
      ..sort((a, b) {
        final orderComp = a.trackOrder.compareTo(b.trackOrder);
        if (orderComp != 0) return orderComp;
        return a.startMidi.compareTo(b.startMidi);
      });

    for (final range in sortedUngrouped) {
      int assignedLane = -1;

      // 寻找首个与当前 range 完全不冲突的未分组泳道（必须同侧且无重叠）
      for (int i = manualLanesCount; i < lanes.length; i++) {
        final laneRanges = lanes[i];
        final hasConflict = laneRanges.any((existing) =>
            existing.indicatorPosition != range.indicatorPosition || range.overlapsWith(existing));

        if (!hasConflict) {
          assignedLane = i;
          laneRanges.add(range);
          break;
        }
      }

      // 若现有所有泳道均冲突，则开辟全新泳道
      if (assignedLane == -1) {
        assignedLane = lanes.length;
        lanes.add([range]);
      }

      allocation[range.id] = assignedLane;
    }

    return RangeLaneAllocation(allocation, lanes.length);
  }
}
