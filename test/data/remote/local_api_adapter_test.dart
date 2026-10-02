import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/network/api_client.dart';
import 'package:studyflow/data/remote/local_api_adapter.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';

import 'in_memory_local_sources.dart';

void main() {
  late InMemorySubjectLocalSource subjects;
  late InMemoryTaskLocalSource tasks;
  late Dio dio;

  // Hata kodlarını (400, 404) exception yerine cevap olarak okumak için.
  final readAll = Options(validateStatus: (_) => true);

  final subject = Subject(
    id: 'subject-1',
    name: 'Matematik',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 0,
  );

  final task = Task(
    id: 'task-1',
    title: 'Türev soruları',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUp(() {
    subjects = InMemorySubjectLocalSource();
    tasks = InMemoryTaskLocalSource();
    dio = createDio(LocalApiAdapter(subjects, tasks));
  });

  group('LocalApiAdapter /subjects', () {
    test('GET /subjects boşken 200 ve boş liste döner', () async {
      final response = await dio.get('/subjects', options: readAll);

      expect(response.statusCode, 200);
      expect(response.data, isEmpty);
    });

    test('POST /subjects dersi kaydeder ve 201 döner', () async {
      final response = await dio.post(
        '/subjects',
        data: subject.toJson(),
        options: readAll,
      );

      expect(response.statusCode, 201);
      expect(response.data['name'], 'Matematik');
      expect(subjects.items.keys, ['subject-1']);
    });

    test('GET /subjects kayıtlı dersleri liste olarak döner', () async {
      subjects.items[subject.id] = subject;

      final response = await dio.get('/subjects', options: readAll);

      expect(response.statusCode, 200);
      expect(response.data.length, 1);
      expect(response.data.first['id'], 'subject-1');
    });

    test('GET /subjects/{id} tek dersi döner', () async {
      subjects.items[subject.id] = subject;

      final response = await dio.get('/subjects/subject-1', options: readAll);

      expect(response.statusCode, 200);
      expect(response.data['name'], 'Matematik');
    });

    test('GET /subjects/{id} olmayan ders için 404 döner', () async {
      final response = await dio.get('/subjects/yok', options: readAll);

      expect(response.statusCode, 404);
    });

    test('PUT /subjects/{id} dersin üzerine yazar ve 200 döner', () async {
      subjects.items[subject.id] = subject;

      final response = await dio.put(
        '/subjects/subject-1',
        data: subject.copyWith(name: 'Fizik').toJson(),
        options: readAll,
      );

      expect(response.statusCode, 200);
      expect(subjects.items['subject-1']!.name, 'Fizik');
    });

    test('PUT /subjects/{id} gövdedeki id farklıysa 400 döner', () async {
      subjects.items[subject.id] = subject;

      final response = await dio.put(
        '/subjects/subject-1',
        data: {...subject.toJson(), 'id': 'baska-id'},
        options: readAll,
      );

      expect(response.statusCode, 400);
      expect(subjects.items['subject-1']!.name, 'Matematik');
    });

    test('PUT /subjects/{id} olmayan ders için 404 döner', () async {
      final response = await dio.put(
        '/subjects/yok',
        data: subject.toJson(),
        options: readAll,
      );

      expect(response.statusCode, 404);
    });

    test('POST /subjects bozuk veride 400 döner ve kaydetmez', () async {
      final response = await dio.post(
        '/subjects',
        data: {'name': 'eksik alanlar'},
        options: readAll,
      );

      expect(response.statusCode, 400);
      expect(subjects.items, isEmpty);
    });

    test('DELETE /subjects/{id} dersi siler ve 204 döner', () async {
      subjects.items[subject.id] = subject;

      final response = await dio.delete(
        '/subjects/subject-1',
        options: readAll,
      );

      expect(response.statusCode, 204);
      expect(subjects.items, isEmpty);
    });

    test('DELETE /subjects/{id} olmayan ders için 404 döner', () async {
      final response = await dio.delete('/subjects/yok', options: readAll);

      expect(response.statusCode, 404);
    });
  });

  group('LocalApiAdapter /tasks', () {
    test('POST /tasks görevi kaydeder ve 201 döner', () async {
      final response = await dio.post(
        '/tasks',
        data: task.toJson(),
        options: readAll,
      );

      expect(response.statusCode, 201);
      expect(tasks.items.keys, ['task-1']);
    });

    test('GET /tasks ve GET /tasks/{id} kayıtlı görevi döner', () async {
      tasks.items[task.id] = task;

      final list = await dio.get('/tasks', options: readAll);
      final one = await dio.get('/tasks/task-1', options: readAll);

      expect(list.statusCode, 200);
      expect(list.data.length, 1);
      expect(one.statusCode, 200);
      expect(one.data['title'], 'Türev soruları');
    });

    test('PUT /tasks/{id} görevin üzerine yazar', () async {
      tasks.items[task.id] = task;

      final response = await dio.put(
        '/tasks/task-1',
        data: task.copyWith(isCompleted: true).toJson(),
        options: readAll,
      );

      expect(response.statusCode, 200);
      expect(tasks.items['task-1']!.isCompleted, isTrue);
    });

    test('DELETE /tasks/{id} görevi siler ve 204 döner', () async {
      tasks.items[task.id] = task;

      final response = await dio.delete('/tasks/task-1', options: readAll);

      expect(response.statusCode, 204);
      expect(tasks.items, isEmpty);
    });

    test('GET /tasks/{id} olmayan görev için 404 döner', () async {
      final response = await dio.get('/tasks/yok', options: readAll);

      expect(response.statusCode, 404);
    });

    test('POST /tasks bozuk veride 400 döner', () async {
      final response = await dio.post(
        '/tasks',
        data: {'title': 'eksik alanlar'},
        options: readAll,
      );

      expect(response.statusCode, 400);
      expect(tasks.items, isEmpty);
    });
  });

  group('LocalApiAdapter tanımadığı adres', () {
    test('bilinmeyen adres için 404 döner', () async {
      final response = await dio.get('/baska', options: readAll);

      expect(response.statusCode, 404);
    });
  });
}
