import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/models/subject.dart';

void main() {
  late Directory tempDir;
  late SubjectLocalSource source;

  final subject = Subject(
    id: 'abc-123',
    name: 'Matematik',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 90,
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.subjects);
    source = SubjectLocalSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('SubjectLocalSource', () {
    test('başlangıçta liste boş', () {
      expect(source.getAll(), isEmpty);
    });

    test('kaydedilen ders geri okunur', () async {
      await source.save(subject);

      final result = source.getAll();

      expect(result.length, 1);
      expect(result.first.name, 'Matematik');
    });

    test('aynı id ile kaydetmek günceller, ikinci kayıt açmaz', () async {
      await source.save(subject);
      await source.save(subject.copyWith(name: 'Fizik'));

      final result = source.getAll();

      expect(result.length, 1);
      expect(result.first.name, 'Fizik');
    });

    test('silinen ders listeden kalkar', () async {
      await source.save(subject);
      await source.delete('abc-123');

      expect(source.getAll(), isEmpty);
    });
  });
}
