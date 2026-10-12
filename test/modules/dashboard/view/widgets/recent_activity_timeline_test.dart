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
  ValueChanged<String?>? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: RecentActivityList(days: days, now: _now, onTap: onTap),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ders adı, süre, gün ve saat aralığı yazılır', (tester) async {
    await _pump(tester, _days);

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Serbest çalışma'), findsOneWidget);
    expect(find.text('Fizik'), findsOneWidget);
    expect(
      find.text('25dk (1 Pomodoro) • Bugün 14:05 - 14:30'),
      findsOneWidget,
    );
    expect(
      find.text('1s 05dk (1 Pomodoro) • Dün 19:45 - 20:50'),
      findsOneWidget,
    );
  });

  testWidgets('başlığın sağında gösterilen günler yazılır (Bugün & Dün)', (
    tester,
  ) async {
    await _pump(tester, _days);

    expect(find.text('Bugün & Dün'), findsOneWidget);
  });

  testWidgets('eski günün adı "5 Eki" olarak yazılır', (tester) async {
    await _pump(tester, [
      ActivityDay(
        date: DateTime(2026, 10, 5),
        activities: [
          RecentActivity(
            name: 'Serbest çalışma',
            startedAt: DateTime(2026, 10, 5, 9),
            minutes: 10,
          ),
        ],
      ),
    ]);

    expect(find.text('5 Eki'), findsWidgets);
  });

  testWidgets('en çok üç satır gösterilir', (tester) async {
    await _pump(tester, [
      ActivityDay(
        date: DateTime(2026, 10, 7),
        activities: [
          for (var i = 0; i < 5; i++)
            RecentActivity(
              name: 'Ders $i',
              startedAt: DateTime(2026, 10, 7, 8 + i),
              minutes: 10,
            ),
        ],
      ),
    ]);

    expect(find.byKey(const Key('timeline-dot')), findsNWidgets(3));
  });

  testWidgets('satıra dokununca dersin id\'si bildirilir', (tester) async {
    final taps = <String?>[];
    await _pump(tester, _days, onTap: taps.add);

    await tester.tap(find.text('Matematik'));
    await tester.tap(find.text('Serbest çalışma'));

    expect(taps, ['mat', null]);
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
