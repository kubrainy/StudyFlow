import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/day_label.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../models/task.dart';

/// "Bugünün Görevleri": başlık, görev sayısı, "Tümü" bağlantısı ve ilk
/// [maxVisible] görev satırı.
class TodayTasksSection extends StatelessWidget {
  const TodayTasksSection({
    super.key,
    required this.tasks,
    required this.subjectNames,
    required this.now,
    required this.onToggle,
    required this.onSeeAll,
  });

  final List<Task> tasks;

  /// Ders id'sinden ders adına.
  final Map<String, String> subjectNames;
  final DateTime now;
  final ValueChanged<Task> onToggle;
  final VoidCallback onSeeAll;

  static const maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    final visible = tasks.take(maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Başlık ve sayı rozeti soldaki boşluğu paylaşır; "Tümü" sağda kalır.
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Bugünün Görevleri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(label: '${tasks.length}'),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              key: const Key('tasks-see-all'),
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  tasks.isEmpty ? 'Görev ekle' : 'Tümü (${tasks.length})',
                  maxLines: 1,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          AppCard(
            child: Text(
              'Bekleyen görev yok. Yeni görev eklemek için "Görev ekle"ye dokun.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Column(
            spacing: AppSpacing.sm,
            children: [
              for (final task in visible)
                _TaskRow(
                  task: task,
                  subjectName: subjectNames[task.subjectId],
                  now: now,
                  onToggle: () => onToggle(task),
                  onTap: onSeeAll,
                ),
            ],
          ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.subjectName,
    required this.now,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final String? subjectName;
  final DateTime now;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final dueDate = task.dueDate;
    final overdue =
        dueDate != null && !done && dueDate.isBefore(DateUtils.dateOnly(now));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppShadows.level1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Checkbox(checked: done, onTap: onToggle),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: done
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PriorityBadge(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (subjectName != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.chipFill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subjectName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (dueDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              dayLabel(dueDate, now) == 'Bugün'
                                  ? Icons.schedule
                                  : Icons.calendar_today_outlined,
                              size: 14,
                              color: overdue
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dayLabel(dueDate, now),
                              style: AppTextStyles.bodySm.copyWith(
                                color: overdue
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('dashboard-task-checkbox'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: checked ? AppColors.subjectGreen : AppColors.chipFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: checked
              ? const Icon(Icons.check, size: 18, color: AppColors.onPrimary)
              : null,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, fill, color) = switch (priority) {
      TaskPriority.high => (
        'Yüksek',
        const Color(0xFFFEE2E2),
        AppColors.subjectRed,
      ),
      TaskPriority.medium => (
        'Orta',
        AppColors.mediumFill,
        AppColors.mediumText,
      ),
      TaskPriority.low => ('Düşük', AppColors.mintSoft, AppColors.subjectGreen),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
