import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/tasks/task_card.dart';

Task _task() => Task(
  id: '1',
  title: 'Paragraf',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onToggle,
  VoidCallback? onPostpone,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TaskCard(
          task: _task(),
          onToggle: onToggle,
          onPostpone: onPostpone,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sağa kaydırınca onToggle çağrılır, kart yerinde kalır', (
    tester,
  ) async {
    var toggled = 0;
    await _pump(tester, onToggle: () => toggled++, onPostpone: () {});

    await tester.drag(find.text('Paragraf'), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(toggled, 1);
    expect(find.text('Paragraf'), findsOneWidget);
  });

  testWidgets('sola kaydırınca onPostpone çağrılır, kart yerinde kalır', (
    tester,
  ) async {
    var postponed = 0;
    await _pump(tester, onToggle: () {}, onPostpone: () => postponed++);

    await tester.drag(find.text('Paragraf'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(postponed, 1);
    expect(find.text('Paragraf'), findsOneWidget);
  });

  testWidgets('onPostpone yoksa sola kaydırma çalışmaz', (tester) async {
    var toggled = 0;
    await _pump(tester, onToggle: () => toggled++);

    await tester.drag(find.text('Paragraf'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(toggled, 0);
  });
}
