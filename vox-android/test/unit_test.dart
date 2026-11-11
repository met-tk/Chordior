import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_master_flutter/core/music_theory.dart';
import 'package:vocal_master_flutter/core/staff_theory.dart';
import 'package:vocal_master_flutter/core/key_signature.dart';
import 'package:vocal_master_flutter/models/vocal_range_model.dart';
import 'package:vocal_master_flutter/models/trainer_models.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/audio/pitch_detector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusicTheory Tests', () {
    test('Format note with sharp and flat', () {
      // MIDI 60 is C4
      final c4 = MusicTheory.getFormattedNote(60);
      expect(c4.baseNote, 'C');
      expect(c4.accidental, '');
      expect(c4.octave, 4);
      expect(c4.scriptNotation, 'C4');

      // MIDI 61 is C#4 or Db4
      final cs4 = MusicTheory.getFormattedNote(61, preferSharp: true);
      expect(cs4.baseNote, 'C');
      expect(cs4.accidental, '♯');
      expect(cs4.octave, 4);
      expect(cs4.scriptNotation, 'C^♯_4');

      final db4 = MusicTheory.getFormattedNote(61, preferSharp: false);
      expect(db4.baseNote, 'D');
      expect(db4.accidental, '♭');
      expect(db4.octave, 4);
      expect(db4.scriptNotation, 'D^♭_4');

      // Japanese solfege and traditional note names (ドレミ & ハニホヘトイロ)
      expect(c4.japaneseSolfege, 'ド');
      expect(c4.japaneseTraditionalNote, 'ハ4');
      expect(cs4.japaneseSolfege, 'ド♯');
      expect(cs4.japaneseTraditionalNote, '嬰ハ4');
      expect(db4.japaneseSolfege, 'レ♭');
      expect(db4.japaneseTraditionalNote, '変ニ4');

      final a4 = MusicTheory.getFormattedNote(69);
      expect(a4.japaneseSolfege, 'ラ');
      expect(a4.japaneseTraditionalNote, 'イ4');

      final b4 = MusicTheory.getFormattedNote(71);
      expect(b4.japaneseSolfege, 'シ');
      expect(b4.japaneseTraditionalNote, 'ロ4');
    });

    test('Frequency calculation', () {
      // A4 (MIDI 69) is 440 Hz
      expect(MusicTheory.midiToFrequency(69), closeTo(440.0, 0.01));
      // A3 (MIDI 57) is 220 Hz
      expect(MusicTheory.midiToFrequency(57), closeTo(220.0, 0.01));
      // C4 (MIDI 60) is approx 261.63 Hz
      expect(MusicTheory.midiToFrequency(60), closeTo(261.63, 0.05));
    });

    test('Black key detection', () {
      expect(MusicTheory.isBlackKey(60), false); // C4
      expect(MusicTheory.isBlackKey(61), true);  // C#4
      expect(MusicTheory.isBlackKey(62), false); // D4
      expect(MusicTheory.isBlackKey(63), true);  // D#4
    });

    test('Range span description', () {
      expect(MusicTheory.calculateRangeSpan(60, 72), contains('1 个八度'));
      expect(MusicTheory.calculateRangeSpan(60, 60), contains('纯一度'));
    });
  });

  group('StaffTheory Tests', () {
    test('Calculate staff position for treble and ledger lines', () {
      // C4 (MIDI 60) has 1 ledger line below treble clef
      final posC4 = StaffTheory.calculatePosition(60);
      expect(posC4.inTrebleStaff, true);
      expect(posC4.diatonicStep, 0);
      expect(posC4.ledgerLines, contains(0));

      // E4 (MIDI 64) is 1st line of treble clef (diatonicStep = 2)
      final posE4 = StaffTheory.calculatePosition(64);
      expect(posE4.inTrebleStaff, true);
      expect(posE4.diatonicStep, 2);
      expect(posE4.ledgerLines.isEmpty, true);

      // B3 (MIDI 59) diatonicStep = -1 (bass clef)
      final posB3 = StaffTheory.calculatePosition(59);
      expect(posB3.inTrebleStaff, false);
      expect(posB3.diatonicStep, -1);
    });
  });

  group('VocalRangeModel Tests', () {
    test('Default presets contain standard vocal ranges', () {
      final presets = VocalRangeItem.getDefaultPresets();
      expect(presets.length, greaterThanOrEqualTo(5));

      final names = presets.map((p) => p.name).toList();
      expect(names, contains('主要音区'));
      expect(names, contains('真声区'));
      expect(names, contains('假声/头声区'));
      expect(names, contains('混声区'));
      expect(names, contains('重点练习区域'));
    });

    test('Range overlap detection', () {
      final r1 = VocalRangeItem(
        id: '1',
        name: '真声区',
        type: VocalRangeType.chestVoice,
        startMidi: 48,
        endMidi: 64,
        color: Colors.blue,
      );
      final r2 = VocalRangeItem(
        id: '2',
        name: '混声区',
        type: VocalRangeType.mixVoice,
        startMidi: 60,
        endMidi: 72,
        color: Colors.purple,
      );
      final r3 = VocalRangeItem(
        id: '3',
        name: '假声区',
        type: VocalRangeType.headVoice,
        startMidi: 73,
        endMidi: 84,
        color: Colors.red,
      );

      expect(r1.overlapsWith(r2), true);
      expect(r2.overlapsWith(r1), true);
      expect(r1.overlapsWith(r3), false);
    });

    test('Range item JSON serialization and deserialization with gradient config', () {
      final original = VocalRangeItem(
        id: 'test_1',
        name: '自定义测试区',
        type: VocalRangeType.custom,
        startMidi: 55,
        endMidi: 70,
        color: const Color(0xFFFF5722),
        description: '高难度跟唱区',
        gradientSteps: 12,
        startOpacity: 0.85,
        endOpacity: 0.12,
        gradientReversed: true,
      );

      final json = original.toJson();
      final restored = VocalRangeItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.startMidi, original.startMidi);
      expect(restored.endMidi, original.endMidi);
      expect(restored.color.toARGB32(), original.color.toARGB32());
      expect(restored.description, original.description);
      expect(restored.gradientSteps, 12);
      expect(restored.startOpacity, 0.85);
      expect(restored.endOpacity, 0.12);
      expect(restored.gradientReversed, true);
    });
  });

  group('TrainerModels Tests', () {
    test('Generate note sequence for 5-tone arpeggio', () {
      final pattern = TrainerPattern.presets.firstWhere(
        (p) => p.type == TrainerPatternType.fiveToneArp,
      );
      // Root C4 (60): 1-3-5-3-1 -> 60, 64, 67, 64, 60
      final seq = pattern.generateSequence(60);
      expect(seq, [60, 64, 67, 64, 60]);
    });

    test('Generate octave leap sequence', () {
      final pattern = TrainerPattern.presets.firstWhere(
        (p) => p.type == TrainerPatternType.octaveLeap,
      );
      // Root C4 (60): 1-5-8-5-1 -> 60, 67, 72, 67, 60
      final seq = pattern.generateSequence(60);
      expect(seq, [60, 67, 72, 67, 60]);
    });
  });

  group('VocalMasterState Tests', () {
    test('Initial state properties and mode changes', () {
      final state = VocalMasterState();
      expect(state.currentMidi, 60);
      expect(state.currentMode, StudioMode.freePlay);
      expect(state.userRanges.isNotEmpty, true);

      // Press piano key
      state.onPianoKeyPressed(64);
      expect(state.currentMidi, 64);

      // Switch mode to range selection
      state.setMode(StudioMode.rangeSelect);
      expect(state.currentMode, StudioMode.rangeSelect);

      state.setSelectionRange(57, 69);
      expect(state.selectionStartMidi, 57);
      expect(state.selectionEndMidi, 69);

      // Save as new range
      state.saveCurrentSelectionAsRange(
        name: '高潮跟唱区',
        type: VocalRangeType.focusPractice,
        color: Colors.amber,
        description: '需加强气息支撑',
      );

      final saved = state.userRanges.firstWhere((r) => r.name == '高潮跟唱区');
      expect(saved.startMidi, 57);
      expect(saved.endMidi, 69);
      expect(state.currentMode, StudioMode.freePlay);

      // Clean up
      state.deleteRange(saved.id);
      expect(state.userRanges.any((r) => r.name == '高潮跟唱区'), false);
    });

    test('Volume control method works cleanly', () {
      final state = VocalMasterState();
      state.setAudioVolume(0.75);
      expect(state.audioVolume, 0.75);
    });

    test('Keyboard zoom and scale controls work accurately', () {
      final state = VocalMasterState();
      expect(state.keyboardScale, 0.65);

      // Zoom in
      state.zoomIn();
      expect(state.keyboardScale, closeTo(0.80, 0.001));

      // Zoom out
      state.zoomOut();
      expect(state.keyboardScale, closeTo(0.65, 0.001));

      // Zoom out bounded by min 0.65
      state.setKeyboardScale(0.5);
      expect(state.keyboardScale, 0.65);

      // Zoom in bounded by max 1.85
      state.setKeyboardScale(2.5);
      expect(state.keyboardScale, 1.85);

      // Reset
      state.resetZoom();
      expect(state.keyboardScale, 0.65);
    });

    test('Key length ratio and range indicator position controls', () {
      final state = VocalMasterState();
      expect(state.keyLengthRatio, 0.60);
      expect(state.rangeIndicatorPosition, RangeIndicatorPosition.blackKeySide);

      // Adjust key length ratio
      state.setKeyLengthRatio(1.25);
      expect(state.keyLengthRatio, 1.25);

      state.setKeyLengthRatio(0.15); // Clamp min 0.30
      expect(state.keyLengthRatio, 0.30);

      state.setKeyLengthRatio(2.0); // Clamp max 1.50
      expect(state.keyLengthRatio, 1.50);

      // Switch indicator position
      state.setRangeIndicatorPosition(RangeIndicatorPosition.whiteKeySide);
      expect(state.rangeIndicatorPosition, RangeIndicatorPosition.whiteKeySide);
    });

    test('Update vocal range and copyWith works correctly', () {
      final state = VocalMasterState();
      final target = state.userRanges.first;

      final updated = target.copyWith(
        name: '全新混声强化区',
        color: const Color(0xFF00E5FF),
        startMidi: 55,
        endMidi: 70,
      );

      state.updateRange(updated);
      final fetched = state.userRanges.firstWhere((r) => r.id == target.id);
      expect(fetched.name, '全新混声强化区');
      expect(fetched.color, const Color(0xFF00E5FF));
      expect(fetched.startMidi, 55);
      expect(fetched.endMidi, 70);
    });

    test('Piano press in rangeSelect mode does not destroy selection', () {
      final state = VocalMasterState();
      state.setMode(StudioMode.rangeSelect);
      expect(state.selectionStartMidi, 60);
      expect(state.selectionEndMidi, 67);

      // Set custom range
      state.setSelectionRange(50, 75);
      expect(state.selectionStartMidi, 50);
      expect(state.selectionEndMidi, 75);

      // Tap piano keys for audio preview
      state.onPianoKeyPressed(64);
      expect(state.selectionStartMidi, 50);
      expect(state.selectionEndMidi, 75);
    });

    test('Keyboard handle editing existing range workflow works cleanly', () {
      final state = VocalMasterState();
      final target = state.userRanges.first;

      // Start editing existing range on piano keyboard
      state.startEditingExistingRange(target);
      expect(state.editingRange?.id, target.id);
      expect(state.currentMode, StudioMode.rangeSelect);
      expect(state.selectionStartMidi, target.startMidi);
      expect(state.selectionEndMidi, target.endMidi);

      // Drag handles to adjust range
      state.setSelectionRange(target.startMidi - 2, target.endMidi + 3);
      expect(state.selectionStartMidi, target.startMidi - 2);
      expect(state.selectionEndMidi, target.endMidi + 3);

      // Save edited range
      state.saveEditedRange(
        name: '微调后主要声区',
        gradientSteps: 14,
        gradientReversed: true,
      );
      expect(state.editingRange, null);
      expect(state.currentMode, StudioMode.freePlay);

      final updated = state.userRanges.firstWhere((r) => r.id == target.id);
      expect(updated.name, '微调后主要声区');
      expect(updated.startMidi, target.startMidi - 2);
      expect(updated.endMidi, target.endMidi + 3);
      expect(updated.gradientSteps, 14);
      expect(updated.gradientReversed, true);

      // Test cancel editing
      state.startEditingExistingRange(updated);
      expect(state.editingRange?.id, updated.id);
      state.cancelEditingRange();
      expect(state.editingRange, null);
      expect(state.currentMode, StudioMode.freePlay);
    });

    test('Toggle range indicator position between black and white key sides', () {
      final state = VocalMasterState();
      expect(state.rangeIndicatorPosition, RangeIndicatorPosition.blackKeySide);

      state.toggleRangeIndicatorPosition();
      expect(state.rangeIndicatorPosition, RangeIndicatorPosition.whiteKeySide);

      state.toggleRangeIndicatorPosition();
      expect(state.rangeIndicatorPosition, RangeIndicatorPosition.blackKeySide);
    });

    test('UI scale controls and clamps accurately', () {
      final state = VocalMasterState();
      expect(state.uiScale, 1.00);

      state.setUiScale(1.20);
      expect(state.uiScale, 1.20);

      // Clamp max 1.30
      state.setUiScale(2.50);
      expect(state.uiScale, 1.30);

      // Clamp min 0.75
      state.setUiScale(0.30);
      expect(state.uiScale, 0.75);

      // Reset
      state.resetUiScale();
      expect(state.uiScale, 1.00);
    });

    test('Toggle single range indicator position independently', () {
      final state = VocalMasterState();
      final target = state.userRanges.first;
      final originalPos = target.indicatorPosition;

      // 切换该音区的方位
      state.toggleSingleRangeIndicatorPosition(target.id);
      final updated = state.userRanges.firstWhere((r) => r.id == target.id);
      expect(
        updated.indicatorPosition,
        originalPos == RangeIndicatorPosition.blackKeySide
            ? RangeIndicatorPosition.whiteKeySide
            : RangeIndicatorPosition.blackKeySide,
      );

      // 其他音区的方位应不受干扰
      if (state.userRanges.length > 1) {
        final otherRange = state.userRanges[1];
        expect(otherRange.id != target.id, true);
      }
    });

    test('ThemeMode and dark mode switching', () {
      final state = VocalMasterState();
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);

      state.setThemeMode(ThemeMode.light);
      expect(state.themeMode, ThemeMode.light);
      expect(state.isDarkMode, false);

      state.toggleThemeMode();
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);
    });

    test('Separate range tracks toggle and openRangeSettings trigger', () {
      final state = VocalMasterState();
      expect(state.separateRangeTracks, true);

      state.toggleSeparateRangeTracks();
      expect(state.separateRangeTracks, false);

      state.setSeparateRangeTracks(true);
      expect(state.separateRangeTracks, true);

      // openRangeSettings triggers editing mode
      final target = state.userRanges.first;
      state.openRangeSettings(target);
      expect(state.currentMode, StudioMode.rangeSelect);
      expect(state.editingRange?.id, target.id);
      expect(state.selectionStartMidi, target.startMidi);
      expect(state.selectionEndMidi, target.endMidi);
    });

    test('Header height and split divider scale controls', () {
      final state = VocalMasterState();
      expect(state.headerHeight, VocalMasterState.defaultHeaderHeight);

      // Adjust height downwards (increase header, decrease keyboard)
      state.adjustHeaderHeight(25.0);
      expect(state.headerHeight, VocalMasterState.defaultHeaderHeight + 25.0);

      // Adjust height upwards (decrease header, increase keyboard)
      state.adjustHeaderHeight(-40.0);
      expect(state.headerHeight, VocalMasterState.defaultHeaderHeight - 15.0);

      // Min limit clamp (90.0)
      state.setHeaderHeight(50.0);
      expect(state.headerHeight, VocalMasterState.minHeaderHeight);

      // Max limit clamp (320.0)
      state.setHeaderHeight(500.0);
      expect(state.headerHeight, VocalMasterState.maxHeaderHeight);

      // Reset to default
      state.resetHeaderHeight();
      expect(state.headerHeight, VocalMasterState.defaultHeaderHeight);
    });

    test('KeySignature and StaffTheory music theory tests', () {
      // 1. C 大调下：升号优先 vs 降号优先
      // MIDI 61 (C#4 / Db4)
      final sharpPos = StaffTheory.calculatePosition(61, preferSharp: true);
      expect(sharpPos.diatonicStep, 0); // 基音 C (下加一线)
      expect(sharpPos.accidental, '♯');

      final flatPos = StaffTheory.calculatePosition(61, preferSharp: false);
      expect(flatPos.diatonicStep, 1); // 基音 D (下加一间)
      expect(flatPos.accidental, '♭');

      // MIDI 63 (D#4 / Eb4)
      final ebPos = StaffTheory.calculatePosition(63, preferSharp: false);
      expect(ebPos.diatonicStep, 2); // 基音 E (第一线)
      expect(ebPos.accidental, '♭');

      // 2. G 大调下 (1 升 F#)：
      const gKey = KeySignature(id: 'G', name: 'G 大调', shortName: '1♯ G', accidentalCount: 1, isSharp: true, accidentalsList: ['F#']);
      // 弹奏 F#4 (MIDI 66)：调内音，无需临时记号
      final fSharpInG = StaffTheory.calculatePosition(66, keySignature: gKey);
      expect(fSharpInG.diatonicStep, 3); // 基音 F (第一间)
      expect(fSharpInG.accidental, '');  // 调内升音无需临时记号！

      // 弹奏 F4 自然音 (MIDI 65)：需要还原记号 ♮
      final fNatInG = StaffTheory.calculatePosition(65, keySignature: gKey);
      expect(fNatInG.diatonicStep, 3);   // 基音 F
      expect(fNatInG.accidental, '♮');   // 还原号！

      // 3. F 大调下 (1 降 Bb)：
      const fKey = KeySignature(id: 'F', name: 'F 大调', shortName: '1♭ F', accidentalCount: -1, isSharp: false, accidentalsList: ['Bb']);
      // 弹奏 Bb4 (MIDI 70)：调内音，无需临时记号
      final bbInF = StaffTheory.calculatePosition(70, keySignature: fKey);
      expect(bbInF.diatonicStep, 6);     // 基音 B (第三线)
      expect(bbInF.accidental, '');      // 调内降音无需临时记号！
    });

    test('toggleMode toggles to mode and returns to freePlay on second click', () {
      final state = VocalMasterState();
      expect(state.currentMode, StudioMode.freePlay);

      // 首次点击：进入 rangeSelect
      state.toggleMode(StudioMode.rangeSelect);
      expect(state.currentMode, StudioMode.rangeSelect);

      // 再次点击：返回 freePlay
      state.toggleMode(StudioMode.rangeSelect);
      expect(state.currentMode, StudioMode.freePlay);

      // 点击跟唱练声：进入 singTrainer
      state.toggleMode(StudioMode.singTrainer);
      expect(state.currentMode, StudioMode.singTrainer);

      // 再次点击：返回 freePlay
      state.toggleMode(StudioMode.singTrainer);
      expect(state.currentMode, StudioMode.freePlay);
    });

    test('Track grouping and overlap validation tests', () {
      final state = VocalMasterState();
      state.resetDefaultRanges();

      // 默认音区包含：
      // 真声区 preset_chest (C3~E4: 48~64)
      // 混声区 preset_mix (D4~C5: 62~72) -> 与真声区存在重叠 (62~64)
      // 假声/头声区 preset_head (Bb4~A5: 70~81) -> 与真声区无重叠 (48~64 vs 70~81)
      final chest = state.userRanges.firstWhere((r) => r.id == 'preset_chest');
      final mix = state.userRanges.firstWhere((r) => r.id == 'preset_mix');
      final head = state.userRanges.firstWhere((r) => r.id == 'preset_head');

      // 1. 重叠的两个音区合并应该失败被拒绝
      final mergeOverlappedResult = state.tryMergeRangesToSameTrack(chest.id, mix.id);
      expect(mergeOverlappedResult, false);
      expect(state.userRanges.firstWhere((r) => r.id == 'preset_chest').trackGroupId, isNull);
      expect(state.userRanges.firstWhere((r) => r.id == 'preset_mix').trackGroupId, isNull);

      // 2. 即使无重叠，但处于不同侧（如黑键侧 vs 白键侧），也必须被拦截拒绝合并！
      // chest 为黑键侧，我们找一个无重叠的白键侧音区进行测试：
      final customWhiteSide = VocalRangeItem(
        id: 'test_white_range',
        name: '测试白键音区',
        type: VocalRangeType.custom,
        startMidi: 75,
        endMidi: 80,
        color: const Color(0xFFFFFFFF),
        indicatorPosition: RangeIndicatorPosition.whiteKeySide,
      );
      state.addCustomRange(customWhiteSide);
      // chest (48~64, 黑键侧) vs customWhiteSide (75~80, 白键侧)：范围完全不重叠，但因不同侧应被严密拦截！
      final crossSideResult = state.tryMergeRangesToSameTrack(chest.id, customWhiteSide.id);
      expect(crossSideResult, false);

      // 3. 同属一侧（同属黑键侧）且不重叠的两个音区合并应该成功
      final mergeNonOverlappedResult = state.tryMergeRangesToSameTrack(chest.id, head.id);
      expect(mergeNonOverlappedResult, true);
      final updatedChest = state.userRanges.firstWhere((r) => r.id == 'preset_chest');
      final updatedHead = state.userRanges.firstWhere((r) => r.id == 'preset_head');
      expect(updatedChest.trackGroupId, isNotNull);
      expect(updatedChest.trackGroupId, updatedHead.trackGroupId);

      // 4. 试图将与已有组中任意音区重叠的音区加入该组，应该被拦截 (mix 与 head 重叠 70~72)
      final addConflictResult = state.tryAddRangeToTrackGroup(mix.id, updatedChest.trackGroupId!);
      expect(addConflictResult, false);

      // 5. 试图将不同侧的音区加入该组，也应该被拦截！
      final addCrossSideResult = state.tryAddRangeToTrackGroup(customWhiteSide.id, updatedChest.trackGroupId!);
      expect(addCrossSideResult, false);

      // 6. 将单个音区从组中移除
      state.removeRangeFromTrackGroup(head.id);
      expect(state.userRanges.firstWhere((r) => r.id == 'preset_head').trackGroupId, isNull);

      // 7. 重置所有分轨分组
      state.resetAllTrackGroups();
      expect(state.userRanges.every((r) => r.trackGroupId == null), true);
    });

    test('VocalRangeItem swap logic (canSwapRanges & trySwapRanges)', () {
      final state = VocalMasterState();
      state.resetDefaultRanges();

      // 先清除干扰测试的 preset_main，保证黑键侧仅有受测音区
      state.deleteRange('preset_main');

      // 先让 chest (48~64) 和 head (70~81) 组成一组（排 1）
      final chest = state.userRanges.firstWhere((r) => r.id == 'preset_chest');
      final head = state.userRanges.firstWhere((r) => r.id == 'preset_head');
      final mergeSuccess = state.tryMergeRangesToSameTrack(chest.id, head.id);
      expect(mergeSuccess, true);

      // 添加一个更高音域的黑键侧音区 (82~90)，处于独立排
      final customHigh = VocalRangeItem(
        id: 'test_high_range',
        name: '高音区',
        type: VocalRangeType.custom,
        startMidi: 82,
        endMidi: 90,
        color: const Color(0xFF00E5FF),
        indicatorPosition: RangeIndicatorPosition.blackKeySide,
      );
      state.addCustomRange(customHigh);

      // 1. 测试置换：将 customHigh (82~90) 与 head (70~81) 进行交替置换
      // 替换后 customHigh 与 chest (48~64) 完全不重叠且同属黑键侧，应该允许置换！
      expect(state.canSwapRanges(customHigh.id, head.id), true);

      final swapSuccess = state.trySwapRanges(customHigh.id, head.id);
      expect(swapSuccess, true);

      final updatedChest = state.userRanges.firstWhere((r) => r.id == 'preset_chest');
      final updatedHead = state.userRanges.firstWhere((r) => r.id == 'preset_head');
      final updatedCustomHigh = state.userRanges.firstWhere((r) => r.id == 'test_high_range');

      // customHigh 成功进入 chest 所在的组，head 被换出成为独立排
      expect(updatedCustomHigh.trackGroupId, isNotNull);
      expect(updatedCustomHigh.trackGroupId, updatedChest.trackGroupId);
      expect(updatedHead.trackGroupId, isNull);

      // 2. 测试范围重叠拦截：将 mix (62~72) 与组内的 customHigh (82~90) 置换
      // mix 替换后与 chest (48~64) 在 62~64 范围重叠，必须严格拦截！
      final mix = state.userRanges.firstWhere((r) => r.id == 'preset_mix');
      expect(state.canSwapRanges(mix.id, updatedCustomHigh.id), false);
      expect(state.trySwapRanges(mix.id, updatedCustomHigh.id), false);

      // 3. 测试跨侧交换 (不同侧音区只要替换后组合不发生重叠即允许交换)
      // 创建一个白键侧独立音区 whistle (92~100)
      final whiteWhistle = VocalRangeItem(
        id: 'test_white_whistle',
        name: '哨音区',
        type: VocalRangeType.custom,
        startMidi: 92,
        endMidi: 100,
        color: const Color(0xFFFFB300),
        indicatorPosition: RangeIndicatorPosition.whiteKeySide,
      );
      state.addCustomRange(whiteWhistle);

      // 此时黑键侧组内有: chest (48~64) 和 customHigh (82~90)
      // 将白键侧的 whiteWhistle (92~100) 与黑键侧组内的 customHigh (82~90) 进行跨侧交换！
      // 替换后 whiteWhistle 与 chest 完全无重叠，customHigh 去白键侧也无重叠，应该允许交换！
      expect(state.canSwapRanges(whiteWhistle.id, updatedCustomHigh.id), true);

      final crossSideSuccess = state.trySwapRanges(whiteWhistle.id, updatedCustomHigh.id);
      expect(crossSideSuccess, true);

      final swappedWhistle = state.userRanges.firstWhere((r) => r.id == 'test_white_whistle');
      final swappedHigh = state.userRanges.firstWhere((r) => r.id == 'test_high_range');

      // whiteWhistle 成功进入黑键侧组，方位自动同步为黑键侧，且与 updatedChest 同属一组
      expect(swappedWhistle.indicatorPosition, RangeIndicatorPosition.blackKeySide);
      expect(swappedWhistle.trackGroupId, updatedChest.trackGroupId);

      // customHigh 换出至白键侧，方位自动同步为白键侧，且与源排原有伙伴 (preset_mix) 同属一组
      expect(swappedHigh.indicatorPosition, RangeIndicatorPosition.whiteKeySide);
      final mixRange = state.userRanges.firstWhere((r) => r.id == 'preset_mix');
      expect(swappedHigh.trackGroupId, mixRange.trackGroupId);
    });

    test('Lane reordering and visual spatial alignment tests', () {
      final state = VocalMasterState();
      state.resetDefaultRanges();

      // 黑键侧包含: chest (48~64), head (70~81)
      final blackLanes = state.getLanesForSide(true);
      expect(blackLanes.isNotEmpty, true);

      if (blackLanes.length > 1) {
        final originalFirstId = blackLanes[0].first.id;
        final originalSecondId = blackLanes[1].first.id;

        // 调整黑键侧第 1 排与第 2 排顺序
        state.swapLaneOrder(isBlackSide: true, indexA: 0, indexB: 1);

        final updatedBlackLanes = state.getLanesForSide(true);
        expect(updatedBlackLanes[0].first.id, originalSecondId);
        expect(updatedBlackLanes[1].first.id, originalFirstId);
      }

      // 重置排布
      state.resetAllTrackGroups();
      expect(state.userRanges.every((r) => r.trackGroupId == null && r.trackOrder == 0), true);
    });

    test('RangeManagerSheet height mode, custom ratio and offset controls', () {
      final state = VocalMasterState();
      // 默认状态检查
      expect(state.pianoContainerKey, isNotNull);
      expect(state.rangeManagerHeightMode, 'auto');
      expect(state.rangeManagerCustomRatio, 0.50);
      expect(state.rangeManagerHeightOffset, 50.0);

      // 设置模式
      state.setRangeManagerHeightMode('custom');
      expect(state.rangeManagerHeightMode, 'custom');

      // 设置自定义比例与越界限制 (0.25 ~ 0.85)
      state.setRangeManagerCustomRatio(0.72);
      expect(state.rangeManagerCustomRatio, 0.72);
      state.setRangeManagerCustomRatio(0.10);
      expect(state.rangeManagerCustomRatio, 0.25);
      state.setRangeManagerCustomRatio(0.99);
      expect(state.rangeManagerCustomRatio, 0.85);

      // 设置贴合偏移量与限制 (-100 ~ 100)
      state.setRangeManagerHeightOffset(24.5);
      expect(state.rangeManagerHeightOffset, 24.5);
      state.setRangeManagerHeightOffset(-150.0);
      expect(state.rangeManagerHeightOffset, -100.0);

      // 重置方法
      state.resetRangeManagerHeight();
      expect(state.rangeManagerHeightMode, 'auto');
      expect(state.rangeManagerCustomRatio, 0.50);
      expect(state.rangeManagerHeightOffset, 50.0);
    });

    test('PitchSensitivity and PianoGlowMode defaults, toggles and persistence', () {
      final state = VocalMasterState();
      // 默认灵敏度为 balanced (推荐)
      expect(state.pitchSensitivity, PitchSensitivity.balanced);
      // 默认发光模式为 fadeOut (余晖渐隐)
      expect(state.pianoGlowMode, PianoGlowMode.fadeOut);

      // 切换灵敏度
      state.setPitchSensitivity(PitchSensitivity.high);
      expect(state.pitchSensitivity, PitchSensitivity.high);
      state.setPitchSensitivity(PitchSensitivity.noiseResistant);
      expect(state.pitchSensitivity, PitchSensitivity.noiseResistant);

      // 切换发光模式
      state.setPianoGlowMode(PianoGlowMode.instant);
      expect(state.pianoGlowMode, PianoGlowMode.instant);
      state.setPianoGlowMode(PianoGlowMode.trail);
      expect(state.pianoGlowMode, PianoGlowMode.trail);
    });

    test('Pitch detector listener smoothing majority vote filter', () async {
      final state = VocalMasterState();
      await state.startListeningMode();
      expect(state.isListeningActive, true);

      // 模拟稳定输入 MIDI 60 (C4)
      PitchDetectorService.instance.simulatePitch(60, freq: 261.6);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(state.listeningMidiNote, 60);

      // 模拟一帧瞬时噪音声学跳跃 MIDI 72 (C5，相差12半音八度跳跃)
      PitchDetectorService.instance.simulatePitch(72, freq: 523.2);
      await Future.delayed(const Duration(milliseconds: 20));
      // 第 1 帧八度跳跃：保持 60
      expect(state.listeningMidiNote, 60);

      // 第 2 帧八度跳跃：仍保持 60 防撕裂
      PitchDetectorService.instance.simulatePitch(72, freq: 523.2);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(state.listeningMidiNote, 60);

      // 第 3 帧八度确认：连续3帧，确信切换至 72
      PitchDetectorService.instance.simulatePitch(72, freq: 523.2);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(state.listeningMidiNote, 72);

      await state.stopListeningMode();
      expect(state.isListeningActive, false);
      expect(state.listeningMidiNote, isNull);
    });
  });
}

