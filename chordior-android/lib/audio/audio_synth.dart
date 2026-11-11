import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:chordior_flutter/core/theory_engine.dart';
import 'web_audio_stub.dart' if (dart.library.js_interop) 'web_audio_web.dart';

/// 跨平台专业乐理音频合成引擎
class AudioSynth {
  static final AudioSynth instance = AudioSynth._internal();
  AudioSynth._internal();

  static const MethodChannel _nativeChannel = MethodChannel('com.chordior.app/audio');

  double volume = 0.85;
  String timbre = 'Concert Grand'; // Concert Grand, Acoustic Guitar, Fender Rhodes, etc.
  String playMode = 'Simultaneous'; // Simultaneous, Pop Strum, Arp Up, Arp Down
  int arpDelayMs = 100;
  int strumSpeedMs = 35; // Pop Strum 扫弦速度间隔 (毫秒，默认 35ms)
  int octaveShift = 0; // 八度移调: -2, -1, 0, +1, +2
  double sustainDuration = 2.0; // 发声延音时长 (0.8s ~ 4.0s)
  bool dampPreviousChord = true; // 换和弦时柔和衰减上一个和弦的余音，防止交错堆叠混响杂乱

  /// 设置当前音色并触发底层采样预热
  void setTimbre(String val) {
    timbre = val;
    if (kIsWeb) {
      setWebTimbre(val);
    } else {
      try {
        _nativeChannel.invokeMethod('setTimbre', {'timbre': val});
      } catch (_) {}
    }
  }

  /// 48 键钢琴绝对音高 (0=C2 ~ 47=B5) 对应的标准 MIDI Pitch (C2=36, A4=69, B5=83)
  static int pianoIndexToMidiPitch(int pianoIndex) {
    return pianoIndex + 36;
  }

  /// 计算 MIDI 音高对应的频率 (Hz)
  static double midiPitchToFrequency(int midiPitch) {
    return 440.0 * pow(2.0, (midiPitch - 69.0) / 12.0);
  }

  /// 播放钢琴键索引列表 (自动叠加八度移调)
  Future<void> playPianoIndices(List<int> indices) async {
    if (indices.isEmpty) return;
    final pitches = indices.map((idx) => pianoIndexToMidiPitch(idx) + (octaveShift * 12)).toList();
    await playMidiPitches(pitches);
  }

  /// 播放音名和弦 (带智能声部诱导)
  Future<void> playChordNotes(List<String> notes, {List<int>? previousIndices, String strategy = 'Voice-Leading Compact'}) async {
    if (notes.isEmpty) return;
    final indices = notesToPianoIndices(notes, previousIndices: previousIndices, strategy: strategy);
    await playPianoIndices(indices);
  }

  /// 核心播放调度：支持同时发声、流行轻扫弦 (Pop Strum) 与琶音
  Future<void> playMidiPitches(List<int> pitches) async {
    if (pitches.isEmpty) return;

    if (kIsWeb) {
      final freqs = pitches.map(midiPitchToFrequency).toList();
      playWebChord(
        freqs,
        volume,
        timbre,
        mode: playMode,
        speedMs: playMode == 'Pop Strum' ? strumSpeedMs : arpDelayMs,
        sustainSec: sustainDuration,
        dampPrevious: dampPreviousChord,
      );
      return;
    }

    // Android 原生端：优先使用 SoundPool 播放打包进 APK 的真实乐器多采样音源！
    try {
      final speed = (playMode == 'Pop Strum') ? strumSpeedMs : arpDelayMs;
      await _nativeChannel.invokeMethod('playSamples', {
        'pitches': pitches,
        'timbre': timbre,
        'mode': playMode,
        'speedMs': speed,
        'volume': volume,
        'sustainSec': sustainDuration,
        'dampPrevious': dampPreviousChord,
      });
      return;
    } catch (e) {
      debugPrint('Native sample playback error: $e, falling back to PCM');
    }

    // 兜底安全保障：若原生采样偶发异常，使用 PCM 物理合成器
    try {
      final pcmBytes = generateChordPcm16(
        pitches,
        durationSeconds: sustainDuration,
        volume: volume,
        timbre: timbre,
        mode: playMode,
        speedMs: playMode == 'Pop Strum' ? strumSpeedMs : arpDelayMs,
      );
      await _nativeChannel.invokeMethod('playPcm', {
        'bytes': pcmBytes,
        'sampleRate': 44100,
        'dampPrevious': dampPreviousChord,
      });
    } catch (e) {
      debugPrint('Native audio fallback error: $e');
    }
  }

