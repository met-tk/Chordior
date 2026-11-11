import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/models/vocal_range_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Test multi group swap between different sides', () {
    final state = VocalMasterState();
    // 清理现有音区
    state.resetDefaultRanges();
    for (final r in List.of(state.userRanges)) {
      state.deleteRange(r.id);
    }

    // 1. 黑键侧组 1 (A: 40~50, B: 70~80)
    final a = VocalRangeItem(
      id: 'range_A',
      name: '黑A',
      type: VocalRangeType.custom,
      startMidi: 40,
      endMidi: 50,
      color: Colors.red,
      indicatorPosition: RangeIndicatorPosition.blackKeySide,
      trackGroupId: 'black_group_1',
    );
    final b = VocalRangeItem(
      id: 'range_B',
      name: '黑B',
      type: VocalRangeType.custom,
      startMidi: 70,
      endMidi: 80,
      color: Colors.orange,
      indicatorPosition: RangeIndicatorPosition.blackKeySide,
      trackGroupId: 'black_group_1',
    );
    state.addCustomRange(a);
    state.addCustomRange(b);

    // 2. 白键侧组 2 (C: 55~65, D: 85~95)
    final c = VocalRangeItem(
      id: 'range_C',
      name: '白C',
      type: VocalRangeType.custom,
      startMidi: 55,
      endMidi: 65,
      color: Colors.blue,
      indicatorPosition: RangeIndicatorPosition.whiteKeySide,
      trackGroupId: 'white_group_2',
    );
    final d = VocalRangeItem(
      id: 'range_D',
      name: '白D',
      type: VocalRangeType.custom,
      startMidi: 85,
      endMidi: 95,
      color: Colors.green,
      indicatorPosition: RangeIndicatorPosition.whiteKeySide,
      trackGroupId: 'white_group_2',
    );
    state.addCustomRange(c);
    state.addCustomRange(d);

    print('=== 交换前 ===');
    final blackLanesBefore = state.getLanesForSide(true);
    for (int i = 0; i < blackLanesBefore.length; i++) {
      print('黑排 $i: ${blackLanesBefore[i].map((r) => '${r.name}(${r.id}, pos=${r.indicatorPosition.name}, group=${r.trackGroupId})').join(', ')}');
    }
    final whiteLanesBefore = state.getLanesForSide(false);
    for (int i = 0; i < whiteLanesBefore.length; i++) {
      print('白排 $i: ${whiteLanesBefore[i].map((r) => '${r.name}(${r.id}, pos=${r.indicatorPosition.name}, group=${r.trackGroupId})').join(', ')}');
    }

    final canSwap = state.canSwapRanges('range_A', 'range_C');
    expect(canSwap, isTrue);

    final success = state.trySwapRanges('range_A', 'range_C');
    expect(success, isTrue);

    print('=== 交换后 ===');
    final blackLanesAfter = state.getLanesForSide(true);
    for (int i = 0; i < blackLanesAfter.length; i++) {
      print('黑排 $i: ${blackLanesAfter[i].map((r) => '${r.name}(${r.id}, pos=${r.indicatorPosition.name}, group=${r.trackGroupId})').join(', ')}');
    }
    final whiteLanesAfter = state.getLanesForSide(false);
    for (int i = 0; i < whiteLanesAfter.length; i++) {
      print('白排 $i: ${whiteLanesAfter[i].map((r) => '${r.name}(${r.id}, pos=${r.indicatorPosition.name}, group=${r.trackGroupId})').join(', ')}');
    }

    // 验证：C 应该在黑键侧，且与 B 在同一排；A 应该在白键侧，且与 D 在同一排！
    expect(blackLanesAfter.length, 1);
    expect(blackLanesAfter[0].map((r) => r.id).toSet(), {'range_C', 'range_B'});
    expect(whiteLanesAfter.length, 1);
    expect(whiteLanesAfter[0].map((r) => r.id).toSet(), {'range_A', 'range_D'});
  });
}
