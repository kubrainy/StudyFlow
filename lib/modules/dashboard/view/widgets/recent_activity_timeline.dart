import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/day_label.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/utils/upper_tr.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/activity_day.dart';
import '../../models/recent_activity.dart';

/// Son çalışmalar: güne göre gruplu, solunda dikey çizgi ve ders renginde
/// noktalar olan zaman çizgisi. [now] gün başlıklarındaki "Bugün" ve "Dün" için.
class RecentActivityTimeline extends StatelessWidget {
  const RecentActivityTimeline({
    super.key,
    required this.days,
    required this.now,
  });

  final List<ActivityDay> days;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return AppCard(
        child: Text(
          'Henüz çalışma yok. Pomodoro ile ilk oturumunu başlat.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [for (final day in days) _DayGroup(day: day, now: now)],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.now});

  final ActivityDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final activities = day.activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          upperTr(dayLabel(day.date, now)),
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < activities.length; i++)
          _ActivityRow(
            activity: activities[i],
            isFirst: i == 0,
            isLast: i == activities.length - 1,
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.isFirst,
    required this.isLast,
  });

  final RecentActivity activity;
  final bool isFirst;
  final bool isLast;

  Color get _color {
    final index = activity.subjectIndex;
    if (index == null) return AppColors.textDisabled;
    return AppColors.subjectPalette[index % AppColors.subjectPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(color: _color, isFirst: isFirst, isLast: isLast),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(activity.startedAt),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: formatMinutes(activity.minutes),
                    type: AppChipType.duration,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satırın solundaki dikey çizgi ve ders renginde nokta. Günün ilk satırında
/// çizgi noktadan başlar, son satırda noktada biter.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final bool isFirst;
  final bool isLast;

  static const _line = VerticalDivider(
    width: 2,
    thickness: 2,
    color: AppColors.border,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      child: Column(
        children: [
          Expanded(child: isFirst ? const SizedBox() : _line),
          Container(
            key: const Key('timeline-dot'),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
          Expanded(child: isLast ? const SizedBox() : _line),
        ],
      ),
    );
  }
}
