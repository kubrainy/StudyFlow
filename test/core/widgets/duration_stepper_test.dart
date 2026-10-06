import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/widgets/duration_stepper.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int value,
  int min = 5,
  int max = 120,
  int step = 5,
  List<int>? changes,
  bool enabled = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DurationStepper(
          label: 'Odaklanma süresi',
          value: value,
          min: min,
          max: max,
          step: step,
          enabled: enabled,
          onChanged: (v) => changes?.add(v),
        ),
      ),
    ),
  );
}

Finder get _minus => find.byTooltip('Odaklanma süresi azalt');
Finder get _plus => find.byTooltip('Odaklanma süresi artır');

void main() {
  testWidgets('değeri dakika olarak gösterir, etiket yalnızca ipucudur', (
    tester,
  ) async {
    await _pump(tester, value: 35);

    expect(find.text('35 dk'), findsOneWidget);
    expect(find.text('Odaklanma süresi'), findsNothing);
    expect(_minus, findsOneWidget);
    expect(_plus, findsOneWidget);
  });

  testWidgets('artı adım kadar artırır, eksi adım kadar azaltır', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, value: 35, changes: changes);

    await tester.tap(_plus);
    await tester.tap(_minus);

    expect(changes, [40, 30]);
  });

  testWidgets('adım 1 olunca birer birer değişir', (tester) async {
    final changes = <int>[];
    await _pump(tester, value: 5, min: 1, max: 30, step: 1, changes: changes);

    await tester.tap(_plus);
    await tester.tap(_minus);

    expect(changes, [6, 4]);
  });

  testWidgets('en küçük değerde eksi çalışmaz', (tester) async {
    final changes = <int>[];
    await _pump(tester, value: 5, changes: changes);

    await tester.tap(_minus);

    expect(changes, isEmpty);
  });

  testWidgets('en büyük değerde artı çalışmaz', (tester) async {
    final changes = <int>[];
    await _pump(tester, value: 120, changes: changes);

    await tester.tap(_plus);

    expect(changes, isEmpty);
  });

  testWidgets('sınırdan bir adım önce son değere kadar gidilir', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, value: 115, changes: changes);

    await tester.tap(_plus);

    expect(changes, [120]);
  });

  testWidgets('değer sınırın üstündeyse artı kapalı, eksi çalışır', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, value: 130, changes: changes);

    await tester.tap(_plus);
    await tester.tap(_minus);

    expect(changes, [125]);
  });

  testWidgets('enabled false iken iki düğme de çalışmaz', (tester) async {
    final changes = <int>[];
    await _pump(tester, value: 35, changes: changes, enabled: false);

    await tester.tap(_plus);
    await tester.tap(_minus);

    expect(changes, isEmpty);
    expect(find.text('35 dk'), findsOneWidget);
  });
}
