import 'package:flutter/material.dart';

import '../../core/widgets/modal_blur.dart';
import '../../models/subject.dart';
import '../../models/task.dart';
import 'task_form.dart';
import 'tasks_controller.dart';

/// Ekleme (task == null) ve düzenleme formunu alt panelde açar.
/// [initialSubjectId] yeni görevde dersi önceden seçili getirir.
Future<void> showTaskForm(
  BuildContext context,
  TasksController controller,
  List<Subject> subjects, {
  Task? task,
  String? initialSubjectId,
}) {
  return showBlurredSheet<void>(
    context: context,
    builder: (_) => TaskForm(
      task: task,
      initialSubjectId: initialSubjectId,
      subjects: subjects,
      onSubmit: (data) => task == null
          ? controller.add(
              data.title,
              description: data.description,
              subjectId: data.subjectId,
              priority: data.priority,
              dueDate: data.dueDate,
            )
          : controller.update(
              task,
              title: data.title,
              description: data.description,
              clearDescription: data.description == null,
              subjectId: data.subjectId,
              clearSubjectId: data.subjectId == null,
              priority: data.priority,
              dueDate: data.dueDate,
              clearDueDate: data.dueDate == null,
            ),
    ),
  );
}

/// Silme onay diyaloğu; "Sil" denirse true döner.
Future<bool> confirmTaskDelete(BuildContext context, Task task) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => ModalBlur(
      child: AlertDialog(
        title: const Text('Görevi sil'),
        content: Text(
          '"${task.title}" görevi silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}
