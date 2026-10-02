import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/local/study_session_local_source.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';

class MockStudySessionLocalSource extends Mock
    implements StudySessionLocalSource {}

class MockSubjectLocalSource extends Mock implements SubjectLocalSource {}

void main() {
  late MockStudySessionLocalSource sessions;
  late MockSubjectLocalSource subjects;
  late StudySessionRepository repository;

  final subject = Subject(
    id: 'subject-1',
    name: 'Matematik',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 90,
  );

  final session = StudySession(
    id: 'session-1',
    subjectId: 'subject-1',
    startedAt: DateTime(2026, 10, 2, 10),
    durationMinutes: 25,
  );

  setUpAll(() {
    registerFallbackValue(session);
    registerFallbackValue(subject);
  });

  setUp(() {
    sessions = MockStudySessionLocalSource();
    subjects = MockSubjectLocalSource();
    repository = StudySessionRepository(sessions, subjects);
    when(() => sessions.save(any())).thenAnswer((_) async {});
    when(() => subjects.save(any())).thenAnswer((_) async {});
  });

  group('StudySessionRepository okuma', () {
    test('getAll local source\'taki oturumları döndürür', () {
      when(() => sessions.getAll()).thenReturn([session]);

      expect(repository.getAll(), [session]);
    });

    test('getBySubjectId dersin oturumlarını local source\'tan alır', () {
      when(() => sessions.getBySubjectId('subject-1')).thenReturn([session]);

      expect(repository.getBySubjectId('subject-1'), [session]);
    });
  });
  group('StudySessionRepository.add', () {
    final startedAt = DateTime(2026, 10, 2, 14);

    test('oturumu kaydeder', () async {
      when(() => subjects.getAll()).thenReturn([subject]);

      final result = await repository.add('subject-1', startedAt, 25);

      expect(result.id, isNotEmpty);
      expect(result.subjectId, 'subject-1');
      expect(result.startedAt, startedAt);
      expect(result.durationMinutes, 25);
      verify(() => sessions.save(result)).called(1);
    });

    test('dersin toplam çalışma süresini artırır', () async {
      when(() => subjects.getAll()).thenReturn([subject]);

      await repository.add('subject-1', startedAt, 25);

      final saved =
          verify(() => subjects.save(captureAny())).captured.single as Subject;
      expect(saved.id, 'subject-1');
      expect(saved.totalStudyMinutes, 115);
    });

    test('ders yoksa hata verir ve hiçbir şey kaydetmez', () async {
      when(() => subjects.getAll()).thenReturn([]);

      await expectLater(
        repository.add('yok', startedAt, 25),
        throwsArgumentError,
      );

      verifyNever(() => sessions.save(any()));
      verifyNever(() => subjects.save(any()));
    });
  });
}
