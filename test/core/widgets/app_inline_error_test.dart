import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/core/widgets/app_widgets.dart';

void main() {
  testWidgets('AppInlineError mesajı "İşlem başarısız:" ile kırmızı yazar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppInlineError(message: 'Kayıt bulunamadı.')),
      ),
    );

    final text = tester.widget<Text>(
      find.text('İşlem başarısız: Kayıt bulunamadı.'),
    );
    expect(text.style?.color, AppColors.danger);
  });

  group('AppWithInlineError', () {
    Future<void> pump(WidgetTester tester, String? error) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppWithInlineError(error: error, child: const Text('içerik')),
        ),
      ),
    );

    testWidgets('hata yokken yalnızca içerik görünür', (tester) async {
      await pump(tester, null);

      expect(find.text('içerik'), findsOneWidget);
      expect(find.byType(AppInlineError), findsNothing);
    });

    testWidgets('hata varsa içeriğin üstünde hata satırı görünür', (
      tester,
    ) async {
      await pump(tester, 'Kayıt bulunamadı.');

      expect(find.text('içerik'), findsOneWidget);
      expect(find.text('İşlem başarısız: Kayıt bulunamadı.'), findsOneWidget);
      final errorY = tester.getTopLeft(find.byType(AppInlineError)).dy;
      final contentY = tester.getTopLeft(find.text('içerik')).dy;
      expect(errorY, lessThan(contentY));
    });
  });
}
