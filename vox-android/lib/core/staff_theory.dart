import 'key_signature.dart';

/// 五线谱音符谱表类型
enum ClefType { treble, bass, grand }

/// 五线谱渲染音符属性
class StaffNotePosition {
  final int midi;
  final int diatonicStep;       // 以中央 C4 为 0 的自然音阶步进 (C4=0, D4=1, E4=2, F4=3, G4=4, A4=5, B4=6)
  final String accidental;      // 变音记号 '♯', '♭', '♮' 或 ''
  final bool inTrebleStaff;     // 是否应优先绘制在高音谱表上
  final List<int> ledgerLines;  // 需要绘制加线的阶梯列表 (偶数阶梯代表线)

  const StaffNotePosition({
    required this.midi,
    required this.diatonicStep,
    required this.accidental,
    required this.inTrebleStaff,
    required this.ledgerLines,
  });
}

/// 严谨大谱表乐理与空间映射算法
class StaffTheory {
  // 7 个自然音级在八度内的基准半音值 (0=C, 1=D, 2=E, 3=F, 4=G, 5=A, 6=B)
  static const List<int> naturalSemitones = [0, 2, 4, 5, 7, 9, 11];

  /// 升号调系在八度内的 7 个音级基音步进与半音偏置
  // semitone -> (stepInOct, accidental)
  static const List<int> sharpStepsInOctave = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
  static const List<int> flatStepsInOctave  = [0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6];

  /// 计算任意 MIDI 音符在大谱表中的精确乐理步进与加线信息
  /// [keySignature] 当前调号 (默认为 C 大调)
  /// [preferSharp] 当在非特定调号或无明确调性指引时的升降号优先偏好
  static StaffNotePosition calculatePosition(
    int midi, {
    KeySignature keySignature = KeySignature.defaultKey,
    bool preferSharp = true,
  }) {
    final semitone = midi % 12;
    final octave = (midi ~/ 12) - 1; // C4 octave = 4
    final octaveOffset = octave - 4; // C4 offset = 0

    int stepInOct;
    String accidental = '';

    // 1. 检查当前调号下的音级乐理规则
    final keyInfo = _resolveInKey(semitone, keySignature, preferSharp);
    stepInOct = keyInfo.stepInOctave;
    accidental = keyInfo.accidental;

    final diatonicStep = (octaveOffset * 7) + stepInOct;

    // 谱表归属判断：
    // C4 (MIDI 60, diatonicStep 0) 以上归入高音谱表；低于 C4 归入低音谱表；
    final inTreble = diatonicStep >= 0;

    // 加线判定：
    // 高音谱表范围：第 1 线 E4 (step 2) 到 第 5 线 F5 (step 10)
    // 低音谱表范围：第 1 线 G2 (step -10) 到 第 5 线 A3 (step -2)
    final ledgerLines = <int>[];

    if (inTreble) {
      // 高音谱表下加线 (C4 及其以下)：step <= 0 (偶数阶梯加线)
      if (diatonicStep <= 0) {
        for (int s = 0; s >= diatonicStep; s -= 2) {
          ledgerLines.add(s);
        }
      }
      // 高音谱表上加线 (A5 step 12 及其以上)：step >= 12
      if (diatonicStep >= 12) {
        for (int s = 12; s <= diatonicStep; s += 2) {
          ledgerLines.add(s);
        }
      }
    } else {
      // 低音谱表上加线 (C4 step 0 及其以上)：step >= 0
      if (diatonicStep >= 0) {
        for (int s = 0; s <= diatonicStep; s += 2) {
          ledgerLines.add(s);
        }
      }
      // 低音谱表下加线 (E2 step -12 及其以下)：step <= -12
      if (diatonicStep <= -12) {
        for (int s = -12; s >= diatonicStep; s -= 2) {
          ledgerLines.add(s);
        }
      }
    }

    return StaffNotePosition(
      midi: midi,
      diatonicStep: diatonicStep,
      accidental: accidental,
      inTrebleStaff: inTreble,
      ledgerLines: ledgerLines,
    );
  }