  /// 纯 Dart 高保真 16-bit 44.1kHz PCM 音频数据生成器 (支持多音色泛音特征与毫秒级时序偏移)
  static Uint8List generateChordPcm16(
    List<int> midiPitches, {
    double durationSeconds = 2.0,
    int sampleRate = 44100,
    double volume = 0.85,
    String timbre = 'Concert Grand',
    String mode = 'Simultaneous',
    int speedMs = 35,
  }) {
    if (midiPitches.isEmpty) return Uint8List(0);

    // 确定音符排序与发声时间偏移
    final List<int> sortedPitches = List<int>.from(midiPitches);
    if (mode == 'Pop Strum' || mode == 'Arp Up') {
      sortedPitches.sort();
    } else if (mode == 'Arp Down') {
      sortedPitches.sort((a, b) => b.compareTo(a));
    }

    final totalDelaySeconds = (mode == 'Simultaneous')
        ? 0.0
        : (sortedPitches.length - 1) * (speedMs / 1000.0);
    final totalDuration = durationSeconds + totalDelaySeconds;
    final numSamples = (sampleRate * totalDuration).toInt();
    final pcmSamples = Float64List(numSamples);

    // 根据不同音色微调泛音与包络参数
    double h1 = 0.65, h2 = 0.25, h3 = 0.10, h4 = 0.03;
    double attackSec = 0.015;
    double decaySec = 0.25;
    double sustainLevel = 0.65;

    switch (timbre) {
      case 'Acoustic Guitar':
        h1 = 0.50; h2 = 0.28; h3 = 0.14; h4 = 0.08;
        attackSec = 0.008;
        decaySec = 0.20;
        sustainLevel = 0.45;
        break;
      case 'Nylon Guitar':
        h1 = 0.70; h2 = 0.22; h3 = 0.08; h4 = 0.02;
        attackSec = 0.012;
        decaySec = 0.22;
        sustainLevel = 0.50;
        break;
      case 'Fender Rhodes':
        h1 = 0.75; h2 = 0.18; h3 = 0.07; h4 = 0.00;
        attackSec = 0.010;
        decaySec = 0.30;
        sustainLevel = 0.60;
        break;
      case 'Church Organ':
        h1 = 0.45; h2 = 0.25; h3 = 0.18; h4 = 0.12;
        attackSec = 0.025;
        decaySec = 0.10;
        sustainLevel = 0.85;
        break;
      case 'Celesta & Bells':
        h1 = 0.55; h2 = 0.25; h3 = 0.15; h4 = 0.05;
        attackSec = 0.005;
        decaySec = 0.15;
        sustainLevel = 0.40;
        break;
      default: // Concert Grand
        h1 = 0.65; h2 = 0.25; h3 = 0.10; h4 = 0.03;
        attackSec = 0.015;
        decaySec = 0.25;
        sustainLevel = 0.65;
        break;
    }

    for (int pIdx = 0; pIdx < sortedPitches.length; pIdx++) {
      final pitch = sortedPitches[pIdx];
      final baseFreq = midiPitchToFrequency(pitch);
      final delaySec = (mode == 'Simultaneous') ? 0.0 : pIdx * (speedMs / 1000.0);
      final startSample = (delaySec * sampleRate).toInt();

      for (int i = startSample; i < numSamples; i++) {
        final t = (i - startSample) / sampleRate;
        if (t > durationSeconds) break;

        // ADSR 包络计算
        double env = 1.0;
        if (t < attackSec) {
          env = t / attackSec;
        } else if (t < (attackSec + decaySec)) {
          final progress = (t - attackSec) / decaySec;
          env = 1.0 - (1.0 - sustainLevel) * progress;
        } else {
          final relStart = durationSeconds - 0.35;
          if (t >= relStart) {
            final relProg = (t - relStart) / 0.35;
            env = sustainLevel * (1.0 - relProg.clamp(0.0, 1.0));
          } else {
            env = sustainLevel;
          }
        }
        if (env < 0) env = 0;

        // 谐波叠加
        final sample = (sin(2 * pi * baseFreq * t) * h1 +
                sin(2 * pi * baseFreq * 2 * t) * h2 +
                sin(2 * pi * baseFreq * 3 * t) * h3 +
                sin(2 * pi * baseFreq * 4 * t) * h4) *
            env;

        pcmSamples[i] += sample;
      }
    }

    // 峰值归一化抗削波
    double maxAmp = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final absVal = pcmSamples[i].abs();
      if (absVal > maxAmp) {
        maxAmp = absVal;
      }
    }
    final scale = (maxAmp > 0.0) ? (32000.0 * volume / maxAmp) : 32000.0;

