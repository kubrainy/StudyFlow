import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/widgets/app_buttons.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_form.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  Subject? subject,
  Future<void> Function(String name, String? description)? onSubmit,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SubjectForm(
          subject: subject,
          onSubmit: onSubmit ?? (_, _) async {},
        ),
      ),
    ),
  );
}

VoidCallback? _saveCallback(WidgetTester tester) =>
    tester.widget<AppPrimaryButton>(find.byType(AppPrimaryButton)).onPressed;

void main() {
  testWidgets('ad boşken kaydet butonu disabled', (tester) async {
    await _pumpForm(tester);

    expect(_saveCallback(tester), isNull);
  });

  testWidgets('ad yazılınca kaydet butonu aktif olur', (tester) async {
    await _pumpForm(tester);

    await tester.enterText(find.byType(TextField).first, 'Fizik');
    await tester.pump();

    expect(_saveCallback(tester), isNotNull);
  });

  testWidgets('sadece boşluktan oluşan ad kabul edilmez', (tester) async {
    await _pumpForm(tester);

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();

    expect(_saveCallback(tester), isNull);
  });

  testWidgets('düzenlemede alanlar dolu gelir', (tester) async {
    final subject = Subject(
      id: '1',
      name: 'Matematik',
      description: 'Türev',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      totalStudyMinutes: 0,
    );

    await _pumpForm(tester, subject: subject);

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev'), findsOneWidget);
    expect(find.text('Dersi düzenle'), findsOneWidget);
    expect(_saveCallback(tester), isNotNull);
  });

  testWidgets('kaydet ad ve boş açıklamayı null olarak iletir', (tester) async {
    String? savedName;
    String? savedDescription = 'değişmedi';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => SubjectForm(
                  onSubmit: (name, description) async {
                    savedName = name;
                    savedDescription = description;
                  },
                ),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '  Fizik  ');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(savedName, 'Fizik');
    expect(savedDescription, isNull);
    expect(find.byType(SubjectForm), findsNothing);
  });
}
