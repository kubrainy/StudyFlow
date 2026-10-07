import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/widgets/app_buttons.dart';

Future<void> _pump(WidgetTester tester, {bool compact = false}) {
  return tester.pumpWidget(
    MaterialApp(
      // Sayfalarda düğme bir Column içinde durur (yükseklik sınırsız).
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              width: 300,
              child: AppPrimaryButton(
                label: 'Kaydet',
                onPressed: () {},
                compact: compact,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('compact düğme normal düğmeden alçaktır', (tester) async {
    await _pump(tester);
    final normal = tester.getSize(find.byType(AppPrimaryButton)).height;

    await _pump(tester, compact: true);
    final compact = tester.getSize(find.byType(AppPrimaryButton)).height;

    expect(compact, lessThan(normal));
  });

  testWidgets('uzun etiket taşmaz, ... ile kesilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 80,
            child: AppPrimaryButton(
              label: 'Çok uzun bir düğme yazısı',
              onPressed: () {},
              compact: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('basılınca onPressed çağrılır', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(label: 'Kaydet', onPressed: () => taps++),
        ),
      ),
    );

    await tester.tap(find.text('Kaydet'));

    expect(taps, 1);
  });
}
