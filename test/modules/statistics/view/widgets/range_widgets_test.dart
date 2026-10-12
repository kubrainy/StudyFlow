import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/statistics/models/range_stats.dart';
import 'package:studyflow/modules/statistics/view/widgets/insights_section.dart';
import 'package:studyflow/modules/statistics/view/widgets/range_bar_chart.dart';
import 'package:studyflow/modules/statistics/view/widgets/range_tabs.dart';
import 'package:studyflow/modules/statistics/view/widgets/stat_cards.dart';
import 'package:studyflow/modules/statistics/view_model/statistics_view_model.dart';

import '../../../../helpers/test_fonts.dart';

RangeStats _stats({
  int total = 1720,
  int? previous = 1460,
  int sessions = 34,
  int? previousSessions = 29,
  int completed = 17,
  int tasks = 20,
  int average = 245,
  int? goalLine = 240,
}) => RangeStats(
  totalMinutes: total,
  previousMinutes: previous,
  sessionCount: sessions,
  previousSessionCount: previousSessions,
  completedTasks: completed,
  totalTasks: tasks,
  averageMinutes: average,
  bars: const [
    ChartBar(label: 'Pzt', minutes: 200, caption: 'Pazartesi'),
    ChartBar(label: 'Sal', minutes: 366, caption: 'Salı'),
    ChartBar(label: 'Çar', minutes: 120, caption: 'Çarşamba'),
  ],
  selectedIndex: 1,
  goalLineMinutes: goalLine,
  chartTitle: 'Haftalık Çalışma Grafiği',
  chartSubtitle: '7 günlük odaklanma süresi (Saat)',
  selectionPrefix: 'Seçili gün',
  comparisonLabel: previous == null ? null : 'geçen haftaya',
  shares: const [],
  bestWindow: null,
);

