import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/widgets/header/info_header_widget.dart';
import 'package:vocal_master_flutter/widgets/bottom/bottom_control_deck.dart';
import 'package:vocal_master_flutter/widgets/piano/piano_view_container.dart';
import 'package:vocal_master_flutter/widgets/piano/range_selection_deck.dart';
import 'package:vocal_master_flutter/widgets/common/split_divider_handle.dart';
import 'package:vocal_master_flutter/widgets/bottom/range_manager_sheet.dart';
import 'package:vocal_master_flutter/models/vocal_range_model.dart';
import 'package:vocal_master_flutter/main.dart';

void _dummy() {}

void main() {
  testWidgets('Test InfoHeader in Column with Expanded', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VocalMasterState(),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                InfoHeaderWidget(onOpenRangeManager: () {}, onOpenSettings: () {}),
                Expanded(child: Container(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('Test BottomControlDeck in Column with Expanded', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VocalMasterState(),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: Container(color: Colors.blue)),
                BottomControlDeck(onOpenRangeManager: () {}, onOpenSettings: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('Test PianoViewContainer in Column with Expanded', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VocalMasterState(),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(height: 50, color: Colors.green),
                Expanded(child: PianoViewContainer(onOpenRangeSaveDialog: () {})),
                Container(height: 50, color: Colors.yellow),
              ],
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('Test RangeSelectionDeck in narrow screen without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = VocalMasterState();
    state.setMode(StudioMode.rangeSelect);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RangeSelectionDeck(
                state: state,
                onSaveRange: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // 验证“试听起止”按钮与“起音/止音”文字标签已被彻底删除
    expect(find.text('试听起止'), findsNothing);
    expect(find.text('起音 '), findsNothing);
    expect(find.text('止音 '), findsNothing);

    // 点击音名芯片发声测试 (通过芯片上的 volume_up_rounded 图标)
    final lowMidi = (state.selectionStartMidi ?? 60) < (state.selectionEndMidi ?? 67)
        ? (state.selectionStartMidi ?? 60)
        : (state.selectionEndMidi ?? 67);
    await tester.tap(find.byIcon(Icons.volume_up_rounded).first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.currentMidi, lowMidi);

    // 测试编辑模式下亦绝无溢出，且名称输入框位于第一项
    if (state.userRanges.isNotEmpty) {
      state.startEditingExistingRange(state.userRanges.first);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const Key('range_deck_save_button')), findsOneWidget);
    }
  });

  testWidgets('Test SplitDividerHandle drag and double-tap in studio layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = VocalMasterState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                InfoHeaderWidget(onOpenRangeManager: _dummy, onOpenSettings: _dummy),
                SplitDividerHandle(),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SplitDividerHandle), findsOneWidget);
    expect(state.headerHeight, VocalMasterState.defaultHeaderHeight);

    // 向上拖拽测试 (五线谱变矮，下方空间增加)
    await tester.drag(find.byType(SplitDividerHandle), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(state.headerHeight < VocalMasterState.defaultHeaderHeight, true);

    // 双击重置测试
    await tester.tap(find.byType(SplitDividerHandle));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(SplitDividerHandle));
    await tester.pumpAndSettle();
    expect(state.headerHeight, VocalMasterState.defaultHeaderHeight);
  });

  testWidgets('Test VocalMasterStudioScreen mounts pianoContainerKey and SettingsSheet has height controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = VocalMasterState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(
          home: VocalMasterStudioScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(state.pianoContainerKey.currentContext, isNotNull);
    expect(state.pianoTopY, isNotNull);

    // 打开设置弹窗
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    // 滚动以呈现音区管理窗口高度区块
    final verticalScrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('自动贴合'),
      50.0,
      scrollable: verticalScrollable,
    );
    await tester.pumpAndSettle();

    // 验证初始单按钮状态为自动贴合，点击切换为自定义
    expect(find.text('自动贴合'), findsOneWidget);
    await tester.tap(find.text('自动贴合'));
    await tester.pumpAndSettle();
    expect(find.text('自定义'), findsOneWidget);
  });

  testWidgets('Test drag and cross-side swap in RangeManagerSheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = VocalMasterState();
    state.resetDefaultRanges();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: RangeManagerSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 找到白键侧混声区与黑键侧主要音区
    final mixFinder = find.text('混声区');
    final mainFinder = find.text('主要音区');
    expect(mixFinder, findsOneWidget);
    expect(mainFinder, findsOneWidget);

    final mixCenter = tester.getCenter(mixFinder);
    final mainCenter = tester.getCenter(mainFinder);

    // 模拟长按（150ms 即可激活）并拖动到主要音区整排
    final gesture = await tester.startGesture(mixCenter);
    await tester.pump(const Duration(milliseconds: 250)); // 超过 150ms

    await gesture.moveTo(mainCenter);
    await tester.pumpAndSettle();

    await gesture.up();
    await tester.pumpAndSettle();

    final afterMix = state.userRanges.firstWhere((r) => r.id == 'preset_mix');
    final afterMain = state.userRanges.firstWhere((r) => r.id == 'preset_main');

    // 成功完成跨侧置换：混声区进入黑键侧，主要音区进入白键侧！
    expect(afterMix.indicatorPosition, RangeIndicatorPosition.blackKeySide);
    expect(afterMain.indicatorPosition, RangeIndicatorPosition.whiteKeySide);
  });
}

