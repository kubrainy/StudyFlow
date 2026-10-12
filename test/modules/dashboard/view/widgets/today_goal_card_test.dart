import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/dashboard/models/dashboard_summary.dart';
import 'package:studyflow/modules/dashboard/view/widgets/today_goal_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  int today = 165,
  int goal = 240,
  int streak = 5,
  int completed = 6,
  int open = 2,
  int sessionCount = 4,
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
                todayCompletedTasks: completed,
                goalMinutes: goal,
                streakDays: streak,
                todaySessionCount: sessionCount,
                openTaskCount: open,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('halkada bugünkü süre ve hedef, rozette yüzde yazar', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('2s 45dk'), findsOneWidget);
    expect(find.text('/ 4s 00dk'), findsOneWidget);
    // 165 / 240 = %68,75 → aşağı yuvarlanır.
    expect(find.text('%68 Tamamlandı'), findsOneWidget);
  });

  testWidgets('hedef aşılınca yüzde 100\'de kalır', (tester) async {
    await _pump(tester, today: 300);

    expect(find.text('%100 Tamamlandı'), findsOneWidget);
  });

  testWidgets('seri, görevler ve Pomodoro satırları görünür', (tester) async {
    await _pump(tester);

    expect(find.text('Seri Durumu'), findsOneWidget);
    expect(find.text('5 Gün'), findsOneWidget);
    expect(find.text('Görevler'), findsOneWidget);
    expect(find.text('6 / 8'), findsOneWidget);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('4 Oturum'), findsOneWidget);
  });

  testWidgets('geniş kartta halka ve satırlar yan yana durur', (tester) async {
    await _pump(tester, width: 360);

    final ring = tester.getRect(find.byKey(const Key('goal-ring')));
    final row = tester.getRect(find.text('Seri Durumu'));

    expect(ring.right, lessThan(row.left));
  });

  testWidgets('çok dar kartta satırlar halkanın altına iner', (tester) async {
    await _pump(tester, width: 260);

    final ring = tester.getRect(find.byKey(const Key('goal-ring')));
    final row = tester.getRect(find.text('Seri Durumu'));

    expect(row.top, greaterThanOrEqualTo(ring.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dar alanda ve büyük sayılarda taşmaz', (tester) async {
    await _pump(tester, today: 7230, goal: 9000, width: 280);

    expect(tester.takeException(), isNull);
  });
}
