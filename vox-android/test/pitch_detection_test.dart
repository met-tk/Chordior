import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_master_flutter/audio/pitch_detector_service.dart';
import 'package:vocal_master_flutter/audio/real_audio_engine.dart';
import 'package:vocal_master_flutter/core/app_strings.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PitchDetectorService & Listening Mode Tests', () {
    late VocalMasterState state;

    setUp(() {
      state = VocalMasterState();
    });

    tearDown(() {
      if (state.isListeningActive) {
        state.toggleListeningMode();
      }
    });

    test('Initial listening state is idle and inactive', () {
      expect(state.isListeningActive, isFalse);
      expect(state.listeningMidiNote, isNull);
      expect(state.listeningPitchHz, equals(0.0));
    });

    test('Toggling listening mode updates state and receives simulated pitch', () async {
      // 开启聆听模式
      await state.toggleListeningMode();
      expect(state.isListeningActive, isTrue);

      // 模拟拾取到 A4 (440Hz, MIDI 69)
      PitchDetectorService.instance.simulatePitch(69, freq: 440.0);
      await Future.delayed(Duration.zero);
      expect(state.listeningMidiNote, equals(69));
      expect(state.listeningPitchHz, closeTo(440.0, 0.1));

      // 模拟音高平滑过渡到 C5 (523.25Hz, MIDI 72)，连续两帧达到多数票确认
      PitchDetectorService.instance.simulatePitch(72, freq: 523.25);
      PitchDetectorService.instance.simulatePitch(72, freq: 523.25);
      await Future.delayed(Duration.zero);
      expect(state.listeningMidiNote, equals(72));
      expect(state.listeningPitchHz, closeTo(523.25, 0.1));

      // 关闭聆听模式
      await state.toggleListeningMode();
      expect(state.isListeningActive, isFalse);
      expect(state.listeningMidiNote, isNull);
    });

    test('Silence smoothing keeps active note before debounce expires', () async {
      await state.toggleListeningMode();
      PitchDetectorService.instance.simulatePitch(60, freq: 261.63);
      await Future.delayed(Duration.zero);
      expect(state.listeningMidiNote, equals(60));

      // 模拟短时间静音 (null)
      PitchDetectorService.instance.simulatePitch(null);
      await Future.delayed(Duration.zero);
      // 由于有 280ms 平滑防闪烁定时器，立即读取时不应立即变为 null
      expect(state.listeningMidiNote, equals(60));

      // 等待超过 320ms 防闪烁消隐时间
      await Future.delayed(const Duration(milliseconds: 320));
      expect(state.listeningMidiNote, isNull);
    });
  });

  group('Internationalization & Instrument Names Tests', () {
    test('Instrument names translate properly in zh, en, and ja', () {
      final zh = AppStrings.of(AppLanguage.zh);
      final en = AppStrings.of(AppLanguage.en);
      final ja = AppStrings.of(AppLanguage.ja);

      // Concert Grand
      expect(zh.instrumentName('Concert Grand', 'Grand Piano'), equals('大三角钢琴'));
      expect(en.instrumentName('Concert Grand', 'Grand Piano'), equals('Concert Grand Piano'));
      expect(ja.instrumentName('Concert Grand', 'Grand Piano'), equals('グランドピアノ'));

      // Church Organ
      expect(zh.instrumentName('Church Organ', 'Pipe Organ'), equals('教堂管风琴'));
      expect(en.instrumentName('Church Organ', 'Pipe Organ'), equals('Church Pipe Organ'));
      expect(ja.instrumentName('Church Organ', 'Pipe Organ'), equals('パイプオルガン'));

      // Concert Flute
      expect(zh.instrumentName('Concert Flute', 'Flute'), equals('音乐会长笛'));
      expect(en.instrumentName('Concert Flute', 'Flute'), equals('Concert Flute'));
      expect(ja.instrumentName('Concert Flute', 'Flute'), equals('コンサートフルート'));

      // Solo Violin
      expect(zh.instrumentName('Solo Violin', 'Violin'), equals('独奏小提琴'));
      expect(en.instrumentName('Solo Violin', 'Violin'), equals('Solo Violin'));
      expect(ja.instrumentName('Solo Violin', 'Violin'), equals('ソロバイオリン'));

      // Fender Rhodes
      expect(zh.instrumentName('Fender Rhodes', 'Electric Piano'), equals('电钢琴 (Rhodes)'));
      expect(en.instrumentName('Fender Rhodes', 'Electric Piano'), equals('Electric Piano (Rhodes)'));
      expect(ja.instrumentName('Fender Rhodes', 'Electric Piano'), equals('エレクトリックピアノ'));

      // Acoustic Guitar
      expect(zh.instrumentName('Acoustic Guitar', 'Guitar'), equals('民谣钢弦吉他'));
      expect(en.instrumentName('Acoustic Guitar', 'Guitar'), equals('Acoustic Guitar'));
      expect(ja.instrumentName('Acoustic Guitar', 'Guitar'), equals('アコースティックギター'));

      // Celesta & Bells
      expect(zh.instrumentName('Celesta & Bells', 'Celesta'), equals('钢片琴 / 钟琴'));
      expect(en.instrumentName('Celesta & Bells', 'Celesta'), equals('Celesta & Bells'));
      expect(ja.instrumentName('Celesta & Bells', 'Celesta'), equals('チェレスタ＆ベル'));
    });

    test('Arpeggio practice titles and buttons translate across languages', () {
      final zh = AppStrings.of(AppLanguage.zh);
      final en = AppStrings.of(AppLanguage.en);
      final ja = AppStrings.of(AppLanguage.ja);

      expect(zh.arpeggioPractice, equals('琶音练习'));
      expect(en.arpeggioPractice, equals('Arpeggio Practice'));
      expect(ja.arpeggioPractice, equals('アルペジオ練習'));

      expect(zh.listenPitch, equals('实时聆听'));
      expect(en.listenPitch, equals('Listen Pitch'));
      expect(ja.listenPitch, equals('ピッチ検出'));

      expect(zh.play, equals('播放'));
      expect(en.play, equals('Play'));
      expect(ja.play, equals('再生'));

      expect(zh.pause, equals('暂停'));
      expect(en.pause, equals('Pause'));
      expect(ja.pause, equals('一時停止'));

      expect(zh.trainerPatternTitle('five_tone', ''), equals('五度琶音 (1-3-5-3-1)'));
      expect(en.trainerPatternTitle('five_tone', ''), equals('5-Tone Arpeggio (1-3-5-3-1)'));
      expect(ja.trainerPatternTitle('five_tone', ''), equals('5音アルペジオ (1-3-5-3-1)'));
    });

    test('Legato transition from E4 to F4 shifts rapidly without deadlock', () async {
      final state = VocalMasterState();
      await state.startListeningMode();
      expect(state.isListeningActive, true);

      // 唱 E4 (MIDI 64)
      PitchDetectorService.instance.simulatePitch(64, freq: 329.63);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(state.listeningMidiNote, 64);

      // 唱连音滑向 F4 (MIDI 65)：第一帧出现过渡
      PitchDetectorService.instance.simulatePitch(65, freq: 349.23);
      await Future.delayed(const Duration(milliseconds: 20));

      // 第二帧连续唱 F4，立即确信迁移并点亮 F4，绝不卡滞在 E4
      PitchDetectorService.instance.simulatePitch(65, freq: 349.23);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(state.listeningMidiNote, 65);

      // 连音继续唱 F4，稳定保持 65
      PitchDetectorService.instance.simulatePitch(65, freq: 349.23);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(state.listeningMidiNote, 65);

      await state.stopListeningMode();
      expect(state.listeningMidiNote, isNull);
    });

    test('RealAudioEngine supports Concert Flute and Solo Violin timbres', () {
      final engine = RealAudioEngine.instance;
      engine.setTimbre('Concert Flute');
      expect(engine.currentTimbre, 'Concert Flute');

      engine.setTimbre('Solo Violin');
      expect(engine.currentTimbre, 'Solo Violin');

      // 播放单音不抛出未捕获异常
      expect(() => engine.playNote(64), returnsNormally);
      expect(() => engine.stopNote(64), returnsNormally);
    });
  });
}
