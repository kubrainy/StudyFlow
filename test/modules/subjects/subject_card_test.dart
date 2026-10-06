import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/modules/subjects/subject_card.dart';

Subject _subject({String? description}) => Subject(
  id: '1',
  name: 'Matematik',
  description: description,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  totalStudyMinutes: 25,
);

Future<void> _pumpCard(
  WidgetTester tester,
  Subject subject, {
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SubjectCard(subject: subject, onEdit: onEdit, onDelete: onDelete),
      ),
    ),
  );
}

void main() {
  testWidgets('ad, açıklama ve süre gösterilir', (tester) async {
    await _pumpCard(tester, _subject(description: 'Türev ve integral'));

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev ve integral'), findsOneWidget);
    expect(find.text('25 dk'), findsOneWidget);
  });

  testWidgets('açıklama yoksa açıklama metni gösterilmez', (tester) async {
    await _pumpCard(tester, _subject());

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev ve integral'), findsNothing);
  });

  testWidgets('düzenle ve sil butonları callback çağırır', (tester) async {
    var edited = false;
    var deleted = false;

    await _pumpCard(
      tester,
      _subject(),
      onEdit: () => edited = true,
      onDelete: () => deleted = true,
    );

    await tester.tap(find.byTooltip('Düzenle'));
    await tester.tap(find.byTooltip('Sil'));

    expect(edited, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets('callback verilmezse butonlar disabled olur', (tester) async {
    await _pumpCard(tester, _subject());

    final edit = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.edit_outlined),
    );
    final delete = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );

    expect(edit.onPressed, isNull);
    expect(delete.onPressed, isNull);
  });
}
