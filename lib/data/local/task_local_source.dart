import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_boxes.dart';
import '../../models/task.dart';

class TaskLocalSource {
  Box get _box => Hive.box(HiveBoxes.tasks);

  List<Task> getAll(){
    return _box.values
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<Task> getBySubjectId(String subjectId){
    return getAll().where((t) => t.subjectId == subjectId).toList();
  }

  Future<void> save(Task task) => _box.put(task.id, task.toJson());

  Future<void> delete(String id) => _box.delete(id);
}