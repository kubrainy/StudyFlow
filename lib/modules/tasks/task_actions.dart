import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    builder: (sheetContext) => TaskForm(
      task: task,
      onDelete: task == null
          ? null
          : () async {
              if (!await confirmTaskDelete(sheetContext, task)) return;
              await controller.delete(task.id);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
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

/// Sola kaydırınca açılan erteleme seçenekleri.
Future<void> showPostponeSheet(
  BuildContext context,
  TasksController controller,
  Task task,
) {
  final today = DateUtils.dateOnly(DateTime.now());

  return showBlurredSheet<void>(
    context: context,
    builder: (sheetContext) {
      Future<void> pick(DateTime date) async {
        await controller.postpone(task, date);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      }

      Widget option(String label, DateTime date) => ListTile(
        title: Text(label),
        trailing: Text(DateFormat('d.MM').format(date)),
        onTap: () => pick(date),
      );

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Ertele')),
            option('Yarın', today.add(const Duration(days: 1))),
            option('3 gün sonra', today.add(const Duration(days: 3))),
            option('Haftaya', today.add(const Duration(days: 7))),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Tarih seç'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: task.dueDate ?? today,
                  firstDate: DateTime(today.year - 1),
                  lastDate: DateTime(today.year + 5),
                );
                if (picked != null) await pick(picked);
              },
            ),
          ],
        ),
      );
    },
  );
}
