import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocal_master_flutter/audio/real_audio_engine.dart';
import 'package:vocal_master_flutter/core/app_strings.dart';
import 'package:vocal_master_flutter/core/app_theme.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/widgets/bottom/settings_sheet.dart';
import 'package:vocal_master_flutter/widgets/header/info_header_widget.dart';
import 'package:vocal_master_flutter/widgets/piano/horizontal_piano.dart';
import 'package:vocal_master_flutter/widgets/piano/vertical_piano.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vox v1.0.0 New Features & Vocal Timbres Verification', () {
    test('Verify Virtual Singer instrument definition and multilingual localization', () {
      final instruments = RealAudioEngine.instruments;
      final diva = instruments.firstWhere((i) => i.id == 'Virtual Singer');

      expect(diva.assetDir, 'diva_voice');

      final zh = AppStrings.of(AppLanguage.zh);
      final en = AppStrings.of(AppLanguage.en);
      final ja = AppStrings.of(AppLanguage.ja);

      expect(zh.instrumentName('Virtual Singer', ''), '虚拟歌姬');
      expect(en.instrumentName('Virtual Singer', ''), 'Virtual Singer');
      expect(ja.instrumentName('Virtual Singer', ''), 'バーチャルシンガー');

      expect(zh.voiceDampingTitle, '音符防浑浊渐弱');
      expect(en.voiceDampingTitle, 'Voice Damping');
      expect(ja.voiceDampingTitle, 'ノート減衰（濁り防止）');
    });

    test('Verify physical audio files for diva_voice exist in assets strictly covering C1 to C6 (61 notes)', () {
      final noteNames = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
      final expectedNotes = <String>[];
      for (int m = 24; m <= 84; m++) {
        final name = noteNames[m % 12];
        final oct = (m ~/ 12) - 1;
        expectedNotes.add('$name$oct');
      }
      expect(expectedNotes.length, 61);

      for (final note in expectedNotes) {
        final dFile = File('assets/audio/diva_voice/$note.mp3');
        expect(dFile.existsSync(), isTrue, reason: 'Missing diva_voice $note.mp3');
        expect(dFile.lengthSync(), greaterThan(1000));
      }
    });

    test('Verify pianoVoiceDamping state defaults to true and can toggle', () {
      final state = VocalMasterState();
      expect(state.pianoVoiceDamping, isTrue);

      state.setPianoVoiceDamping(false);
      expect(state.pianoVoiceDamping, isFalse);

      state.setPianoVoiceDamping(true);
      expect(state.pianoVoiceDamping, isTrue);
    });

    testWidgets('InfoHeaderWidget displays synced version v1.4', (tester) async {
      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider<VocalMasterState>.value(
            value: state,
            child: Scaffold(
              body: InfoHeaderWidget(
                onOpenRangeManager: () {},
                onOpenSettings: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Vox'), findsOneWidget);
      expect(find.text('v1.4'), findsOneWidget);
    });

    testWidgets('SettingsSheet contains Voice Damping switch and taketo credit', (tester) async {
      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider<VocalMasterState>.value(
            value: state,
            child: const Scaffold(
              body: SettingsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 滚动到防浑浊渐弱开关并验证存在与交互
      final switchFinder = find.byKey(const Key('voice_damping_switch'));
      await tester.scrollUntilVisible(switchFinder, 100.0, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      // 点击切换
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(state.pianoVoiceDamping, isFalse);

      // 滚动到底部验证 Vox v1.4 和 AI-driven by taketo
      await tester.scrollUntilVisible(find.text('Vox v1.4'), 100.0, scrollable: find.byType(Scrollable).first);
      expect(find.text('Vox v1.4'), findsOneWidget);
      expect(find.text('AI-driven by taketo'), findsOneWidget);
    });

    test('Verify piano widgets strictly match Yamaha C1-C6 range (minMidi = 36, maxMidi = 96, 61 keys)', () {
      const hPiano = HorizontalPianoWidget(
        activeMidi: 60,
        ranges: [],
        activeRange: null,
        onKeyPressed: _dummyKey,
        onKeyReleased: _dummyKey,
      );
      expect(hPiano.minMidi, 36);
      expect(hPiano.maxMidi, 96);

      const vPiano = VerticalPianoWidget(
        activeMidi: 60,
        ranges: [],
        activeRange: null,
        onKeyPressed: _dummyKey,
        onKeyReleased: _dummyKey,
      );
      expect(vPiano.minMidi, 36);
      expect(vPiano.maxMidi, 96);
    });
  });
}

void _dummyKey(int midi) {}
