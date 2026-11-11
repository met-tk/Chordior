import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'web_audio_stub.dart' if (dart.library.js_interop) 'web_audio_web.dart';

/// 乐器音色定义
class InstrumentInfo {
  final String id;
  final String name;
  final String icon;
  final IconData iconData;
  final String assetDir;
  final String description;

  const InstrumentInfo({
    required this.id,
    required this.name,
    this.icon = '',
    required this.iconData,
    required this.assetDir,
    required this.description,
  });
}

/// 纯真实采样高保真音频调度引擎 (100% 真实声学实录，彻底拒绝合成器)
/// 双轨自适应：
/// 1. Android 原生环境：通过 MethodChannel 直通 48 路硬件混音 SoundPool (< 1ms)
/// 2. Web 浏览器环境：通过 Web Audio API 极速加载并重采样真实 .mp3 录音切片
class RealAudioEngine {
  static final RealAudioEngine instance = RealAudioEngine._internal();
  RealAudioEngine._internal();

  static const MethodChannel _nativeChannel = MethodChannel('com.chordior.vocal/audio');

  // 支持的真实乐器清单 (全面采用内置 Material 矢量图标，彻底消除 emoji 兼容性问题)
  static const List<InstrumentInfo> instruments = [
    InstrumentInfo(
      id: 'Concert Grand',
      name: '大三角钢琴',
      iconData: Icons.piano_rounded,
      assetDir: 'piano',
      description: '施坦威 D 型音乐会大三角钢琴实录，琴槌敲击钢丝的丰富自然泛音。',
    ),
    InstrumentInfo(
      id: 'Church Organ',
      name: '教堂管风琴',
      iconData: Icons.music_note_rounded,
      assetDir: 'organ',
      description: '大教堂实体管风琴实录，神圣肃穆的气鸣长音与自然空间混响。',
    ),
    InstrumentInfo(
      id: 'Concert Flute',
      name: '音乐会长笛',
      iconData: Icons.air_rounded,
      assetDir: 'flute',
      description: '交响乐团长笛真声实录，包含气流呼吸起音与清亮纯净的高频共鸣。',
    ),
    InstrumentInfo(
      id: 'Solo Violin',
      name: '独奏小提琴',
      iconData: Icons.audiotrack_rounded,
      assetDir: 'violin',
      description: '独奏提琴实录，包含弓毛摩擦松香质感与温暖的木质共鸣箱体。',
    ),
    InstrumentInfo(
      id: 'Fender Rhodes',
      name: '经典电钢琴',
      iconData: Icons.electric_bolt_rounded,
      assetDir: 'rhodes',
      description: '复古 Rhodes 电钢琴实录，清润饱满的铃音与电磁拾音音色。',
    ),
    InstrumentInfo(
      id: 'Acoustic Guitar',
      name: '民谣钢弦吉他',
      iconData: Icons.queue_music_rounded,
      assetDir: 'guitar_steel',
      description: '原声民谣木吉他实录，清脆明亮的指弹拨弦颗粒感。',
    ),
    InstrumentInfo(
      id: 'Celesta & Bells',
      name: '钢片琴 / 钟琴',
      iconData: Icons.notifications_active_rounded,
      assetDir: 'celesta',
      description: '击弦钢片琴实录，晶莹剔透的高音空灵钟音。',
    ),
    InstrumentInfo(
      id: 'Virtual Singer',
      name: '虚拟歌姬',
      iconData: Icons.mic_external_on_rounded,
      assetDir: 'diva_voice',
      description: '基于高保真虚拟歌姬 C1-C6 阶梯原声全音符切片提取，音色通透纯净、灵动唯美。',
    ),
  ];

  String currentTimbre = 'Concert Grand';
  double volume = 1.0;
  double sustainSec = 3.0;

  /// 切换乐器音色
  void setTimbre(String timbre) {
    currentTimbre = timbre;
    if (kIsWeb) {
      webSetTimbre(timbre);
    } else {
      unawaited(
        _nativeChannel.invokeMethod('setTimbre', {'timbre': timbre}).catchError((_) {}),
      );
    }
  }

  /// 极速单音按键触发 (Android 原生 SoundPool / Web Audio API)
  void playNote(int midi, {bool dampPrevious = false}) {
    final noteSustain = (currentTimbre == 'Church Organ' || currentTimbre == 'Concert Flute' || currentTimbre == 'Solo Violin')
        ? 8.0
        : sustainSec;
    if (kIsWeb) {
      webPlayNote(midi, volume, currentTimbre, noteSustain, dampPrevious);
    } else {
      unawaited(
        _nativeChannel.invokeMethod('playSingleNote', {
          'midi': midi,
          'timbre': currentTimbre,
          'volume': volume,
          'sustainSec': noteSustain,
          'dampPrevious': dampPrevious,
        }).catchError((e) {
          debugPrint('playSingleNote notice: $e');
        }),
      );
    }
  }

  /// 按键释放 (Note Off) 触发平滑阻尼消音
  void stopNote(int midi) {
    if (kIsWeb) {
      webStopNote(midi);
    } else {
      unawaited(
        _nativeChannel.invokeMethod('stopSingleNote', {'midi': midi}).catchError((_) {}),
      );
    }
  }

  /// 播放琶音或练声音阶序列 (支持 dampPrevious 防混叠防浑浊渐弱)
  Future<void> playSequence(
    List<int> pitches, {
    int speedMs = 120,
    String mode = 'Ascending',
    bool dampPrevious = false,
  }) async {
    if (pitches.isEmpty) return;

    if (kIsWeb) {
      // Web 端定时连续触发
      for (int i = 0; i < pitches.length; i++) {
        final shouldDamp = (mode != 'Simultaneous' && i > 0) ? dampPrevious : false;
        webPlayNote(pitches[i], volume, currentTimbre, sustainSec, shouldDamp);
        if (i < pitches.length - 1) {
          await Future.delayed(Duration(milliseconds: speedMs));
        }
      }
    } else {
      unawaited(
        _nativeChannel.invokeMethod('playSamples', {
          'pitches': pitches,
          'timbre': currentTimbre,
          'mode': mode,
          'speedMs': speedMs,
          'volume': volume,
          'sustainSec': sustainSec,
          'dampPrevious': dampPrevious,
        }).catchError((e) {
          debugPrint('playSamples notice: $e');
        }),
      );
    }
  }

  /// 停止全部正在播放的声音
  void stopAll() {
    if (kIsWeb) {
      webStopAll();
    } else {
      unawaited(
        _nativeChannel.invokeMethod('stopAll').catchError((_) {}),
      );
    }
  }
}
