import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocal_master_flutter/core/app_strings.dart';
import 'package:vocal_master_flutter/core/app_theme.dart';
import 'package:vocal_master_flutter/models/trainer_models.dart';
import 'package:vocal_master_flutter/state/vocal_master_state.dart';
import 'package:vocal_master_flutter/widgets/bottom/sing_along_controller.dart';
import 'package:vocal_master_flutter/widgets/bottom/settings_sheet.dart';
import 'package:vocal_master_flutter/widgets/piano/horizontal_piano.dart';
import 'package:vocal_master_flutter/widgets/piano/vertical_piano.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vox v1.1.2 Features Verification', () {
    testWidgets('SingAlongControllerView pattern selector scales text and prevents overflow', (tester) async {
      final state = VocalMasterState();
      state.setLanguage(AppLanguage.zh);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: state,
              child: const SizedBox(
                width: 320, // 极限窄屏幕宽度测试
                child: SingAlongControllerView(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证没有引发任何 RenderFlex overflow 错误
      expect(tester.takeException(), isNull);

      // 验证下拉框已渲染
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // 验证长标题在各个预设下均能正常映射
      for (final p in TrainerPattern.presets) {
        final title = state.strings.trainerPatternTitle(p.id, p.title);
        expect(title.isNotEmpty, true);
      }
    });

    testWidgets('SettingsSheet contains pitch sensitivity and glow mode controls with v1.1.2 footer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              height: 1200,
              child: ChangeNotifierProvider.value(
                value: state,
                child: const SettingsSheet(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 滚动至灵敏度设置选项可见并完全进入视口
      await tester.scrollUntilVisible(
        find.text(state.strings.sensitivityNoiseResistant),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );

      // 验证灵敏度设置选项
      expect(find.text(state.strings.listeningSensitivityTitle), findsOneWidget);
      expect(find.text(state.strings.sensitivityBalanced), findsOneWidget);

      // 交互测试：切换灵敏度
      await tester.tap(find.text(state.strings.sensitivityNoiseResistant));
      await tester.pumpAndSettle();
      expect(state.pitchSensitivity, PitchSensitivity.noiseResistant);

      // 滚动至发光余晖模式设置选项可见并完全进入视口
      await tester.scrollUntilVisible(
        find.text(state.strings.glowModeTrail),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );

      // 验证发光余晖模式设置选项
      expect(find.text(state.strings.pianoGlowModeTitle), findsOneWidget);
      expect(find.text(state.strings.glowModeFadeOut), findsOneWidget);

      // 交互测试：切换发光模式
      await tester.tap(find.text(state.strings.glowModeTrail));
      await tester.pumpAndSettle();
      expect(state.pianoGlowMode, PianoGlowMode.trail);

      // 滚动到底部验证版本号同步为 Vox v1.4 及 taketo 署名
      await tester.scrollUntilVisible(find.text('Vox v1.4'), 100.0, scrollable: find.byType(Scrollable).first);
      expect(find.text('Vox v1.4'), findsOneWidget);
      expect(find.text('AI-driven by taketo'), findsOneWidget);
    });

    testWidgets('Horizontal and Vertical piano widgets accept glowMode and render without error', (tester) async {
      final state = VocalMasterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HorizontalPianoWidget(
              activeMidi: 60,
              listeningMidi: 60,
              ranges: state.userRanges,
              activeRange: state.activeRange,
              glowMode: PianoGlowMode.fadeOut,
              onKeyPressed: (_) {},
              onKeyReleased: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 测试竖排键盘发光
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: VerticalPianoWidget(
              activeMidi: 60,
              listeningMidi: 60,
              ranges: state.userRanges,
              activeRange: state.activeRange,
              glowMode: PianoGlowMode.trail,
              onKeyPressed: (_) {},
              onKeyReleased: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
