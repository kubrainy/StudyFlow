import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/subjects/controller/subjects_controller.dart';

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockSubjectRepository subjects;
  late MockTaskRepository tasks;
  late SubjectsController controller;

  setUp(() {
    subjects = MockSubjectRepository();
    tasks = MockTaskRepository();
    controller = SubjectsController(subjects, tasks);
    when(() => subjects.getAll()).thenReturn([]);
    when(() => subjects.delete(any())).thenAnswer((_) async {});
    when(() => tasks.deleteBySubjectId(any())).thenAnswer((_) async {});
  });

  group('SubjectsController.delete', () {
    test('dersi silmeden önce ona bağlı görevleri siler', () async {
      await controller.delete('ders-1');

      verifyInOrder([
        () => tasks.deleteBySubjectId('ders-1'),
        () => subjects.delete('ders-1'),
      ]);
    });

    test('silince listeyi yeniler', () async {
      await controller.delete('ders-1');

      verify(() => subjects.getAll()).called(1);
      expect(controller.status, SubjectsStatus.empty);
    });
  });

  group('SubjectsController.taskProgress', () {
    Task task(String id, {bool done = false}) => Task(
      id: id,
      title: id,
      isCompleted: done,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('toplam ve tamamlanan görev sayısını verir', () {
      when(
        () => tasks.getBySubjectId('ders-1'),
      ).thenReturn([task('a', done: true), task('b'), task('c', done: true)]);

      final progress = controller.taskProgress('ders-1');

      expect(progress.total, 3);
      expect(progress.completed, 2);
    });

    test('görev yoksa ikisi de sıfır', () {
      when(() => tasks.getBySubjectId('ders-1')).thenReturn([]);

      final progress = controller.taskProgress('ders-1');

      expect(progress.total, 0);
      expect(progress.completed, 0);
    });
  });
}
