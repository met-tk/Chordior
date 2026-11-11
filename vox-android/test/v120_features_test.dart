import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocal_master_flutter/core/music_theory.dart';
import 'package:vocal_master_flutter/models/vocal_range_model.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/widgets/bottom/settings_sheet.dart';
import 'package:vocal_master_flutter/widgets/header/scientific_note_card.dart';
import 'package:vocal_master_flutter/audio/real_audio_engine.dart';
import 'package:vocal_master_flutter/widgets/bottom/range_editor_dialog.dart';
import 'package:vocal_master_flutter/widgets/bottom/save_range_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vox Octave Notation (SPN vs Yamaha) Tests', () {
    test('MusicTheory.getFormattedNote formats accurately for SPN and Yamaha standards', () {
      // MIDI 60: 中央 C (Middle C)
      final spnC4 = MusicTheory.getFormattedNote(60, octaveNotation: OctaveNotation.spn);
      expect(spnC4.displayName, 'C4');
      expect(spnC4.octave, 4);
      expect(spnC4.scriptNotation, 'C4');

      final yamahaC3 = MusicTheory.getFormattedNote(60, octaveNotation: OctaveNotation.yamaha);
      expect(yamahaC3.displayName, 'C3');
      expect(yamahaC3.octave, 3);
      expect(yamahaC3.scriptNotation, 'C3');

      // MIDI 72: 高音 C (Treble C)
      final spnC5 = MusicTheory.getFormattedNote(72, octaveNotation: OctaveNotation.spn);
      expect(spnC5.displayName, 'C5');
      final yamahaC4 = MusicTheory.getFormattedNote(72, octaveNotation: OctaveNotation.yamaha);
      expect(yamahaC4.displayName, 'C4');

      // MIDI 48: 低音 C (Bass C)
      final spnC3 = MusicTheory.getFormattedNote(48, octaveNotation: OctaveNotation.spn);
      expect(spnC3.displayName, 'C3');
      final yamahaC2 = MusicTheory.getFormattedNote(48, octaveNotation: OctaveNotation.yamaha);
      expect(yamahaC2.displayName, 'C2');

      // MIDI 24: C1
      final spnC1 = MusicTheory.getFormattedNote(24, octaveNotation: OctaveNotation.spn);
      expect(spnC1.displayName, 'C1');
      final yamahaC0 = MusicTheory.getFormattedNote(24, octaveNotation: OctaveNotation.yamaha);
      expect(yamahaC0.displayName, 'C0');
    });

    test('VocalRangeItem formatRangeLabel respects OctaveNotation', () {
      final range = VocalRangeItem(
        id: 'test_range',
        name: '假声区',
        type: VocalRangeType.headVoice,
        startMidi: 60, // C4 (SPN) / C3 (Yamaha)
        endMidi: 72,   // C5 (SPN) / C4 (Yamaha)
        color: Colors.blue,
      );

      expect(range.formatRangeLabel(OctaveNotation.spn), 'C4 ~ C5');
      expect(range.formatRangeLabel(OctaveNotation.yamaha), 'C3 ~ C4');
      expect(range.rangeLabel, 'C4 ~ C5'); // 默认兼容
    });

    test('VocalMasterState handles OctaveNotation state changes and preferences', () {
      final state = VocalMasterState();
      expect(state.octaveNotation, OctaveNotation.yamaha);

      state.setOctaveNotation(OctaveNotation.spn);
      expect(state.octaveNotation, OctaveNotation.spn);

      state.toggleOctaveNotation();
      expect(state.octaveNotation, OctaveNotation.yamaha);
    });

    test('Sustained instruments stop on piano key release', () {
      final state = VocalMasterState();
      // 切到音乐会长笛
      state.setTimbre('Concert Flute');
      expect(RealAudioEngine.instance.currentTimbre, 'Concert Flute');
      // 触发 release 不抛异常
      state.onPianoKeyReleased(60);

      // 切到独奏小提琴
      state.setTimbre('Solo Violin');
      expect(RealAudioEngine.instance.currentTimbre, 'Solo Violin');
      state.onPianoKeyReleased(60);

      // 切到管风琴
      state.setTimbre('Church Organ');
      expect(RealAudioEngine.instance.currentTimbre, 'Church Organ');
      state.onPianoKeyReleased(60);
    });
  });

  group('SettingsSheet & ScientificNoteCard Octave Notation Widget Tests', () {
    testWidgets('ScientificNoteCard reflects SPN vs Yamaha octave notation', (WidgetTester tester) async {
      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: state,
              child: ScientificNoteCard(
                midi: 60,
                preferSharp: true,
                onToggleSharp: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 默认 Yamaha 下中央 C 主音名八度显示为 3 (C3)
      expect(find.text('C'), findsWidgets);
      expect(find.text('3'), findsOneWidget);

      // 切换为 SPN 记谱法
      state.setOctaveNotation(OctaveNotation.spn);
      await tester.pumpAndSettle();

      // SPN 下主音名显示为 C4
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('SettingsSheet contains Octave Notation section and single toggle buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: state,
              child: const SettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final s = state.strings;
      final scrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );

      // 验证八度记谱法标准区域存在
      await tester.scrollUntilVisible(find.text(s.octaveNotationTitle), 50.0, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text(s.octaveNotationTitle), findsOneWidget);
      expect(find.text(s.octaveNotationSpn), findsOneWidget);
      expect(find.text(s.octaveNotationYamaha), findsOneWidget);

      // 点击切换为 Yamaha
      await tester.tap(find.text(s.octaveNotationYamaha));
      await tester.pumpAndSettle();
      expect(state.octaveNotation, OctaveNotation.yamaha);

      // 滚动到“新增音区默认方位”单按钮
      await tester.scrollUntilVisible(find.text(s.blackKeySide), 50.0, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text(s.blackKeySide), findsOneWidget);
      await tester.tap(find.text(s.blackKeySide));
      await tester.pumpAndSettle();
      expect(state.rangeIndicatorPosition, RangeIndicatorPosition.whiteKeySide);
      expect(find.text(s.whiteKeySide), findsOneWidget);

      // 滚动到“音区窗口纵向长度”单按钮
      await tester.scrollUntilVisible(find.text(s.autoFit), 50.0, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text(s.autoFit), findsOneWidget);
      await tester.tap(find.text(s.autoFit));
      await tester.pumpAndSettle();
      expect(state.rangeManagerHeightMode, 'custom');
      expect(find.text(s.customHeight), findsOneWidget);
    });
  });

  group('v1.2.0 Build 13 UI Compactness, Scale Slider & Vector Icons Tests', () {
    test('All instruments have native vector IconData and no empty icons', () {
      final instruments = RealAudioEngine.instruments;
      expect(instruments.length, 8);
      for (final inst in instruments) {
        expect(inst.iconData, isNotNull);
      }
      final diva = instruments.firstWhere((i) => i.id == 'Virtual Singer');
      expect(diva.iconData, Icons.mic_external_on_rounded);
      final piano = instruments.firstWhere((i) => i.id == 'Concert Grand');
      expect(piano.iconData, Icons.piano_rounded);
    });

    testWidgets('SettingsSheet renders UI scale slider and resets correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: state,
              child: const SettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final s = state.strings;
      final scrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );

      await tester.scrollUntilVisible(find.text(s.uiScaleTitle), 50.0, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text(s.uiScaleTitle), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // 调整 UI 比例
      state.setUiScale(0.85);
      await tester.pumpAndSettle();
      expect(find.text('85%'), findsOneWidget);
      expect(find.byKey(const Key('ui_scale_reset_button')), findsOneWidget);

      // 点击重置
      await tester.tap(find.byKey(const Key('ui_scale_reset_button')));
      await tester.pumpAndSettle();
      expect(state.uiScale, 1.0);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('RangeEditorDialog renders compactly on narrow screen (360x640) without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = VocalMasterState();
      final range = state.userRanges.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: state,
              child: RangeEditorDialog(range: range, state: state),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RangeEditorDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SaveRangeDialog renders compactly on narrow screen (360x640) without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: state,
              child: SaveRangeDialog(
                startMidi: 60,
                endMidi: 72,
                onSave: ({required color, required description, required name, required type}) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SaveRangeDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
