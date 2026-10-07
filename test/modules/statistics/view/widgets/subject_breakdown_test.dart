import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/modules/statistics/models/subject_share.dart';
import 'package:studyflow/modules/statistics/view/widgets/subject_breakdown.dart';

Future<void> _pump(
  WidgetTester tester,
  List<SubjectShare> shares, {
  bool scrollable = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: scrollable ? 300 : null,
          child: SubjectBreakdown(shares: shares, scrollable: scrollable),
        ),
      ),
    ),
  );
}

void main() {
  const shares = [
    SubjectShare(subjectId: 'mat', name: 'Matematik', minutes: 105),
    SubjectShare(subjectId: 'fiz', name: 'Fizik', minutes: 70),
    SubjectShare(name: 'Serbest çalışma', minutes: 30),
  ];

  testWidgets('her ders için ad, süre ve yüzde gösterir', (tester) async {
    await _pump(tester, shares);

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('1 sa 45 dk'), findsOneWidget);
    expect(find.text('%51'), findsOneWidget);
    expect(find.text('Fizik'), findsOneWidget);
    expect(find.text('Serbest çalışma'), findsOneWidget);
    expect(find.text('30 dk'), findsOneWidget);
  });

  testWidgets('şerit her ders için bir parça içerir', (tester) async {
    await _pump(tester, shares);

    final strip = find.byKey(const Key('breakdown-strip'));
    expect(
      find.descendant(of: strip, matching: find.byType(ColoredBox)),
      findsNWidgets(shares.length),
    );
  });

  testWidgets('şeridin her parçası görünür yüksekliktedir', (tester) async {
    await _pump(tester, shares);

    final strip = find.byKey(const Key('breakdown-strip'));
    final parts = find.descendant(of: strip, matching: find.byType(ColoredBox));

    for (var i = 0; i < shares.length; i++) {
      expect(tester.getSize(parts.at(i)).height, 14);
    }
  });

  testWidgets('10 dersin her biri ayrı renk alır, 11. ders başa döner', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 11; i++)
        SubjectShare(subjectId: 'd$i', name: 'Ders $i', minutes: 100 - i),
    ];
    await _pump(tester, many);

    final strip = find.byKey(const Key('breakdown-strip'));
    final colors = tester
        .widgetList<ColoredBox>(
          find.descendant(of: strip, matching: find.byType(ColoredBox)),
        )
        .map((box) => box.color)
        .toList();

    expect(colors.take(10).toSet(), hasLength(10));
    expect(colors[10], colors[0]);
  });

  testWidgets('serbest çalışma paletten bağımsız hep gri', (tester) async {
    await _pump(tester, shares);

    final strip = find.byKey(const Key('breakdown-strip'));
    final colors = tester
        .widgetList<ColoredBox>(
          find.descendant(of: strip, matching: find.byType(ColoredBox)),
        )
        .map((box) => box.color)
        .toList();

    expect(colors.last, AppColors.textDisabled);
    expect(AppColors.subjectPalette, isNot(contains(AppColors.textDisabled)));
  });

  testWidgets('liste boşsa açıklama yazar', (tester) async {
    await _pump(tester, const []);

    expect(find.text('Henüz ders bazlı çalışma yok.'), findsOneWidget);
  });

  testWidgets('kaydırılabilir modda sabit yükseklikte taşmaz', (tester) async {
    await _pump(tester, shares, scrollable: true);

    expect(find.text('Matematik'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
