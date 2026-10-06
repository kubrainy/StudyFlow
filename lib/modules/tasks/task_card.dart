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
    this.onLongPress,
    this.onPostpone,
  });

  final Task task;
  final String? subjectName;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Sola kaydırınca çağrılır; null ise sola kaydırma kapalıdır.
  final VoidCallback? onPostpone;

  @override
  Widget build(BuildContext context) {
    final subject = subjectName;
    final dueDate = task.dueDate;
    final isOverdue =
        dueDate != null &&
        !task.isCompleted &&
        dueDate.isBefore(DateUtils.dateOnly(DateTime.now()));

    final card = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Row(
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
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: AppIconSize.chip,
                                  color: task.isCompleted
                                      ? AppColors.textDisabled
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    subject,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: task.isCompleted
                                          ? AppColors.textDisabled
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _dueDate(dueDate, isOverdue),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(
                key: const Key('priority-stripe'),
                color: _stripeColor(),
              ),
            ),
          ],
        ),
      ),
    );

    if (onToggle == null && onPostpone == null) return card;

    // Kart yerinden silinmez: işlem yapılır, kart geri yaylanır, liste yenilenir.
    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: onToggle != null && onPostpone != null
          ? DismissDirection.horizontal
          : onToggle != null
          ? DismissDirection.startToEnd
          : DismissDirection.endToStart,
      background: const _SwipeBackground(
        color: AppColors.secondary,
        icon: Icons.check,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: AppColors.warning,
        icon: Icons.event_repeat_outlined,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle?.call();
        } else {
          onPostpone?.call();
        }
        return false;
      },
      child: card,
    );
  }

  /// Tamamlandıysa yeşil, değilse önceliğe göre kırmızı / indigo / gri.
  Color _stripeColor() {
    if (task.isCompleted) return AppColors.secondary;
    return switch (task.priority) {
      TaskPriority.high => AppColors.danger,
      TaskPriority.medium => AppColors.primary,
      TaskPriority.low => AppColors.textDisabled,
    };
  }

  Widget _dueDate(DateTime dueDate, bool isOverdue) {
    final color = task.isCompleted
        ? AppColors.textDisabled
        : isOverdue
        ? AppColors.danger
        : AppColors.textSecondary;
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
          DateFormat('d.MM').format(dueDate),
          style: AppTextStyles.bodyMd.copyWith(
            color: color,
            fontWeight: isOverdue ? FontWeight.w600 : null,
          ),
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

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(icon, color: AppColors.onPrimary),
    );
  }
}
