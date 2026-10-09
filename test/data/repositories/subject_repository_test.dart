import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/network/api_client.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/remote/local_api_adapter.dart';
import 'package:studyflow/data/remote/subject_remote_source.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/models/subject.dart';

import '../remote/in_memory_local_sources.dart';

class MockSubjectLocalSource extends Mock implements SubjectLocalSource {}

class MockSubjectRemoteSource extends Mock implements SubjectRemoteSource {}

void main() {
  final subject = Subject(
    id: 'abc-123',
    name: 'Matematik',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 90,
  );

  setUpAll(() {
    registerFallbackValue(subject);
  });

  group('SubjectRepository (taklit kaynaklarla)', () {
    late MockSubjectLocalSource local;
    late MockSubjectRemoteSource remote;
    late SubjectRepository repository;

    setUp(() {
      local = MockSubjectLocalSource();
      remote = MockSubjectRemoteSource();
      repository = SubjectRepository(local, remote);

      // Sahte sunucu gibi: gelen dersi aynen geri verir.
      when(() => remote.create(any()))
          .thenAnswer((i) async => i.positionalArguments.first as Subject);
      when(() => remote.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as Subject);
      when(() => remote.delete(any())).thenAnswer((_) async {});
    });

    test('getAll local source\'taki dersleri döndürür', () {
      when(() => local.getAll()).thenReturn([subject]);

      final result = repository.getAll();

      expect(result, [subject]);
      verifyNever(() => remote.getAll());
    });

    test('getAll dersleri eklenme sırasına dizer (kimlik sırasına değil)', () {
      final first = subject.copyWith(name: 'Fizik');
      final second = Subject(
        id: 'aaa-000', // kimliği alfabede önce gelir, ama sonra eklendi
        name: 'Kimya',
        createdAt: DateTime(2026, 10, 2),
        updatedAt: DateTime(2026, 10, 2),
        totalStudyMinutes: 0,
      );
      final sameDay = Subject(
        id: 'zzz-999',
        name: 'Biyoloji',
        createdAt: DateTime(2026, 10, 2),
        updatedAt: DateTime(2026, 10, 2),
        totalStudyMinutes: 0,
      );
      // Hive'ın verdiği sıra: kimliğe göre.
      when(() => local.getAll()).thenReturn(List.unmodifiable([second, first, sameDay]));

      final result = repository.getAll();

      // Aynı gün eklenenler ada göre: Biyoloji, Kimya.
      expect(result.map((s) => s.name), ['Fizik', 'Biyoloji', 'Kimya']);
    });

    test('add yeni ders oluşturur ve REST\'e (POST) iletir', () async {
      final result = await repository.add('Fizik', 'Mekanik');

      expect(result.id, isNotEmpty);
      expect(result.name, 'Fizik');
      expect(result.description, 'Mekanik');
      expect(result.totalStudyMinutes, 0);
      expect(result.createdAt, result.updatedAt);
      verify(() => remote.create(result)).called(1);
      verifyNever(() => local.save(any()));
    });

    test('add her seferinde farklı id üretir', () async {
      final a = await repository.add('A', null);
      final b = await repository.add('B', null);

      expect(a.id, isNot(b.id));
    });

    test(
      'update adı değiştirir, id ve oluşturulma zamanı aynı kalır',
      () async {
        final result = await repository.update(subject, 'Fizik', 'Mekanik');

        expect(result.id, subject.id);
        expect(result.name, 'Fizik');
        expect(result.createdAt, subject.createdAt);
        expect(result.totalStudyMinutes, 90);
        expect(result.updatedAt.isAfter(subject.updatedAt), isTrue);
        verify(() => remote.update(result)).called(1);
        verifyNever(() => local.save(any()));
      },
    );

    test('update açıklama null ise eski açıklamayı siler', () async {
      final withDescription = Subject(
        id: 'abc-123',
        name: 'Matematik',
        description: 'Türev',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        totalStudyMinutes: 90,
      );

      final result = await repository.update(
        withDescription,
        'Matematik',
        null,
      );

      expect(result.description, isNull);
    });

    test('delete id\'yi REST\'e (DELETE) iletir', () async {
      await repository.delete('abc-123');

      verify(() => remote.delete('abc-123')).called(1);
      verifyNever(() => local.delete(any()));
    });

    test(
      'REST hata verirse add, update ve delete hatayı yukarı atar',
      () async {
        const error = ApiException('Bağlantı kurulamadı.');
        when(() => remote.create(any())).thenThrow(error);
        when(() => remote.update(any())).thenThrow(error);
        when(() => remote.delete(any())).thenThrow(error);

        expect(() => repository.add('A', null), throwsA(error));
        expect(() => repository.update(subject, 'A', null), throwsA(error));
        expect(() => repository.delete('abc-123'), throwsA(error));
      },
    );
  });

  // Taklit yok: Repository → Dio → sahte sunucu (LocalApiAdapter) → bellek.
  group('SubjectRepository (gerçek Dio zinciriyle)', () {
    late InMemorySubjectLocalSource store;
    late SubjectRepository repository;

    setUp(() {
      store = InMemorySubjectLocalSource();
      final dio = createDio(LocalApiAdapter(store, InMemoryTaskLocalSource()));
      repository = SubjectRepository(store, SubjectRemoteSource(dio));
    });

    test('add dersi sahte sunucuya kaydeder, getAll\'da görünür', () async {
      final created = await repository.add('Fizik', 'Mekanik');

      expect(store.items[created.id]?.name, 'Fizik');
      expect(repository.getAll().map((s) => s.id), [created.id]);
    });

    test('update kaydı günceller', () async {
      final created = await repository.add('Fizik', 'Mekanik');

      final updated = await repository.update(created, 'Kimya', null);

      expect(updated.id, created.id);
      expect(updated.description, isNull);
      expect(store.items[created.id]?.name, 'Kimya');
      expect(repository.getAll(), hasLength(1));
    });

    test('delete kaydı siler', () async {
      final created = await repository.add('Fizik', null);

      await repository.delete(created.id);

      expect(store.items, isEmpty);
      expect(repository.getAll(), isEmpty);
    });

    test('olmayan dersi güncellemek 404 ApiException verir', () async {
      expect(
        () => repository.update(subject, 'Kimya', null),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('olmayan dersi silmek 404 ApiException verir', () async {
      expect(
        () => repository.delete('yok'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}
