import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/subject.dart';
import '../../models/task.dart';

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

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    this.task,
    this.initialSubjectId,
    required this.subjects,
    required this.onSubmit,
  });

  final Task? task;
  final String? initialSubjectId;
  final List<Subject> subjects;
  final Future<void> Function(TaskFormData data) onSubmit;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _subjectId;
  late TaskPriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title);
    _descriptionController = TextEditingController(text: task?.description);
    final wanted = task?.subjectId ?? widget.initialSubjectId;
    final hasSubject = widget.subjects.any((s) => s.id == wanted);
    _subjectId = hasSubject ? wanted : null;
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    await widget.onSubmit(
      TaskFormData(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        subjectId: _subjectId,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final dueDate = _dueDate;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEdit ? 'Görevi düzenle' : 'Görev ekle',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Görev başlığı'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Açıklama (opsiyonel)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            initialValue: _subjectId,
            decoration: const InputDecoration(labelText: 'Ders (opsiyonel)'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Ders yok'),
              ),
              for (final s in widget.subjects)
                DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
            ],
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Öncelik', style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.xs),
          AppSegmentedControl(
            options: const ['Düşük', 'Orta', 'Yüksek'],
            selectedIndex: _priority.index,
            onChanged: (i) =>
                setState(() => _priority = TaskPriority.values[i]),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: dueDate == null
                      ? 'Son tarih seç'
                      : DateFormat('d.MM.yyyy').format(dueDate),
                  onPressed: _pickDate,
                ),
              ),
              if (dueDate != null)
                IconButton(
                  tooltip: 'Tarihi kaldır',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _dueDate = null),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(label: 'Kaydet', onPressed: _canSave ? _save : null),
        ],
      ),
    );
  }
}
