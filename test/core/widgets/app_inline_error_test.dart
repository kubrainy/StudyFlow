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
}
