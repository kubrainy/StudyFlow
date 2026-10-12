import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/modules/statistics/models/subject_share.dart';
import 'package:studyflow/modules/statistics/view/widgets/subject_breakdown.dart';

import '../../../../helpers/test_fonts.dart';

Future<void> _pump(WidgetTester tester, List<SubjectShare> shares) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SubjectBreakdown(shares: shares, periodText: 'Bu haftaki'),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  const shares = [
    SubjectShare(subjectId: 'mat', name: 'Matematik', minutes: 105),
    SubjectShare(subjectId: 'fiz', name: 'Fizik', minutes: 70),
    SubjectShare(name: 'Serbest çalışma', minutes: 30),
  ];

  testWidgets('başlık, ders sayısı rozeti ve dönem yazısı görünür', (
    tester,
  ) async {
    await _pump(tester, shares);

    expect(find.text('Ders Bazlı Süre Dağılımı'), findsOneWidget);
    expect(find.text('3 Ders'), findsOneWidget);
    expect(find.text('Bu haftaki konu odakları'), findsOneWidget);
  });

  testWidgets('halkanın ortasında toplam saat yazar', (tester) async {
    await _pump(tester, shares);

    // 205 dk = 3.4 saat.
    expect(find.text('3.4s'), findsOneWidget);
    expect(find.text('TOPLAM'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
  });

  testWidgets(
    'gösterge ve çubuk listesinde her ders için ad, yüzde ve süre var',
    (tester) async {
      await _pump(tester, shares);

      expect(find.text('Matematik'), findsNWidgets(2)); // gösterge + çubuk
      expect(find.text('%51'), findsOneWidget);
      expect(find.text('1s 45dk'), findsOneWidget);
      expect(find.text('Fizik'), findsNWidgets(2));
      expect(find.text('Serbest çalışma'), findsNWidgets(2));
      expect(find.text('30dk'), findsOneWidget);
    },
  );

  testWidgets('her çubuk dersin payı kadar dolar', (tester) async {
    await _pump(tester, shares);

    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((b) => b.value!)
        .toList();

    expect(bars, hasLength(3));
    expect(bars[0], closeTo(105 / 205, 0.001));
    expect(bars[2], closeTo(30 / 205, 0.001));
  });

  testWidgets('ilk dört ders Figma renkleri: indigo, yeşil, kahve, kırmızı', (
    tester,
  ) async {
    expect(AppColors.subjectPalette.take(4), [
      AppColors.primary,
      AppColors.subjectGreen,
      AppColors.subjectBrown,
      AppColors.subjectRed,
    ]);
  });

  testWidgets('6 ders olunca gösterge ilk 4 dersi ve "Diğer"i yazar', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 6; i++)
        SubjectShare(subjectId: 'd$i', name: 'Ders $i', minutes: 100 - i * 10),
    ];
    await _pump(tester, many);

    expect(find.text('Diğer'), findsOneWidget);
    // Gösterge 4 ders, çubuk listesi 6 ders: "Ders 0" ikisinde de var.
    expect(find.text('Ders 0'), findsNWidgets(2));
    expect(find.text('Ders 5'), findsOneWidget); // yalnız çubuk listesinde
  });

  testWidgets('serbest çalışma paletten bağımsız hep gri', (tester) async {
    await _pump(tester, shares);

    expect(AppColors.subjectPalette, isNot(contains(AppColors.textDisabled)));
    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    final color = bars.last.valueColor!.value;
    expect(color, AppColors.textDisabled);
  });

  testWidgets('liste boşsa açıklama yazar, halka çizilmez', (tester) async {
    await _pump(tester, const []);

    expect(find.text('Bu aralıkta ders bazlı çalışma yok.'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
    expect(find.text('0 Ders'), findsOneWidget);
  });

  testWidgets('dar alanda taşmaz', (tester) async {
    tester.view.physicalSize = const Size(280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, shares);

    expect(tester.takeException(), isNull);
  });
}
