import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/dashboard/models/activity_day.dart';
import 'package:studyflow/modules/dashboard/models/recent_activity.dart';
import 'package:studyflow/modules/dashboard/view/widgets/recent_activity_timeline.dart';

// 7 Ekim 2026 Çarşamba.
final _now = DateTime(2026, 10, 7, 15);

final _days = [
  ActivityDay(
    date: DateTime(2026, 10, 7),
    activities: [
      RecentActivity(
        subjectId: 'mat',
        subjectIndex: 0,
        name: 'Matematik',
        startedAt: DateTime(2026, 10, 7, 14, 5),
        minutes: 25,
      ),
      RecentActivity(
        name: 'Serbest çalışma',
        startedAt: DateTime(2026, 10, 7, 11, 30),
        minutes: 20,
      ),
    ],
  ),
  ActivityDay(
    date: DateTime(2026, 10, 6),
    activities: [
      RecentActivity(
        subjectId: 'fiz',
        subjectIndex: 1,
        name: 'Fizik',
        startedAt: DateTime(2026, 10, 6, 19, 45),
        minutes: 65,
      ),
    ],
  ),
];

Future<void> _pump(
  WidgetTester tester,
  List<ActivityDay> days, {
  double width = 360,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: RecentActivityTimeline(days: days, now: _now),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('gün başlıklarını, ders adlarını, saatleri ve süreleri yazar', (
    tester,
  ) async {
    await _pump(tester, _days);

    expect(find.text('BUGÜN'), findsOneWidget);
    expect(find.text('DÜN'), findsOneWidget);
    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Serbest çalışma'), findsOneWidget);
    expect(find.text('14:05'), findsOneWidget);
    expect(find.text('25 dk'), findsOneWidget);
    expect(find.text('1 sa 5 dk'), findsOneWidget);
  });

  testWidgets('her satır için bir nokta çizer', (tester) async {
    await _pump(tester, _days);

    expect(find.byKey(const Key('timeline-dot')), findsNWidgets(3));
  });

  testWidgets('liste boşsa açıklama yazar', (tester) async {
    await _pump(tester, const []);

    expect(find.textContaining('Henüz çalışma yok'), findsOneWidget);
  });

  testWidgets('dar alanda taşmaz', (tester) async {
    await _pump(tester, _days, width: 240);

    expect(tester.takeException(), isNull);
  });
}
