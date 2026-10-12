import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_card.dart';

import '../../../../helpers/test_fonts.dart';

Subject _subject({String? description, int minutes = 1110}) => Subject(
  id: '1',
  name: 'Matematik',
  description: description,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  totalStudyMinutes: minutes,
);

Future<void> _pumpCard(
  WidgetTester tester,
  Subject subject, {
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  VoidCallback? onStudy,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  int totalTasks = 0,
  int completedTasks = 0,
  String? nextTaskTitle,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SubjectCard(
            subject: subject,
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            nextTaskTitle: nextTaskTitle,
            onTap: onTap,
            onLongPress: onLongPress,
            onStudy: onStudy,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('ad, açıklama ve toplam süre gösterilir', (tester) async {
    await _pumpCard(tester, _subject(description: 'Türev ve integral'));

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev ve integral'), findsOneWidget);
    expect(find.text('TOPLAM SÜRE'), findsOneWidget);
    expect(find.text('18s 30dk'), findsOneWidget);
  });

  testWidgets('açıklama yoksa açıklama rozeti gösterilmez', (tester) async {
    await _pumpCard(tester, _subject());

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev ve integral'), findsNothing);
  });

  testWidgets('görev yoksa "Görev yok" ve boş çubuk yazılır', (tester) async {
    await _pumpCard(tester, _subject());

    expect(find.text('Görev yok'), findsOneWidget);
    expect(find.text('Görev İlerlemesi (%0)'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(find.text('Henüz görev yok'), findsOneWidget);
  });

  testWidgets('bekleyen görev sayısı, ilerleme ve sıradaki görev yazılır', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _subject(),
      totalTasks: 3,
      completedTasks: 2,
      nextTaskTitle: 'SQL Lab',
    );

    expect(find.text('1 Görev bekliyor'), findsOneWidget);
    expect(find.text('Görev İlerlemesi (%67)'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('SQL Lab'), findsOneWidget);
  });

  testWidgets('çubuk tamamlanma oranını gösterir', (tester) async {
    await _pumpCard(tester, _subject(), totalTasks: 4, completedTasks: 1);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('subject-progress')),
    );
    expect(bar.value, 0.25);
  });

  testWidgets('hepsi bittiyse "Hepsi bitti" ve yeşil tik satırı görünür', (
    tester,
  ) async {
    await _pumpCard(tester, _subject(), totalTasks: 2, completedTasks: 2);

    expect(find.text('Hepsi bitti'), findsOneWidget);
    expect(find.text('Tüm görevler tamam'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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

  testWidgets('Hemen Çalış onStudy çağırır, onTap çağırmaz', (tester) async {
    var studied = false;
    var tapped = false;

    await _pumpCard(
      tester,
      _subject(),
      onTap: () => tapped = true,
      onStudy: () => studied = true,
    );
    await tester.tap(find.byKey(const Key('subject-study')));

    expect(studied, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('üç nokta menüsü Düzenle ve Sil seçeneklerini açar', (
    tester,
  ) async {
    var edited = false;
    var deleted = false;

    await _pumpCard(
      tester,
      _subject(),
      onEdit: () => edited = true,
      onDelete: () => deleted = true,
    );
    await tester.tap(find.byTooltip('Daha fazla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    await tester.tap(find.byTooltip('Daha fazla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('menü eylemi verilmezse üç nokta görünmez', (tester) async {
    await _pumpCard(tester, _subject());

    expect(find.byTooltip('Daha fazla'), findsNothing);
  });
}
