import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_boxes.dart';
import '../../models/study_session.dart';

class StudySessionLocalSource {
  Box get _box => Hive.box(HiveBoxes.studySessions);

  List<StudySession> getAll() {
    return _box.values
        .map((e) => StudySession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<StudySession> getBySubjectId(String subjectId) {
    return getAll().where((s) => s.subjectId == subjectId).toList();
  }

  Future<void> save(StudySession session) => _box.put(session.id, session.toJson());

  Future<void> delete(String id) => _box.delete(id);
}
