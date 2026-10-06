import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/study_session.dart';

void main() {
  group('StudySession', () {
    final session = StudySession(
      id: 'session-1',
      subjectId: 'abc-123',
      startedAt: DateTime(2026, 10, 2, 14, 0),
      durationMinutes: 25,
    );

    test('toJson sonra fromJson aynı oturumu verir', () {
      final result = StudySession.fromJson(session.toJson());

      expect(result.id, session.id);
      expect(result.subjectId, session.subjectId);
      expect(result.startedAt, session.startedAt);
      expect(result.durationMinutes, 25);
    });
    test('dersi olmayan oturum null subjectId ile gidip gelir', () {
      final free = StudySession(
        id: 'session-2',
        subjectId: null,
        startedAt: DateTime(2026, 10, 2, 15, 0),
        durationMinutes: 30,
      );

      final result = StudySession.fromJson(free.toJson());

      expect(result.subjectId, isNull);
      expect(result.durationMinutes, 30);
    });
  });
}
