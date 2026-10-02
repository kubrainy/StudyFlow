import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';

/// Hive açmadan, bellekte çalışan sahte ders deposu (remote testleri için).
class InMemorySubjectLocalSource extends SubjectLocalSource {
  final Map<String, Subject> items = {};

  @override
  List<Subject> getAll() => items.values.toList();

  @override
  Future<void> save(Subject subject) async => items[subject.id] = subject;

  @override
  Future<void> delete(String id) async => items.remove(id);
}

/// Hive açmadan, bellekte çalışan sahte görev deposu (remote testleri için).
class InMemoryTaskLocalSource extends TaskLocalSource {
  final Map<String, Task> items = {};

  @override
  List<Task> getAll() => items.values.toList();

  @override
  Future<void> save(Task task) async => items[task.id] = task;

  @override
  Future<void> delete(String id) async => items.remove(id);
}
