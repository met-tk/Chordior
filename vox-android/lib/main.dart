import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'state/vocal_master_state.dart';
import 'widgets/header/info_header_widget.dart';
import 'widgets/piano/piano_view_container.dart';
import 'widgets/bottom/bottom_control_deck.dart';
import 'widgets/bottom/save_range_dialog.dart';
import 'widgets/bottom/range_manager_sheet.dart';
import 'widgets/bottom/settings_sheet.dart';
import 'widgets/common/split_divider_handle.dart';
import 'widgets/common/top_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 状态栏沉浸式配置
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => VocalMasterState(),
      child: const VocalMasterApp(),
    ),
  );
}

class VocalMasterApp extends StatelessWidget {
  const VocalMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VocalMasterState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Vox',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(state.uiScale),
              ),
              child: child!,
            );
          },
          home: const VocalMasterStudioScreen(),
        );
      },
    );
  }
}

class VocalMasterStudioScreen extends StatefulWidget {
  const VocalMasterStudioScreen({super.key});

  @override
  State<VocalMasterStudioScreen> createState() => _VocalMasterStudioScreenState();
}

class _VocalMasterStudioScreenState extends State<VocalMasterStudioScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    super.didChangeAppLifecycleState(lifecycle);
    // 当应用退到后台、被覆盖、暂停或销毁时，立即落地保存用户所有配置与当前界面状态
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.inactive ||
        lifecycle == AppLifecycleState.detached ||
        lifecycle == AppLifecycleState.hidden) {
      if (mounted) {
        context.read<VocalMasterState>().savePreferences();
      }
    }
  }

  void _showSaveRangeDialog(BuildContext context) {
    final state = context.read<VocalMasterState>();
    if (state.selectionStartMidi == null || state.selectionEndMidi == null) return;

    showDialog(
      context: context,
      builder: (ctx) => SaveRangeDialog(
        startMidi: state.selectionStartMidi!,
        endMidi: state.selectionEndMidi!,
        onSave: ({required name, required type, required color, required description}) {
          state.saveCurrentSelectionAsRange(
            name: name,
            type: type,
            color: color,
            description: description,
          );
        },
      ),
    );
  }

  void _showRangeManager(BuildContext context) {
    showTopSheet(
      context: context,
      builder: (_) => const RangeManagerSheet(),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ================= 顶部第一大区块：信息与五线谱区块 (独立硬件绘制层) =================
            RepaintBoundary(
              child: InfoHeaderWidget(
                onOpenRangeManager: () => _showRangeManager(context),
                onOpenSettings: () => _showSettings(context),
              ),
            ),

            // ================= 缝隙分割滑块：动态调整垂直空间比例 =================
            const SplitDividerHandle(),

            // ================= 中间第二大区块：可变样式钢琴键盘与多轨重叠画布 (独立硬件绘制层) =================
            Expanded(
              child: RepaintBoundary(
                child: PianoViewContainer(
                  key: state.pianoContainerKey,
                  onOpenRangeSaveDialog: () => _showSaveRangeDialog(context),
                ),
              ),
            ),

            // ================= 最下方第三大区块：功能模式切换、音源与设置区块 (独立硬件绘制层) =================
            RepaintBoundary(
              child: BottomControlDeck(
                onOpenRangeManager: () => _showRangeManager(context),
                onOpenSettings: () => _showSettings(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
