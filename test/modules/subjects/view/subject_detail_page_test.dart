import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/subjects/view/subject_detail_page.dart';
import 'package:studyflow/modules/subjects/view_model/subjects_view_model.dart';
import 'package:studyflow/modules/tasks/view/widgets/task_card.dart';
import 'package:studyflow/modules/tasks/view/widgets/task_form.dart';
import 'package:studyflow/modules/tasks/view_model/tasks_view_model.dart';

class _MockSubjectRepository extends Mock implements SubjectRepository {}

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  Subject subject({String? description}) => Subject(
    id: 'mat',
    name: 'Matematik',
    description: description,
    createdAt: DateTime(2026, 9, 14),
    updatedAt: DateTime(2026, 9, 14),
    totalStudyMinutes: 185,
  );

  Task task(String id, String title, {bool done = false}) => Task(
    id: id,
    subjectId: 'mat',
    title: title,
    isCompleted: done,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  late _MockSubjectRepository subjects;
  late _MockTaskRepository tasks;
  late List<Subject> storedSubjects;
  late List<Task> storedTasks;

  setUpAll(() => registerFallbackValue(task('x', 'x')));

  setUp(() {
    subjects = _MockSubjectRepository();
    tasks = _MockTaskRepository();
    storedSubjects = [subject(description: 'Türev, integral ve limit')];
    storedTasks = [task('t1', 'Türev soruları'), task('t2', 'Limit tekrarı')];
    when(() => subjects.getAll()).thenAnswer((_) => storedSubjects);
    when(() => tasks.getBySubjectId('mat')).thenAnswer((_) => storedTasks);
    when(() => tasks.setCompleted(any(), any()))
        .thenAnswer((invocation) async => invocation.positionalArguments.first);
  });

  Future<void> openPage(WidgetTester tester, {String id = 'mat'}) {
    return tester.pumpWidget(
      MaterialApp(
        home: SubjectDetailPage(
          subjectId: id,
          viewModel: SubjectsViewModel(subjects, tasks),
          tasksViewModel: TasksViewModel(tasks, subjects),
        ),
      ),
    );
  }

  testWidgets('ders adı, açıklama, çalışılan süre ve eklenme tarihi görünür', (
    tester,
  ) async {
    await openPage(tester);

    expect(find.text('Ders detayı'), findsOneWidget);
    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev, integral ve limit'), findsOneWidget);
    expect(find.text('185 dk çalışıldı'), findsOneWidget);
    expect(find.text('14.09.2026'), findsOneWidget);
  });

  testWidgets('açıklaması olmayan dersde açıklama satırı yoktur', (
    tester,
  ) async {
    storedSubjects = [subject()];
    await openPage(tester);

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türev, integral ve limit'), findsNothing);
  });

  testWidgets('dersin görevleri sayısıyla birlikte listelenir', (tester) async {
    await openPage(tester);

    expect(find.text('Görevler (2)'), findsOneWidget);
    expect(find.byType(TaskCard), findsNWidgets(2));
    expect(find.text('Türev soruları'), findsOneWidget);
    expect(find.text('Limit tekrarı'), findsOneWidget);
  });

  testWidgets('görevi olmayan dersde yalnızca Görevler (0) ve + düğmesi var', (
    tester,
  ) async {
    storedTasks = [];
    await openPage(tester);

    expect(find.text('Görevler (0)'), findsOneWidget);
    expect(find.byType(TaskCard), findsNothing);
    expect(find.byTooltip('Görev ekle'), findsOneWidget);
  });

  testWidgets('ders bulunamazsa bunu söyler', (tester) async {
    await openPage(tester, id: 'silinmis-ders');

    expect(find.text('Ders bulunamadı'), findsOneWidget);
    expect(find.byType(TaskCard), findsNothing);
  });

  testWidgets('tamamlama kutusuna dokununca görev tamamlanır', (tester) async {
    await openPage(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(TaskCard, 'Türev soruları'),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_TaskCheckbox',
        ),
      ),
    );
    await tester.pump();

    verify(() => tasks.setCompleted(storedTasks.first, true)).called(1);
  });

  testWidgets('ders kartına dokununca düzenleme formu açılır', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Matematik'));
    await tester.pumpAndSettle();

    expect(find.text('Dersi düzenle'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Matematik'), findsOneWidget);
  });

  testWidgets('+ yeni görev formunu bu ders seçili olarak açar', (
    tester,
  ) async {
    await openPage(tester);

    await tester.tap(find.byTooltip('Görev ekle'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskForm), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TaskForm),
        matching: find.text('Matematik'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('göreve dokununca görev düzenleme formu açılır', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Limit tekrarı'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskForm), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Limit tekrarı'), findsOneWidget);
    expect(find.text('Görevi sil'), findsOneWidget);
  });
}
