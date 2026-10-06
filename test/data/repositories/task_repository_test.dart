import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/task.dart';

class MockTaskLocalSource extends Mock implements TaskLocalSource {}

void main() {
  late MockTaskLocalSource local;
  late TaskRepository repository;

  final task = Task(
    id: 'task-1',
    subjectId: 'subject-1',
    title: 'Türev soruları',
    description: '10 soru çöz',
    priority: TaskPriority.high,
    dueDate: DateTime(2026, 10, 10),
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUpAll(() {
    registerFallbackValue(task);
  });

  setUp(() {
    local = MockTaskLocalSource();
    repository = TaskRepository(local);
    when(() => local.save(any())).thenAnswer((_) async {});
  });

  group('TaskRepository okuma ve silme', () {
    test('getAll local source\'taki görevleri döndürür', () {
      when(() => local.getAll()).thenReturn([task]);

      expect(repository.getAll(), [task]);
    });

    test('getBySubjectId dersin görevlerini local source\'tan alır', () {
      when(() => local.getBySubjectId('subject-1')).thenReturn([task]);

      expect(repository.getBySubjectId('subject-1'), [task]);
    });

    test('delete id\'yi local source\'a iletir', () async {
      when(() => local.delete(any())).thenAnswer((_) async {});

      await repository.delete('task-1');

      verify(() => local.delete('task-1')).called(1);
    });

    test('deleteBySubjectId sadece o dersin görevlerini siler', () async {
      final second = Task(
        id: 'task-2',
        subjectId: 'subject-1',
        title: 'İkinci görev',
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
      );
      when(() => local.getBySubjectId('subject-1')).thenReturn([task, second]);
      when(() => local.delete(any())).thenAnswer((_) async {});

      await repository.deleteBySubjectId('subject-1');

      verify(() => local.delete('task-1')).called(1);
      verify(() => local.delete('task-2')).called(1);
      verifyNever(() => local.getAll());
    });
  });

  group('TaskRepository.add', () {
    test('sadece başlık verilince varsayılan değerlerle oluşturur', () async {
      final result = await repository.add('Konu tekrarı');

      expect(result.id, isNotEmpty);
      expect(result.title, 'Konu tekrarı');
      expect(result.priority, TaskPriority.medium);
      expect(result.isCompleted, isFalse);
      expect(result.completedAt, isNull);
      expect(result.dueDate, isNull);
      expect(result.subjectId, isNull);
      expect(result.createdAt, result.updatedAt);
      verify(() => local.save(result)).called(1);
    });

    test('verilen ders, öncelik, açıklama ve son tarihi saklar', () async {
      final due = DateTime(2026, 10, 15);

      final result = await repository.add(
        'Rapor yaz',
        description: 'Laboratuvar raporu',
        subjectId: 'subject-2',
        priority: TaskPriority.low,
        dueDate: due,
      );

      expect(result.description, 'Laboratuvar raporu');
      expect(result.subjectId, 'subject-2');
      expect(result.priority, TaskPriority.low);
      expect(result.dueDate, due);
    });

    test('her seferinde farklı id üretir', () async {
      final a = await repository.add('A');
      final b = await repository.add('B');

      expect(a.id, isNot(b.id));
    });
  });

  group('TaskRepository.update', () {
    test('sadece verilen alanı değiştirir, diğerlerini korur', () async {
      final result = await repository.update(task, priority: TaskPriority.low);

      expect(result.priority, TaskPriority.low);
      expect(result.id, task.id);
      expect(result.title, task.title);
      expect(result.description, task.description);
      expect(result.subjectId, task.subjectId);
      expect(result.dueDate, task.dueDate);
      expect(result.createdAt, task.createdAt);
      expect(result.updatedAt.isAfter(task.updatedAt), isTrue);
      verify(() => local.save(result)).called(1);
    });

    test('tamamlanma durumuna dokunmaz', () async {
      final completed = task.copyWith(
        isCompleted: true,
        completedAt: DateTime(2026, 10, 2),
      );

      final result = await repository.update(completed, title: 'Yeni başlık');

      expect(result.title, 'Yeni başlık');
      expect(result.isCompleted, isTrue);
      expect(result.completedAt, DateTime(2026, 10, 2));
    });

    test('clear bayrakları açıklama, son tarih ve dersi boşaltır', () async {
      final result = await repository.update(
        task,
        clearDescription: true,
        clearDueDate: true,
        clearSubjectId: true,
      );

      expect(result.description, isNull);
      expect(result.dueDate, isNull);
      expect(result.subjectId, isNull);
      expect(result.title, task.title);
      verify(() => local.save(result)).called(1);
    });
  });

  group('TaskRepository.setCompleted', () {
    test(
      'tamamlandı yapınca isCompleted true ve completedAt dolu olur',
      () async {
        final result = await repository.setCompleted(task, true);

        expect(result.isCompleted, isTrue);
        expect(result.completedAt, isNotNull);
        expect(result.completedAt, result.updatedAt);
        verify(() => local.save(result)).called(1);
      },
    );

    test('geri alınca isCompleted false olur ve completedAt boşalır', () async {
      final completed = task.copyWith(
        isCompleted: true,
        completedAt: DateTime(2026, 10, 2),
      );

      final result = await repository.setCompleted(completed, false);

      expect(result.isCompleted, isFalse);
      expect(result.completedAt, isNull);
      verify(() => local.save(result)).called(1);
    });
  });
}