  /// 根据调号与升降号偏好计算半音对应的八度阶梯 (0~6) 及临时记号 ('', '♯', '♭', '♮')
  static _KeyStepResult _resolveInKey(int semitone, KeySignature key, bool preferSharp) {
    // 1. 若为自然大调 C (0 升降)
    if (key.accidentalCount == 0) {
      final isBlack = (semitone == 1 || semitone == 3 || semitone == 6 || semitone == 8 || semitone == 10);
      if (!isBlack) {
        // 白键自然音
        final step = naturalSemitones.indexOf(semitone);
        return _KeyStepResult(stepInOctave: step, accidental: '');
      } else {
        // 黑键变音：严格根据 preferSharp 映射自然音级
        if (preferSharp) {
          final step = sharpStepsInOctave[semitone];
          return _KeyStepResult(stepInOctave: step, accidental: '♯');
        } else {
          final step = flatStepsInOctave[semitone];
          return _KeyStepResult(stepInOctave: step, accidental: '♭');
        }
      }
    }

    // 2. 升号调系
    if (key.isSharp) {
      // 升号调各阶梯所对应的升高音：
      // F#(6)=step 3, C#(1)=step 0, G#(8)=step 4, D#(3)=step 1, A#(10)=step 5, E#(5)=step 2, B#(0)=step 6
      const sharpStepOrder = [3, 0, 4, 1, 5, 2, 6];
      const sharpPitchClasses = [6, 1, 8, 3, 10, 5, 0]; // 各升号的半音值
      const naturalPitchClasses = [5, 0, 7, 2, 9, 4, 11]; // 对应的自然半音值 (F, C, G, D, A, E, B)

      final count = key.accidentalCount;
      // 检查是否恰好命中调号内的升音
      for (int i = 0; i < count; i++) {
        if (semitone == sharpPitchClasses[i]) {
          // 在调号内已有升号，无需临时记号
          return _KeyStepResult(stepInOctave: sharpStepOrder[i], accidental: '');
        }
      }

      // 检查是否弹了调号已被升高的自然音 (需要还原记号 ♮)
      for (int i = 0; i < count; i++) {
        if (semitone == naturalPitchClasses[i]) {
          return _KeyStepResult(stepInOctave: sharpStepOrder[i], accidental: '♮');
        }
      }

      // 检查是否为剩余的调内自然音
      final natIdx = naturalSemitones.indexOf(semitone);
      if (natIdx != -1) {
        return _KeyStepResult(stepInOctave: natIdx, accidental: '');
      }

      // 属于调外变音，根据 preferSharp 判定
      if (preferSharp) {
        return _KeyStepResult(stepInOctave: sharpStepsInOctave[semitone], accidental: '♯');
      } else {
        return _KeyStepResult(stepInOctave: flatStepsInOctave[semitone], accidental: '♭');
      }
    }

    // 3. 降号调系
    final flatCount = -key.accidentalCount;
    // 降号次序: Bb(10)=step 6, Eb(3)=step 2, Ab(8)=step 5, Db(1)=step 1, Gb(6)=step 4, Cb(11)=step 0, Fb(4)=step 3
    const flatStepOrder = [6, 2, 5, 1, 4, 0, 3];
    const flatPitchClasses = [10, 3, 8, 1, 6, 11, 4];
    const naturalPitchClasses = [11, 4, 9, 2, 7, 0, 5]; // 对应的自然半音值 (B, E, A, D, G, C, F)

    // 检查是否恰好命中调号内的降音
    for (int i = 0; i < flatCount; i++) {
      if (semitone == flatPitchClasses[i]) {
        // 在调号内已有降号，无需临时记号
        return _KeyStepResult(stepInOctave: flatStepOrder[i], accidental: '');
      }
    }

    // 检查是否弹了已被降下的自然音 (需要还原记号 ♮)
    for (int i = 0; i < flatCount; i++) {
      if (semitone == naturalPitchClasses[i]) {
        return _KeyStepResult(stepInOctave: flatStepOrder[i], accidental: '♮');
      }
    }

    // 检查是否为剩余的调内自然音
    final natIdx = naturalSemitones.indexOf(semitone);
    if (natIdx != -1) {
      return _KeyStepResult(stepInOctave: natIdx, accidental: '');
    }

    // 属于调外变音，降号调默认优先降号，但尊重 preferSharp
    if (preferSharp) {
      return _KeyStepResult(stepInOctave: sharpStepsInOctave[semitone], accidental: '♯');
    } else {
      return _KeyStepResult(stepInOctave: flatStepsInOctave[semitone], accidental: '♭');
    }
  }
}

class _KeyStepResult {
  final int stepInOctave;
  final String accidental;

  const _KeyStepResult({required this.stepInOctave, required this.accidental});
}
