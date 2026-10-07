import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/statistics/models/daily_minutes.dart';
import 'package:studyflow/modules/statistics/view/widgets/weekly_line_chart.dart';

List<DailyMinutes> _week(List<int> minutes) => [
  for (var i = 0; i < minutes.length; i++)
    DailyMinutes(date: DateTime(2026, 10, 1 + i), minutes: minutes[i]),
];

Future<void> _pump(WidgetTester tester, List<DailyMinutes> data) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: WeeklyLineChart(data: data)),
    ),
  );
}

void main() {
  group('dayTooltipLabel', () {
    // 7 Ekim 2026 Çarşamba.
    DailyMinutes day(int minutes) =>
        DailyMinutes(date: DateTime(2026, 10, 7), minutes: minutes);

    test('gün adı ve süreyi yazar', () {
      expect(dayTooltipLabel(day(3)), 'Çar · 3 dk');
    });

    test('saatli süreyi saat ve dakikaya çevirir', () {
      expect(dayTooltipLabel(day(63)), 'Çar · 1 sa 3 dk');
      expect(dayTooltipLabel(day(120)), 'Çar · 2 sa');
    });

    test('çalışılmamış gün 0 dk yazar', () {
      expect(dayTooltipLabel(day(0)), 'Çar · 0 dk');
    });
  });

  testWidgets('gelmemiş günler boşken çizgi bugünde biter', (tester) async {
    // Çarşamba (sıra 2): Per-Paz henüz gelmedi, dakikaları 0.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyLineChart(
            data: _week([20, 40, 30, 0, 0, 0, 0]),
            todayIndex: 2,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Pazartesi günü tek noktayla da çizilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyLineChart(
            data: _week([20, 0, 0, 0, 0, 0, 0]),
            todayIndex: 0,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('parmakla sürüklenince hata vermez', (tester) async {
    await _pump(tester, _week([30, 45, 0, 60, 25, 40, 45]));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(WeeklyLineChart)),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('gün kısaltmalarını gösterir', (tester) async {
    // 1 Ekim 2026 Perşembe.
    await _pump(tester, _week([30, 45, 0, 60, 25, 40, 45]));

    for (final name in ['Per', 'Cum', 'Cmt', 'Paz', 'Pzt', 'Sal', 'Çar']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiç çalışılmamış haftada da çizilir', (tester) async {
    await _pump(tester, _week([0, 0, 0, 0, 0, 0, 0]));

    expect(find.byType(WeeklyLineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
