import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/network/api_client.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/remote/local_api_adapter.dart';
import 'package:studyflow/data/remote/task_remote_source.dart';
import 'package:studyflow/models/task.dart';

import 'in_memory_local_sources.dart';

void main() {
  late InMemoryTaskLocalSource tasks;
  late TaskRemoteSource remote;

  final task = Task(
    id: 'task-1',
    subjectId: 'subject-1',
    title: 'Türev soruları',
    priority: TaskPriority.high,
    dueDate: DateTime(2026, 10, 10),
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUp(() {
    tasks = InMemoryTaskLocalSource();
    final dio = createDio(LocalApiAdapter(InMemorySubjectLocalSource(), tasks));
    remote = TaskRemoteSource(dio);
  });

  group('TaskRemoteSource', () {
    test('getAll başlangıçta boş liste döner', () async {
      expect(await remote.getAll(), isEmpty);
    });

    test('create görevi kaydeder ve alanlarını korur', () async {
      final created = await remote.create(task);

      expect(created.id, 'task-1');
      expect(created.priority, TaskPriority.high);
      expect(created.dueDate, DateTime(2026, 10, 10));
      expect(created.isCompleted, isFalse);
      expect(tasks.items.keys, ['task-1']);
    });

    test('getAll kayıtlı görevleri Task listesine çevirir', () async {
      await remote.create(task);

      final result = await remote.getAll();

      expect(result.length, 1);
      expect(result.first.title, 'Türev soruları');
    });

    test('update görevin tamamlanma durumunu değiştirir', () async {
      await remote.create(task);

      final updated = await remote.update(
        task.copyWith(isCompleted: true, completedAt: DateTime(2026, 10, 2)),
      );

      expect(updated.isCompleted, isTrue);
      expect(updated.completedAt, DateTime(2026, 10, 2));
      expect(tasks.items['task-1']!.isCompleted, isTrue);
    });

    test('delete görevi siler', () async {
      await remote.create(task);

      await remote.delete('task-1');

      expect(tasks.items, isEmpty);
    });

    test('olmayan görevi güncellemek 404 ApiException fırlatır', () async {
      await expectLater(
        remote.update(task),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('olmayan görevi silmek 404 ApiException fırlatır', () async {
      await expectLater(
        remote.delete('yok'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}
