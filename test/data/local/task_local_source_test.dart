import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/models/task.dart';

void main() {
  late Directory tempDir;
  late TaskLocalSource source;

  Task makeTask(String id, {String? subjectId}) => Task(
    id: id,
    subjectId: subjectId,
    title: 'Görev $id',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.tasks);
    source = TaskLocalSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('TaskLocalSource', () {
    test('kaydedilen görev geri okunur', () async {
      await source.save(makeTask('t1'));

      final result = source.getAll();

      expect(result.length, 1);
      expect(result.first.title, 'Görev t1');
    });

    test('aynı id ile kaydetmek günceller', () async {
      final task = makeTask('t1');
      await source.save(task);
      await source.save(task.copyWith(isCompleted: true));

      final result = source.getAll();

      expect(result.length, 1);
      expect(result.first.isCompleted, true);
    });

    test('silinen görev listeden kalkar', () async {
      await source.save(makeTask('t1'));
      await source.delete('t1');

      expect(source.getAll(), isEmpty);
    });

    test('getBySubjectId yalnızca o dersin görevlerini getirir', () async {
      await source.save(makeTask('t1', subjectId: 'mat'));
      await source.save(makeTask('t2', subjectId: 'fizik'));
      await source.save(makeTask('t3', subjectId: 'mat'));

      final result = source.getBySubjectId('mat');

      expect(result.length, 2);
      expect(result.every((t) => t.subjectId == 'mat'), true);
    });
  });
}
