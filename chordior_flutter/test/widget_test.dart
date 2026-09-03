import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chordior_flutter/main.dart';
import 'package:chordior_flutter/state/app_state.dart';

void main() {
  testWidgets('ChordiorApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ChordiorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('和弦:'), findsWidgets);
    expect(find.text('调式罗盘'), findsOneWidget);
    expect(find.text('乐器探索'), findsOneWidget);
    expect(find.text('和弦工坊'), findsOneWidget);
    expect(find.text('设置中心'), findsOneWidget);
  });
}