Future<void> _pump(WidgetTester tester, Widget child, {double width = 390}) {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  group('RangeTabs', () {
    testWidgets('dört aralık da görünür, dokunulan bildirilir', (tester) async {
      final picked = <StatsRange>[];
      await _pump(
        tester,
        RangeTabs(selected: StatsRange.week, onChanged: picked.add),
      );

      for (final label in ['Günlük', 'Haftalık', 'Aylık', 'Tüm Zamanlar']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Aylık'));
      await tester.tap(find.text('Günlük'));

      expect(picked, [StatsRange.month, StatsRange.day]);
    });
  });

  group('StatCards', () {
    testWidgets('dört kartın değeri ve karşılaştırması yazılır', (
      tester,
    ) async {
      await _pump(tester, StatCards(stats: _stats(), goalMinutes: 240));

      expect(find.text('Toplam Çalışma'), findsOneWidget);
      expect(find.text('28s 40dk'), findsOneWidget);
      expect(find.text('+%18'), findsOneWidget);
      expect(find.text('geçen haftaya'), findsWidgets);
      expect(find.text('34 Oturum'), findsOneWidget);
      expect(find.text('+5 seans'), findsOneWidget);
      expect(find.text('%85'), findsOneWidget);
      expect(find.text('17/20 Tamamlandı'), findsOneWidget);
      expect(find.text('4s 05dk'), findsOneWidget);
      expect(find.text('Hedefin üstünde 🎯'), findsOneWidget);
    });

    testWidgets('düşüş kırmızı rozetle, "-" işaretiyle yazılır', (
      tester,
    ) async {
      await _pump(
        tester,
        StatCards(
          stats: _stats(
            total: 730,
            previous: 1460,
            sessions: 10,
            previousSessions: 12,
          ),
          goalMinutes: 240,
        ),
      );

      expect(find.text('-%50'), findsOneWidget);
      expect(find.text('-2 seans'), findsOneWidget);
    });

    testWidgets('ortalama hedefin altındaysa "Hedefin altında" yazar', (
      tester,
    ) async {
      await _pump(
        tester,
        StatCards(stats: _stats(average: 100), goalMinutes: 240),
      );

      expect(find.text('Hedefin altında'), findsOneWidget);
    });

    testWidgets('karşılaştırma dönemi yoksa (Tüm Zamanlar) rozet çıkmaz', (
      tester,
    ) async {
      await _pump(
        tester,
        StatCards(
          stats: _stats(previous: null, previousSessions: null),
          goalMinutes: 240,
        ),
      );

      expect(find.textContaining('%18'), findsNothing);
      expect(find.text('başlangıçtan beri'), findsNWidgets(2));
    });

    testWidgets('önceki dönem 0 ise yüzde yerine açıklama yazar', (
      tester,
    ) async {
      await _pump(
        tester,
        StatCards(
          stats: _stats(previous: 0, previousSessions: 0),
          goalMinutes: 240,
        ),
      );

      expect(find.text('karşılaştırma yok'), findsOneWidget);
    });

    testWidgets('dar ekranda taşmaz', (tester) async {
      await _pump(
        tester,
        StatCards(stats: _stats(), goalMinutes: 240),
        width: 280,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('RangeBarChart', () {
    testWidgets('başlık, alt başlık ve varsayılan seçili sütun yazılır', (
      tester,
    ) async {
      await _pump(tester, RangeBarChart(stats: _stats()));

      expect(find.text('Haftalık Çalışma Grafiği'), findsOneWidget);
      expect(find.text('7 günlük odaklanma süresi (Saat)'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      final selection = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('chart-selection')),
          matching: find.byType(Text),
        ),
      );
      expect(selection.textSpan!.toPlainText(), 'Seçili gün: Salı (6.1 Saat)');
    });

    testWidgets('hedef çizgisi varsa etiketi yazılır', (tester) async {
      await _pump(tester, RangeBarChart(stats: _stats()));

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.extraLinesData.horizontalLines, hasLength(1));
      expect(chart.data.extraLinesData.horizontalLines.single.y, 240);
    });

    testWidgets('hedef çizgisi yoksa çizgi çizilmez', (tester) async {
      await _pump(tester, RangeBarChart(stats: _stats(goalLine: null)));

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.extraLinesData.horizontalLines, isEmpty);
    });

    testWidgets('her sütun için bir çubuk çizilir', (tester) async {
      await _pump(tester, RangeBarChart(stats: _stats()));

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups, hasLength(3));
      expect(chart.data.barGroups[1].barRods.single.toY, 366);
    });

    testWidgets('hoursText 90 dk için "1.5 Saat" der', (tester) async {
      expect(hoursText(90), '1.5 Saat');
      expect(hoursText(0), '0.0 Saat');
    });
  });

  group('InsightsSection', () {
    const badges = [
      StatsBadge(title: 'İstikrar Ustası', description: '5 gün', earned: true),
      StatsBadge(
        title: 'Hedef Avcısı',
        description: 'Hedef: 240 dk',
        earned: false,
      ),
    ];

    testWidgets('en verimli aralık ve rozetler yazılır', (tester) async {
      await _pump(
        tester,
        const InsightsSection(
          bestWindow: (startHour: 9, endHour: 11),
          badges: badges,
          periodLabel: 'Bu Hafta',
        ),
      );

      expect(find.text('İçgörüler ve Rozetler'), findsOneWidget);
      expect(find.text('Bu Hafta'), findsOneWidget);
      expect(find.text('VERİMLİLİK ANALİZİ'), findsOneWidget);
      expect(find.textContaining('09:00 - 11:00'), findsOneWidget);
      expect(find.text('KAZANILDI'), findsOneWidget);
      expect(find.text('KİLİTLİ'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('veri yoksa açıklama yazar', (tester) async {
      await _pump(
        tester,
        const InsightsSection(
          bestWindow: null,
          badges: badges,
          periodLabel: 'Bugün',
        ),
      );

      expect(find.textContaining('Henüz yeterli veri yok'), findsOneWidget);
    });
  });
}
