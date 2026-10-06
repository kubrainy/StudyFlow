import '../../../models/task.dart';

class TaskFormData {
  const TaskFormData({
    required this.title,
    this.description,
    this.subjectId,
    required this.priority,
    this.dueDate,
  });

  final String title;
  final String? description;
  final String? subjectId;
  final TaskPriority priority;
  final DateTime? dueDate;
}
