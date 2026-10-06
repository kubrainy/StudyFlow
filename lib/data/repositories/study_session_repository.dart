import 'package:uuid/uuid.dart';

import '../../models/study_session.dart';
import '../local/study_session_local_source.dart';
import '../local/subject_local_source.dart';

class StudySessionRepository {
  final StudySessionLocalSource _sessions;
  final SubjectLocalSource _subjects;

  StudySessionRepository(this._sessions, this._subjects);

  List<StudySession> getAll() => _sessions.getAll();

  List<StudySession> getBySubjectId(String subjectId) =>
      _sessions.getBySubjectId(subjectId);

  Future<StudySession> add(
    String subjectId,
    DateTime startedAt,
    int durationMinutes,
  ) async {
    final subject = _subjects
        .getAll()
        .where((s) => s.id == subjectId)
        .firstOrNull;
    if (subject == null) {
      throw ArgumentError('Ders bulunamadı: $subjectId');
    }

    final session = StudySession(
      id: const Uuid().v4(),
      subjectId: subjectId,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
    );
    await _sessions.save(session);
    await _subjects.save(
      subject.copyWith(
        totalStudyMinutes: subject.totalStudyMinutes + durationMinutes,
        updatedAt: DateTime.now(),
      ),
    );
    return session;
  }
}
