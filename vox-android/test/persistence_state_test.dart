import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:vocal_master_flutter/main.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/audio/real_audio_engine.dart';
import 'package:vocal_master_flutter/models/trainer_models.dart';
import 'package:vocal_master_flutter/core/key_signature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VocalMasterState User Configuration & Interface State Persistence Tests', () {
    test('Settings persistence: Timbre, Orientation, Invert, KeySignature and Engine Sync', () async {
      final state1 = VocalMasterState();
      // 等待初始异步加载完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. 修改音色并验证引擎与状态
      state1.setTimbre('Virtual Diva');
      expect(state1.currentTimbre, 'Virtual Diva');
      expect(RealAudioEngine.instance.currentTimbre, 'Virtual Diva');

      // 2. 修改键盘方向与竖向反转
      state1.togglePianoOrientation(); // horizontal -> vertical
      expect(state1.pianoOrientation, Axis.vertical);

      state1.setInvertVerticalOrder(true);
      expect(state1.invertVerticalOrder, true);

      // 3. 修改调号
      final gKey = KeySignature.all.firstWhere((k) => k.id == 'G');
      state1.setKeySignature(gKey);
      expect(state1.keySignature.id, 'G');

      // 主动触发落盘保存
      await state1.savePreferences();

      // 4. 模拟软件重启：实例化全新的 state2，加载偏好设置
      final state2 = VocalMasterState();
      await Future.delayed(const Duration(milliseconds: 150));

      // 验证音色恢复与音频引擎同步
      expect(state2.currentTimbre, 'Virtual Diva');
      expect(RealAudioEngine.instance.currentTimbre, 'Virtual Diva');

      // 验证键盘方向与竖排设置
      expect(state2.pianoOrientation, Axis.vertical);
      expect(state2.invertVerticalOrder, true);

      // 验证调号恢复
      expect(state2.keySignature.id, 'G');
    });

    test('Exit interface state persistence: Active range, StudioMode, Selection and Note focus', () async {
      final state1 = VocalMasterState();
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. 选中第三个预设音区
      expect(state1.userRanges.length, greaterThan(2));
      final targetRange = state1.userRanges[2];
      state1.selectRange(targetRange);
      expect(state1.activeRange?.id, targetRange.id);

      // 2. 切换到划选模式并自定义区间
      state1.setMode(StudioMode.rangeSelect);
      state1.setSelectionRange(53, 76);
      expect(state1.currentMode, StudioMode.rangeSelect);
      expect(state1.selectionStartMidi, 53);
      expect(state1.selectionEndMidi, 76);
      expect(state1.currentMidi, 53);

      // 3. 配置跟唱练声参数
      final pattern2 = TrainerPattern.presets[1];
      state1.setTrainerPattern(pattern2);
      state1.setTrainerRootMidi(64); // E4
      state1.setTrainerBpm(96);
      expect(state1.trainerPattern.id, pattern2.id);
      expect(state1.trainerRootMidi, 64);
      expect(state1.trainerBpm, 96);

      // 模拟退出前保存
      await state1.savePreferences();

      // 4. 重启加载
      final state2 = VocalMasterState();
      await Future.delayed(const Duration(milliseconds: 150));

      // 验证记忆激活音区
      expect(state2.activeRange?.id, targetRange.id);

      // 验证记忆工作模式与划选选区
      expect(state2.currentMode, StudioMode.rangeSelect);
      expect(state2.selectionStartMidi, 53);
      expect(state2.selectionEndMidi, 76);
      expect(state2.currentMidi, 64);

      // 验证记忆跟唱练声参数
      expect(state2.trainerPattern.id, pattern2.id);
      expect(state2.trainerRootMidi, 64);
      expect(state2.trainerBpm, 96);
    });

    test('Mode switching and clearing selection persists cleanly', () async {
      final state1 = VocalMasterState();
      await Future.delayed(const Duration(milliseconds: 100));

      // 切换到跟唱练声模式
      state1.setMode(StudioMode.singTrainer);
      expect(state1.currentMode, StudioMode.singTrainer);
      expect(state1.selectionStartMidi, isNull);
      expect(state1.selectionEndMidi, isNull);

      await state1.savePreferences();

      // 重启
      final state2 = VocalMasterState();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(state2.currentMode, StudioMode.singTrainer);
      expect(state2.selectionStartMidi, isNull);
      expect(state2.selectionEndMidi, isNull);
    });

    testWidgets('VocalMasterStudioScreen observer triggers savePreferences on AppLifecycleState.paused', (tester) async {
      final state = VocalMasterState();
      await tester.pumpWidget(
        ChangeNotifierProvider<VocalMasterState>.value(
          value: state,
          child: const MaterialApp(
            home: VocalMasterStudioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 修改某个设置项（如音色为 Concert Flute）
      state.setTimbre('Concert Flute');

      // 模拟系统切后台事件
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // 验证在 SharedPreferences 中成功持久化了 'Concert Flute'
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vocal_current_timbre'), 'Concert Flute');
    });
  });
}
