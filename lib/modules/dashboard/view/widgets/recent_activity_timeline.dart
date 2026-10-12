import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/subject_style.dart';
import '../../../../core/utils/day_label.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/activity_day.dart';
import '../../models/recent_activity.dart';

/// "Son Aktiviteler": son çalışma oturumları, ders renginde ikon kutusuyla.
/// [now] "Bugün" / "Dün" etiketleri için.
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({
    super.key,
    required this.days,
    required this.now,
    this.onTap,
  });

  final List<ActivityDay> days;
  final DateTime now;

  /// Satıra dokununca; ders id'si serbest çalışmada null.
  final ValueChanged<String?>? onTap;

  static const maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    final activities = [for (final day in days) ...day.activities]
        .take(maxVisible)
        .toList();

    // "Bugün & Dün": gösterilen satırların gün etiketleri, tekrarsız.
    final labels = <String>[];
    for (final activity in activities) {
      final label = dayLabel(activity.startedAt, now);
      if (!labels.contains(label)) labels.add(label);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Son Aktiviteler',
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (labels.isNotEmpty)
              Text(
                labels.take(2).join(' & '),
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activities.isEmpty)
          AppCard(
            child: Text(
              'Henüz çalışma yok. Pomodoro ile ilk oturumunu başlat.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Column(
            spacing: AppSpacing.sm,
            children: [
              for (final activity in activities)
                _ActivityRow(
                  activity: activity,
                  now: now,
                  onTap: onTap == null
                      ? null
                      : () => onTap!(activity.subjectId),
                ),
            ],
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.now,
    required this.onTap,
  });

  final RecentActivity activity;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = SubjectStyle.of(activity.subjectIndex);
    final time = DateFormat('HH:mm');
    final end = activity.startedAt.add(Duration(minutes: activity.minutes));

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
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: const Key('timeline-dot'),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.color),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatHm(activity.minutes)} (1 Pomodoro) • '
                    '${dayLabel(activity.startedAt, now)} '
                    '${time.format(activity.startedAt)} - ${time.format(end)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.statMono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: style.color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
