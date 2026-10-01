import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/data/local/study_session_local_source.dart';
import 'package:studyflow/models/study_session.dart';

void main() {
  late Directory tempDir;
  late StudySessionLocalSource source;

  StudySession makeSession(String id, String subjectId) => StudySession(
    id: id,
    subjectId: subjectId,
    startedAt: DateTime(2026, 10, 2, 14, 0),
    durationMinutes: 25,
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.studySessions);
    source = StudySessionLocalSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('StudySessionLocalSource', () {
    test('kaydedilen oturum geri okunur', () async {
      await source.save(makeSession('s1', 'mat'));

      final result = source.getAll();

      expect(result.length, 1);
      expect(result.first.durationMinutes, 25);
    });

    test('silinen oturum listeden kalkar', () async {
      await source.save(makeSession('s1', 'mat'));
      await source.delete('s1');

      expect(source.getAll(), isEmpty);
    });

    test('getBySubjectId yalnızca o dersin oturumlarını getirir', () async {
      await source.save(makeSession('s1', 'mat'));
      await source.save(makeSession('s2', 'fizik'));

      final result = source.getBySubjectId('fizik');

      expect(result.length, 1);
      expect(result.first.id, 's2');
    });
  });
}