    // 输出 16 位小端 PCM 字节
    final byteData = ByteData(numSamples * 2);
    int offset = 0;
    for (int i = 0; i < numSamples; i++) {
      int val = (pcmSamples[i] * scale).toInt();
      if (val > 32767) val = 32767;
      if (val < -32768) val = -32768;
      byteData.setInt16(offset, val, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// 纯 Dart PCM WAV 数据流生成器 (16-bit 44.1kHz RIFF WAV)
  /// 无论在哪一端均可直接生成无杂音、带包络的 WAV 字节
  static Uint8List generateChordWav(
    List<int> midiPitches, {
    double durationSeconds = 1.6,
    int sampleRate = 44100,
    double volume = 0.8,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final pcmSamples = Float64List(numSamples);

    for (final pitch in midiPitches) {
      final baseFreq = midiPitchToFrequency(pitch);
      for (int i = 0; i < numSamples; i++) {
        final t = i / sampleRate;

        // ADSR 包络：Attack 0.015s, Decay 0.25s, Sustain 0.65, Release 0.4s
        double env = 1.0;
        if (t < 0.015) {
          env = t / 0.015;
        } else if (t < 0.3) {
          env = 1.0 - (1.0 - 0.65) * ((t - 0.015) / 0.285);
        } else {
          final relStart = durationSeconds - 0.4;
          if (t >= relStart) {
            env = 0.65 * (1.0 - (t - relStart) / 0.4);
          } else {
            env = 0.65;
          }
        }
        if (env < 0) env = 0;

        // 泛音合成 (基波 + 二次谐波 + 三次谐波)
        final sample = (sin(2 * pi * baseFreq * t) * 0.65 +
                sin(2 * pi * baseFreq * 2 * t) * 0.25 +
                sin(2 * pi * baseFreq * 3 * t) * 0.1) *
            env;

        pcmSamples[i] += sample;
      }
    }

    // 峰值归一化防止削波失真 (Anti-Clipping Normalization)
    double maxAmp = 0.0;
    for (int i = 0; i < numSamples; i++) {
      if (pcmSamples[i].abs() > maxAmp) {
        maxAmp = pcmSamples[i].abs();
      }
    }
    final scale = (maxAmp > 0.0) ? (32000.0 * volume / maxAmp) : 32000.0;

    // 构建标准 44 字节 RIFF WAV 文件头
    final byteData = ByteData(44 + numSamples * 2);
    _writeWavHeader(byteData, numSamples, sampleRate);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      int val = (pcmSamples[i] * scale).toInt();
      if (val > 32767) val = 32767;
      if (val < -32768) val = -32768;
      byteData.setInt16(offset, val, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  static void _writeWavHeader(ByteData data, int numSamples, int sampleRate) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final subChunk2Size = numSamples * numChannels * bitsPerSample ~/ 8;
    final chunkSize = 36 + subChunk2Size;

    // RIFF
    data.setUint8(0, 0x52);
    data.setUint8(1, 0x49);
    data.setUint8(2, 0x46);
    data.setUint8(3, 0x46);
    data.setUint32(4, chunkSize, Endian.little);
    // WAVE
    data.setUint8(8, 0x57);
    data.setUint8(9, 0x41);
    data.setUint8(10, 0x56);
    data.setUint8(11, 0x45);
    // fmt
    data.setUint8(12, 0x66);
    data.setUint8(13, 0x6D);
    data.setUint8(14, 0x74);
    data.setUint8(15, 0x20);
    data.setUint32(16, 16, Endian.little); // Subchunk1Size
    data.setUint16(20, 1, Endian.little); // AudioFormat (PCM = 1)
    data.setUint16(22, numChannels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, blockAlign, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    // data
    data.setUint8(36, 0x64);
    data.setUint8(37, 0x61);
    data.setUint8(38, 0x74);
    data.setUint8(39, 0x61);
    data.setUint32(40, subChunk2Size, Endian.little);
  }
}
