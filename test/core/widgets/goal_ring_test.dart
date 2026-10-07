import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/widgets/goal_ring.dart';

Future<void> _pump(WidgetTester tester, {required double progress}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: GoalRing(progress: progress, value: '45', caption: 'dk bugün'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ortadaki değeri ve alt yazıyı gösterir', (tester) async {
    await _pump(tester, progress: 0.4);

    expect(find.text('45'), findsOneWidget);
    expect(find.text('dk bugün'), findsOneWidget);
  });

  testWidgets('boş ve tam doluyken de çizilir', (tester) async {
    await _pump(tester, progress: 0);
    expect(tester.takeException(), isNull);

    await _pump(tester, progress: 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verilen boyutta çizilir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GoalRing(progress: 0.5, value: '1', caption: 'x', size: 80),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(GoalRing)), const Size(80, 80));
  });
}
