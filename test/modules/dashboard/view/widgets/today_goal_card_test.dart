import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/widgets/app_buttons.dart';
import 'package:studyflow/modules/dashboard/models/dashboard_summary.dart';
import 'package:studyflow/modules/dashboard/view/widgets/today_goal_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  int today = 45,
  int goal = 120,
  VoidCallback? onStartTap,
  double width = 360,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: TodayGoalCard(
              summary: DashboardSummary(
                todayMinutes: today,
                todayCompletedTasks: 0,
                goalMinutes: goal,
              ),
              onStartTap: onStartTap,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('bugünün dakikasını, hedefi ve kalan süreyi gösterir', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('45'), findsOneWidget);
    expect(find.text('dk bugün'), findsOneWidget);
    expect(find.text('Günlük hedef 120 dk'), findsOneWidget);
    expect(find.text('1 sa 15 dk kaldı'), findsOneWidget);
  });

  testWidgets('hedef dolunca "Hedefe ulaştın" yazar', (tester) async {
    await _pump(tester, today: 130);

    expect(find.text('Hedefe ulaştın'), findsOneWidget);
    expect(find.textContaining('kaldı'), findsNothing);
  });

  testWidgets('Pomodoro başlat düğmesi onStartTap çağırır', (tester) async {
    var taps = 0;
    await _pump(tester, onStartTap: () => taps++);

    await tester.tap(find.text('Pomodoro başlat'));

    expect(taps, 1);
  });

  testWidgets('düğme kartın altında, tam genişlikte ve alçaktır', (
    tester,
  ) async {
    await _pump(tester);

    final card = tester.getRect(find.byType(TodayGoalCard));
    final button = tester.getRect(find.text('Pomodoro başlat'));
    final buttonBox = tester.getRect(find.byType(AppPrimaryButton));
    final ring = tester.getRect(find.byKey(const Key('goal-ring')));

    expect(buttonBox.top, greaterThan(ring.bottom));
    // Kartın iç boşluğu 16 + kenarlık 1, iki yanda.
    expect(buttonBox.width, closeTo(card.width - 34, 0.5));
    expect(buttonBox.height, lessThanOrEqualTo(48));
    expect(button.height, lessThan(buttonBox.height));
  });

  testWidgets('geniş kartta halka ve yazılar yan yana durur', (tester) async {
    await _pump(tester, width: 360);

    final ring = tester.getRect(find.byKey(const Key('goal-ring')));
    final text = tester.getRect(find.text('Günlük hedef 120 dk'));

    expect(ring.right, lessThan(text.left));
  });

  testWidgets('çok dar kartta yazılar halkanın altına iner', (tester) async {
    await _pump(tester, width: 260);

    final ring = tester.getRect(find.byKey(const Key('goal-ring')));
    final text = tester.getRect(find.text('Günlük hedef 120 dk'));

    expect(text.top, greaterThanOrEqualTo(ring.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dar alanda taşmaz', (tester) async {
    await _pump(tester, today: 7230, goal: 9000, width: 280);

    expect(tester.takeException(), isNull);
  });
}
