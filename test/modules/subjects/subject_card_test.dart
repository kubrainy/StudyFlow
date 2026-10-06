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
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  int totalTasks = 0,
  int completedTasks = 0,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SubjectCard(
          subject: subject,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
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

  testWidgets('görev yoksa halkada kitap ikonu, yüzde yok', (tester) async {
    await _pumpCard(tester, _subject());

    expect(find.byKey(const Key('subject-ring')), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('görev varsa halkada yüzde yazar', (tester) async {
    await _pumpCard(tester, _subject(), totalTasks: 3, completedTasks: 2);

    expect(find.text('67%'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
  });

  testWidgets('hepsi bittiyse halkada tik gösterilir', (tester) async {
    await _pumpCard(tester, _subject(), totalTasks: 2, completedTasks: 2);

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('dokununca onTap çağrılır', (tester) async {
    var tapped = false;

    await _pumpCard(tester, _subject(), onTap: () => tapped = true);
    await tester.tap(find.text('Matematik'));

    expect(tapped, isTrue);
  });

  testWidgets('uzun basınca onLongPress çağrılır, onTap çağrılmaz', (
    tester,
  ) async {
    var tapped = false;
    var longPressed = false;

    await _pumpCard(
      tester,
      _subject(),
      onTap: () => tapped = true,
      onLongPress: () => longPressed = true,
    );
    await tester.longPress(find.text('Matematik'));

    expect(longPressed, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('kartta düzenle ve sil butonu yoktur', (tester) async {
    await _pumpCard(tester, _subject());

    expect(find.byTooltip('Düzenle'), findsNothing);
    expect(find.byTooltip('Sil'), findsNothing);
  });
}
