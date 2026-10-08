import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/network/api_client.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/data/remote/local_api_adapter.dart';
import 'package:studyflow/data/remote/task_remote_source.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/task.dart';

import '../remote/in_memory_local_sources.dart';

class MockTaskLocalSource extends Mock implements TaskLocalSource {}

class MockTaskRemoteSource extends Mock implements TaskRemoteSource {}

void main() {
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

  group('TaskRepository (taklit kaynaklarla)', () {
    late MockTaskLocalSource local;
    late MockTaskRemoteSource remote;
    late TaskRepository repository;

    setUp(() {
      local = MockTaskLocalSource();
      remote = MockTaskRemoteSource();
      repository = TaskRepository(local, remote);

      // Sahte sunucu gibi: gelen görevi aynen geri verir.
      when(() => remote.create(any()))
          .thenAnswer((i) async => i.positionalArguments.first as Task);
      when(() => remote.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as Task);
      when(() => remote.delete(any())).thenAnswer((_) async {});
    });

    group('okuma ve silme', () {
      test('getAll local source\'taki görevleri döndürür', () {
        when(() => local.getAll()).thenReturn([task]);

        expect(repository.getAll(), [task]);
        verifyNever(() => remote.getAll());
      });

      test('getBySubjectId dersin görevlerini local source\'tan alır', () {
        when(() => local.getBySubjectId('subject-1')).thenReturn([task]);

        expect(repository.getBySubjectId('subject-1'), [task]);
      });

      test('delete id\'yi REST\'e (DELETE) iletir', () async {
        await repository.delete('task-1');

        verify(() => remote.delete('task-1')).called(1);
        verifyNever(() => local.delete(any()));
      });

      test('deleteBySubjectId sadece o dersin görevlerini siler', () async {
        final second = Task(
          id: 'task-2',
          subjectId: 'subject-1',
          title: 'İkinci görev',
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        );
        when(() => local.getBySubjectId('subject-1'))
            .thenReturn([task, second]);

        await repository.deleteBySubjectId('subject-1');

        verify(() => remote.delete('task-1')).called(1);
        verify(() => remote.delete('task-2')).called(1);
        verifyNever(() => local.delete(any()));
        verifyNever(() => local.getAll());
      });

      test('deleteBySubjectId hata verince durur ve hatayı atar', () async {
        final second = Task(
          id: 'task-2',
          subjectId: 'subject-1',
          title: 'İkinci görev',
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        );
        const error = ApiException('Sunucu hatası.');
        when(() => local.getBySubjectId('subject-1'))
            .thenReturn([task, second]);
        when(() => remote.delete('task-1')).thenThrow(error);

        expect(() => repository.deleteBySubjectId('subject-1'), throwsA(error));
        verifyNever(() => remote.delete('task-2'));
      });
    });

    group('add', () {
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
        verify(() => remote.create(result)).called(1);
        verifyNever(() => local.save(any()));
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

    group('update', () {
      test('sadece verilen alanı değiştirir, diğerlerini korur', () async {
        final result = await repository.update(
          task,
          priority: TaskPriority.low,
        );

        expect(result.priority, TaskPriority.low);
        expect(result.id, task.id);
        expect(result.title, task.title);
        expect(result.description, task.description);
        expect(result.subjectId, task.subjectId);
        expect(result.dueDate, task.dueDate);
        expect(result.createdAt, task.createdAt);
        expect(result.updatedAt.isAfter(task.updatedAt), isTrue);
        verify(() => remote.update(result)).called(1);
        verifyNever(() => local.save(any()));
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
        verify(() => remote.update(result)).called(1);
      });
    });

    group('setCompleted', () {
      test(
        'tamamlandı yapınca isCompleted true ve completedAt dolu olur',
        () async {
          final result = await repository.setCompleted(task, true);

          expect(result.isCompleted, isTrue);
          expect(result.completedAt, isNotNull);
          expect(result.completedAt, result.updatedAt);
          verify(() => remote.update(result)).called(1);
          verifyNever(() => local.save(any()));
        },
      );

      test(
        'geri alınca isCompleted false olur ve completedAt boşalır',
        () async {
          final completed = task.copyWith(
            isCompleted: true,
            completedAt: DateTime(2026, 10, 2),
          );

          final result = await repository.setCompleted(completed, false);

          expect(result.isCompleted, isFalse);
          expect(result.completedAt, isNull);
          verify(() => remote.update(result)).called(1);
        },
      );
    });

    test('REST hata verirse yazma metotları hatayı yukarı atar', () async {
      const error = ApiException('Bağlantı kurulamadı.');
      when(() => remote.create(any())).thenThrow(error);
      when(() => remote.update(any())).thenThrow(error);
      when(() => remote.delete(any())).thenThrow(error);

      expect(() => repository.add('A'), throwsA(error));
      expect(() => repository.update(task, title: 'B'), throwsA(error));
      expect(() => repository.setCompleted(task, true), throwsA(error));
      expect(() => repository.delete('task-1'), throwsA(error));
    });
  });

  // Taklit yok: Repository → Dio → sahte sunucu (LocalApiAdapter) → bellek.
  group('TaskRepository (gerçek Dio zinciriyle)', () {
    late InMemoryTaskLocalSource store;
    late TaskRepository repository;

    setUp(() {
      store = InMemoryTaskLocalSource();
      final dio = createDio(
        LocalApiAdapter(InMemorySubjectLocalSource(), store),
      );
      repository = TaskRepository(store, TaskRemoteSource(dio));
    });

    test('add görevi tüm alanlarıyla kaydeder, okumada görünür', () async {
      final due = DateTime(2026, 10, 15);

      final created = await repository.add(
        'Rapor yaz',
        description: 'Laboratuvar raporu',
        subjectId: 'subject-2',
        priority: TaskPriority.low,
        dueDate: due,
      );

      final saved = store.items[created.id]!;
      expect(saved.title, 'Rapor yaz');
      expect(saved.description, 'Laboratuvar raporu');
      expect(saved.subjectId, 'subject-2');
      expect(saved.priority, TaskPriority.low);
      expect(saved.dueDate, due);
      expect(repository.getAll().map((t) => t.id), [created.id]);
      expect(repository.getBySubjectId('subject-2'), hasLength(1));
    });

    test('update alanı günceller, clear bayrağı alanı boşaltır', () async {
      final created = await repository.add(
        'Rapor yaz',
        dueDate: DateTime(2026, 10, 15),
      );

      final updated = await repository.update(
        created,
        title: 'Rapor bitir',
        clearDueDate: true,
      );

      expect(updated.id, created.id);
      expect(store.items[created.id]?.title, 'Rapor bitir');
      expect(store.items[created.id]?.dueDate, isNull);
    });

    test(
      'setCompleted durumu yazar, geri alınca completedAt boşalır',
      () async {
        final created = await repository.add('Rapor yaz');

        final done = await repository.setCompleted(created, true);
        expect(store.items[created.id]?.isCompleted, isTrue);
        expect(store.items[created.id]?.completedAt, done.completedAt);

        await repository.setCompleted(done, false);
        expect(store.items[created.id]?.isCompleted, isFalse);
        expect(store.items[created.id]?.completedAt, isNull);
      },
    );

    test('delete görevi siler', () async {
      final created = await repository.add('Rapor yaz');

      await repository.delete(created.id);

      expect(store.items, isEmpty);
    });

    test('deleteBySubjectId yalnızca o dersin görevlerini siler', () async {
      await repository.add('A', subjectId: 'subject-1');
      await repository.add('B', subjectId: 'subject-1');
      final other = await repository.add('C', subjectId: 'subject-2');

      await repository.deleteBySubjectId('subject-1');

      expect(store.items.keys, [other.id]);
    });

    test('olmayan görevi güncellemek, tamamlamak, silmek 404 verir', () async {
      Matcher notFound() => throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
      );

      expect(() => repository.update(task, title: 'X'), notFound());
      expect(() => repository.setCompleted(task, true), notFound());
      expect(() => repository.delete('yok'), notFound());
    });
  });
}
