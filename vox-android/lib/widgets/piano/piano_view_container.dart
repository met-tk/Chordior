import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../state/vocal_master_state.dart';
import 'horizontal_piano.dart';
import 'vertical_piano.dart';
import 'range_selection_deck.dart';

/// 中间第二大区块：可变样式钢琴键盘与多音区画布容器 (支持缩放、优雅括线与渐变渗透，零溢出风险)
class PianoViewContainer extends StatelessWidget {
  final VoidCallback onOpenRangeSaveDialog;

  const PianoViewContainer({
    super.key,
    required this.onOpenRangeSaveDialog,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VocalMasterState>();
    final isHorizontal = state.pianoOrientation == Axis.horizontal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: AppTheme.scaffoldBg(context),
      child: Column(
        children: [
          // 独立的双滑块音区框选控制台 (划选模式下常驻展示，支持一边拖动滑块一边弹琴试听)
          if (state.currentMode == StudioMode.rangeSelect)
            RangeSelectionDeck(
              state: state,
              onSaveRange: onOpenRangeSaveDialog,
            ),

          // 键盘核心区 (横向或竖排自适应，支持双侧并行音区渲染)
          Expanded(
            child: isHorizontal
                ? HorizontalPianoWidget(
                    minMidi: 36, // 雅马哈记谱法 C1 (SPN C2)
                    maxMidi: 96, // 雅马哈记谱法 C6 (SPN C7)，共 61 键
                    activeMidi: state.isListeningActive
                        ? (state.listeningMidiNote ?? -1)
                        : (state.trainerNoteHighlight ?? state.currentMidi),
                    listeningMidi: state.isListeningActive ? state.listeningMidiNote : null,
                    ranges: state.userRanges,
                    activeRange: state.activeRange,
                    selectionStart: state.selectionStartMidi,
                    selectionEnd: state.selectionEndMidi,
                    isSelectionMode: state.currentMode == StudioMode.rangeSelect,
                    preferSharp: state.preferSharps,
                    scale: state.keyboardScale,
                    keyLengthRatio: state.keyLengthRatio,
                    rangeIndicatorPosition: state.rangeIndicatorPosition,
                    separateRangeTracks: state.separateRangeTracks,
                    glowMode: state.pianoGlowMode,
                    octaveNotation: state.octaveNotation,
                    onKeyPressed: (m) => state.onPianoKeyPressed(m),
                    onKeyReleased: (m) => state.onPianoKeyReleased(m),
                    onSelectRange: (r) => state.selectRange(r),
                    onLongPressRange: (r) => state.openRangeSettings(r),
                    onScaleChanged: (s) => state.setKeyboardScale(s),
                    onSelectionRangeChanged: (start, end) => state.setSelectionRange(start, end),
                  )
                : VerticalPianoWidget(
                    minMidi: 36, // 雅马哈记谱法 C1 (SPN C2)
                    maxMidi: 96, // 雅马哈记谱法 C6 (SPN C7)，共 61 键
                    activeMidi: state.isListeningActive
                        ? (state.listeningMidiNote ?? -1)
                        : (state.trainerNoteHighlight ?? state.currentMidi),
                    listeningMidi: state.isListeningActive ? state.listeningMidiNote : null,
                    ranges: state.userRanges,
                    activeRange: state.activeRange,
                    selectionStart: state.selectionStartMidi,
                    selectionEnd: state.selectionEndMidi,
                    isSelectionMode: state.currentMode == StudioMode.rangeSelect,
                    preferSharp: state.preferSharps,
                    scale: state.keyboardScale,
                    keyLengthRatio: state.keyLengthRatio,
                    rangeIndicatorPosition: state.rangeIndicatorPosition,
                    separateRangeTracks: state.separateRangeTracks,
                    glowMode: state.pianoGlowMode,
                    octaveNotation: state.octaveNotation,
                    onKeyPressed: (m) => state.onPianoKeyPressed(m),
                    onKeyReleased: (m) => state.onPianoKeyReleased(m),
                    onSelectRange: (r) => state.selectRange(r),
                    onLongPressRange: (r) => state.openRangeSettings(r),
                    onScaleChanged: (s) => state.setKeyboardScale(s),
                    onSelectionRangeChanged: (start, end) => state.setSelectionRange(start, end),
                  ),
          ),
        ],
      ),
    );
  }
}
