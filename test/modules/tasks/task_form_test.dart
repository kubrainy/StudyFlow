import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/widgets/app_buttons.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/tasks/task_form.dart';

final _subjects = [
  Subject(
    id: 's1',
    name: 'Matematik',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    totalStudyMinutes: 0,
  ),
];

/// Formu alt panel olarak açar (kaydedince Navigator.pop çalışsın diye).
Future<void> _openForm(
  WidgetTester tester, {
  Task? task,
  String? initialSubjectId,
  required void Function(TaskFormData data) onSubmit,
  VoidCallback? onDelete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TaskForm(
                task: task,
                initialSubjectId: initialSubjectId,
                subjects: _subjects,
                onSubmit: (data) async => onSubmit(data),
                onDelete: onDelete,
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
}

Task _task({
  String title = 'Eski başlık',
  TaskPriority priority = TaskPriority.low,
  DateTime? dueDate,
  String? subjectId,
}) => Task(
  id: '1',
  title: title,
  priority: priority,
  dueDate: dueDate,
  subjectId: subjectId,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

bool _saveDisabled(WidgetTester tester) =>
    tester.widget<AppPrimaryButton>(find.byType(AppPrimaryButton)).onPressed ==
    null;

void main() {
  testWidgets('başlık boşken Kaydet kapalı, yazınca açılır', (tester) async {
    await _openForm(tester, onSubmit: (_) {});

    expect(_saveDisabled(tester), isTrue);

    await tester.enterText(find.byType(TextField).first, 'Ödev');
    await tester.pump();

    expect(_saveDisabled(tester), isFalse);
  });

  testWidgets('varsayılan olarak orta öncelik, tarihsiz, derssiz kaydeder', (
    tester,
  ) async {
    TaskFormData? saved;
    await _openForm(tester, onSubmit: (d) => saved = d);

    await tester.enterText(find.byType(TextField).first, '  Ödev  ');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saved?.title, 'Ödev');
    expect(saved?.priority, TaskPriority.medium);
    expect(saved?.dueDate, isNull);
    expect(saved?.subjectId, isNull);
    expect(saved?.description, isNull);
  });

  testWidgets('öncelik ve Bugün çipi seçilince forma yansır', (tester) async {
    TaskFormData? saved;
    await _openForm(tester, onSubmit: (d) => saved = d);

    await tester.enterText(find.byType(TextField).first, 'Ödev');
    await tester.tap(find.text('Yüksek'));
    await tester.tap(find.text('Bugün'));
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saved?.priority, TaskPriority.high);
    expect(saved?.dueDate, DateUtils.dateOnly(DateTime.now()));
  });

  testWidgets('seçili Bugün çipine tekrar basınca tarih kalkar', (
    tester,
  ) async {
    TaskFormData? saved;
    await _openForm(tester, onSubmit: (d) => saved = d);

    await tester.enterText(find.byType(TextField).first, 'Ödev');
    await tester.tap(find.text('Bugün'));
    await tester.pump();
    await tester.tap(find.text('Bugün'));
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saved?.dueDate, isNull);
  });

  testWidgets('düzenlemede mevcut değerler dolu gelir', (tester) async {
    await _openForm(
      tester,
      task: _task(subjectId: 's1'),
      onSubmit: (_) {},
    );

    expect(find.text('Görevi düzenle'), findsOneWidget);
    expect(find.text('Eski başlık'), findsOneWidget);
    expect(find.text('Matematik'), findsOneWidget);
  });

  testWidgets('initialSubjectId yeni görevde dersi önceden seçer', (
    tester,
  ) async {
    await _openForm(tester, initialSubjectId: 's1', onSubmit: (_) {});

    expect(find.text('Görev ekle'), findsOneWidget);
    expect(find.text('Matematik'), findsOneWidget);
  });

  testWidgets('silinmiş derse bağlı görevde ders "Ders yok" görünür', (
    tester,
  ) async {
    await _openForm(
      tester,
      task: _task(subjectId: 'silinmis'),
      onSubmit: (_) {},
    );

    expect(find.text('Ders yok'), findsOneWidget);
  });

  testWidgets('Görevi sil yalnızca onDelete verilince görünür', (tester) async {
    await _openForm(tester, onSubmit: (_) {});
    expect(find.text('Görevi sil'), findsNothing);
  });

  testWidgets('Görevi sil dokununca onDelete çağrılır', (tester) async {
    var deleted = false;
    await _openForm(
      tester,
      task: _task(),
      onSubmit: (_) {},
      onDelete: () => deleted = true,
    );

    await tester.ensureVisible(find.text('Görevi sil'));
    await tester.tap(find.text('Görevi sil'));

    expect(deleted, isTrue);
  });
}
