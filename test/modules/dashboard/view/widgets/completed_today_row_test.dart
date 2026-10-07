import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/dashboard/view/widgets/completed_today_row.dart';

Future<void> _pump(WidgetTester tester, {int count = 3, VoidCallback? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CompletedTodayRow(count: count, onTap: onTap),
      ),
    ),
  );
}

void main() {
  testWidgets('görev sayısını ve açıklamayı gösterir', (tester) async {
    await _pump(tester);

    expect(find.text('3 görev'), findsOneWidget);
    expect(find.text('Bugün tamamladın'), findsOneWidget);
  });

  testWidgets('basılınca onTap çağrılır ve ok görünür', (tester) async {
    var taps = 0;
    await _pump(tester, onTap: () => taps++);

    await tester.tap(find.text('Bugün tamamladın'));

    expect(taps, 1);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('onTap verilmezse ok yoktur', (tester) async {
    await _pump(tester);

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('0 görevde de çizilir', (tester) async {
    await _pump(tester, count: 0);

    expect(find.text('0 görev'), findsOneWidget);
  });
}
