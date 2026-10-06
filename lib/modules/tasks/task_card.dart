import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.subjectName,
    this.onToggle,
    this.onTap,
    this.onDelete,
  });

  final Task task;
  final String? subjectName;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subject = subjectName;
    final dueDate = task.dueDate;
    final isOverdue =
        dueDate != null &&
        !task.isCompleted &&
        dueDate.isBefore(DateUtils.dateOnly(DateTime.now()));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TaskCheckbox(checked: task.isCompleted, onTap: onToggle),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (subject != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subject,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _priorityChip(task.priority),
                      if (dueDate != null) _dueDate(dueDate, isOverdue),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(TaskPriority priority) => switch (priority) {
    TaskPriority.high => const AppChip(label: 'Yüksek', type: AppChipType.high),
    TaskPriority.medium => const AppChip(
      label: 'Orta',
      type: AppChipType.focus,
    ),
    TaskPriority.low => const AppChip(
      label: 'Düşük',
      type: AppChipType.neutral,
    ),
  };

  Widget _dueDate(DateTime dueDate, bool isOverdue) {
    final color = isOverdue ? AppColors.danger : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: AppIconSize.chip,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          DateFormat('d.MM.yyyy').format(dueDate),
          style: AppTextStyles.bodyMd.copyWith(color: color),
        ),
      ],
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.checked, this.onTap});

  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('task-checkbox'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: checked ? AppColors.secondary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.checkbox),
            border: Border.all(
              color: checked ? AppColors.secondary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: checked
              ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
              : null,
        ),
      ),
    );
  }
}
