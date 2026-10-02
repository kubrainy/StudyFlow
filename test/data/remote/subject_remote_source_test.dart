import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/network/api_client.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/remote/local_api_adapter.dart';
import 'package:studyflow/data/remote/subject_remote_source.dart';
import 'package:studyflow/models/subject.dart';

import 'in_memory_local_sources.dart';

void main() {
  late InMemorySubjectLocalSource subjects;
  late SubjectRemoteSource remote;

  final subject = Subject(
    id: 'subject-1',
    name: 'Matematik',
    description: 'Analiz',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 30,
  );

  setUp(() {
    subjects = InMemorySubjectLocalSource();
    final dio = createDio(LocalApiAdapter(subjects, InMemoryTaskLocalSource()));
    remote = SubjectRemoteSource(dio);
  });

  group('SubjectRemoteSource', () {
    test('getAll başlangıçta boş liste döner', () async {
      expect(await remote.getAll(), isEmpty);
    });

    test('create dersi kaydeder ve aynı alanlarla geri döndürür', () async {
      final created = await remote.create(subject);

      expect(created.id, 'subject-1');
      expect(created.name, 'Matematik');
      expect(created.description, 'Analiz');
      expect(created.totalStudyMinutes, 30);
      expect(subjects.items.keys, ['subject-1']);
    });

    test('getAll kayıtlı dersleri Subject listesine çevirir', () async {
      await remote.create(subject);

      final result = await remote.getAll();

      expect(result.length, 1);
      expect(result.first.name, 'Matematik');
      expect(result.first.createdAt, DateTime(2026, 10, 1));
    });

    test('update dersin adını değiştirir', () async {
      await remote.create(subject);

      final updated = await remote.update(subject.copyWith(name: 'Fizik'));

      expect(updated.name, 'Fizik');
      expect(subjects.items['subject-1']!.name, 'Fizik');
    });

    test('delete dersi siler', () async {
      await remote.create(subject);

      await remote.delete('subject-1');

      expect(subjects.items, isEmpty);
    });

    test('olmayan dersi güncellemek 404 ApiException fırlatır', () async {
      await expectLater(
        remote.update(subject),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Kayıt bulunamadı.'),
        ),
      );
    });

    test('olmayan dersi silmek 404 ApiException fırlatır', () async {
      await expectLater(
        remote.delete('yok'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}
