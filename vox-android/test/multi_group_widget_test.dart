import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/models/vocal_range_model.dart';
import 'package:vocal_master_flutter/widgets/bottom/range_manager_sheet.dart';

void main() {
  testWidgets('Drag to empty area of multi-range group card', (WidgetTester tester) async {
    final state = VocalMasterState();
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

    await tester.pumpWidget(
      ChangeNotifierProvider<VocalMasterState>.value(
        value: state,
        child: const MaterialApp(
          home: Scaffold(
            body: RangeManagerSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final aFinder = find.text('黑A');
    final dFinder = find.text('白D');

    final aCenter = tester.getCenter(aFinder);
    // 拖到白D右侧50像素处（卡片内部的空白处，不落在任何Chip上）
    final dCenter = tester.getCenter(dFinder);
    final cardEmptyPoint = Offset(dCenter.dx + 50, dCenter.dy);

    final gesture = await tester.startGesture(aCenter);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(cardEmptyPoint);
    await tester.pumpAndSettle();

    await gesture.up();
    await tester.pumpAndSettle();

    print('=== 拖到空白处后 ===');
    final blackLanes = state.getLanesForSide(true);
    for (int i = 0; i < blackLanes.length; i++) {
      print('黑排 $i: ${blackLanes[i].map((r) => '${r.name}(${r.id}, pos=${r.indicatorPosition.name}, group=${r.trackGroupId})').join(', ')}');
    }
    final whiteLanes = state.getLanesForSide(false);
    for (int i = 0; i < whiteLanes.length; i++) {
      print('白排 $i: ${whiteLanes[i].map((r) => '${r.name}(${r.id}, pos=${r.indicatorPosition.name}, group=${r.trackGroupId})').join(', ')}');
    }
  });
}
