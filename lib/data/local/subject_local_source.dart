import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_boxes.dart';
import '../../models/subject.dart';

class SubjectLocalSource {
  Box get _box => Hive.box(HiveBoxes.subjects);

  List<Subject> getAll() {
    return _box.values
        .map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(Subject subject) => _box.put(subject.id, subject.toJson());

  Future<void> delete(String id) => _box.delete(id);
}
