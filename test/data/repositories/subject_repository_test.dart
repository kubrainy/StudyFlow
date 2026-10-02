import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/models/subject.dart';

class MockSubjectLocalSource extends Mock implements SubjectLocalSource {}

void main() {
  late MockSubjectLocalSource local;
  late SubjectRepository repository;

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

  setUp(() {
    local = MockSubjectLocalSource();
    repository = SubjectRepository(local);
  });

  group('SubjectRepository', () {
    test('getAll local source\'taki dersleri döndürür', () {
      when(() => local.getAll()).thenReturn([subject]);

      final result = repository.getAll();

      expect(result, [subject]);
    });
    test('add yeni ders oluşturur ve kaydeder', () async {
      when(() => local.save(any())).thenAnswer((_) async {});

      final result = await repository.add('Fizik', 'Mekanik');

      expect(result.id, isNotEmpty);
      expect(result.name, 'Fizik');
      expect(result.description, 'Mekanik');
      expect(result.totalStudyMinutes, 0);
      expect(result.createdAt, result.updatedAt);
      verify(() => local.save(result)).called(1);
    });

    test('add her seferinde farklı id üretir', () async {
      when(() => local.save(any())).thenAnswer((_) async {});

      final a = await repository.add('A', null);
      final b = await repository.add('B', null);

      expect(a.id, isNot(b.id));
    });

    test(
      'update adı değiştirir, id ve oluşturulma zamanı aynı kalır',
      () async {
        when(() => local.save(any())).thenAnswer((_) async {});

        final result = await repository.update(subject, 'Fizik', 'Mekanik');

        expect(result.id, subject.id);
        expect(result.name, 'Fizik');
        expect(result.createdAt, subject.createdAt);
        expect(result.totalStudyMinutes, 90);
        expect(result.updatedAt.isAfter(subject.updatedAt), isTrue);
        verify(() => local.save(result)).called(1);
      },
    );

    test('delete id\'yi local source\'a iletir', () async {
      when(() => local.delete(any())).thenAnswer((_) async {});

      await repository.delete('abc-123');

      verify(() => local.delete('abc-123')).called(1);
    });
  });
}
