import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/statistics/models/statistics_summary.dart';
import 'package:studyflow/modules/statistics/view/widgets/today_summary_card.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  int today = 45,
  int goal = 60,
  int week = 245,
  int tasks = 8,
  double width = 360,
  VoidCallback? onTasksTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: TodaySummaryCard(
              summary: StatisticsSummary(
                todayMinutes: today,
                weekMinutes: week,
                weekCompletedTasks: tasks,
              ),
              goalMinutes: goal,
              onTasksTap: onTasksTap,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'bugünün dakikasını, hafta toplamını ve görev sayısını gösterir',
    (tester) async {
      await _pumpCard(tester);

      expect(find.text('45'), findsOneWidget);
      expect(find.text('dk bugün'), findsOneWidget);
      expect(find.text('4 sa 5 dk'), findsOneWidget);
      expect(find.text('8 görev bitti'), findsOneWidget);
    },
  );

  testWidgets('günlük hedefi yüzde olmadan yazar', (tester) async {
    await _pumpCard(tester, today: 45, goal: 60);

    expect(find.text('Günlük hedef 60 dk'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('hedef aşılınca da taşma olmaz', (tester) async {
    await _pumpCard(tester, today: 90, goal: 60);

    expect(find.text('Günlük hedef 60 dk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiç çalışılmamışsa da çizilir', (tester) async {
    await _pumpCard(tester, today: 0, week: 0, tasks: 0);

    expect(find.byKey(const Key('today-ring')), findsOneWidget);
    expect(find.text('0 görev bitti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dar alanda taşmaz', (tester) async {
    await _pumpCard(tester, week: 7230, width: 280);

    expect(tester.takeException(), isNull);
  });

  testWidgets('görev rozetine basılınca onTasksTap çağrılır', (tester) async {
    var taps = 0;
    await _pumpCard(tester, onTasksTap: () => taps++);

    await tester.tap(find.text('8 görev bitti'));

    expect(taps, 1);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('onTasksTap verilmezse rozette ok işareti yoktur', (
    tester,
  ) async {
    await _pumpCard(tester);

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
