import 'package:uuid/uuid.dart';

import '../../models/task.dart';
import '../local/task_local_source.dart';
import '../remote/task_remote_source.dart';

class TaskRepository {
  final TaskLocalSource _local;
  final TaskRemoteSource _remote;

  TaskRepository(this._local, this._remote);

  List<Task> getAll() => _local.getAll();

  List<Task> getBySubjectId(String subjectId) =>
      _local.getBySubjectId(subjectId);

  Future<void> delete(String id) => _remote.delete(id);

  Future<Task> add(
    String title, {
    String? description,
    String? subjectId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      subjectId: subjectId,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
    return _remote.create(task);
  }

  Future<Task> update(
    Task task, {
    String? title,
    String? description,
    String? subjectId,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearSubjectId = false,
    bool clearDescription = false,
    bool clearDueDate = false,
  }) async {
    final updated = task.copyWith(
      title: title,
      description: description,
      subjectId: subjectId,
      priority: priority,
      dueDate: dueDate,
      updatedAt: DateTime.now(),
      clearSubjectId: clearSubjectId,
      clearDescription: clearDescription,
      clearDueDate: clearDueDate,
    );
    return _remote.update(updated);
  }

  Future<Task> setCompleted(Task task, bool isCompleted) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? now : null,
      clearCompletedAt: !isCompleted,
      updatedAt: now,
    );
    return _remote.update(updated);
  }

  Future<void> deleteBySubjectId(String subjectId) async {
    for (final task in _local.getBySubjectId(subjectId)) {
      await _remote.delete(task.id);
    }
  }
}
