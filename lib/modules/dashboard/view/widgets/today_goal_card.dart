import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/goal_ring.dart';
import '../../models/dashboard_summary.dart';

/// "Günlük İlerleme" kartı: bugünün hedef halkası, yüzde rozeti ve üç özet
/// satırı (seri, görevler, Pomodoro). Kart çok daralırsa halka üstte, satırlar
/// altında dizilir.
class TodayGoalCard extends StatelessWidget {
  const TodayGoalCard({super.key, required this.summary});

  final DashboardSummary summary;

  /// Kartın iç genişliği bundan darsa satırlar halkanın altına iner.
  static const _sideBySideMinWidth = 290.0;

  @override
  Widget build(BuildContext context) {
    final percent = (summary.todayMinutes * 100 / summary.goalMinutes)
        .floor()
        .clamp(0, 100);

    final ring = GoalRing(
      key: const Key('goal-ring'),
      progress: summary.progress,
      size: 108,
      value: formatHm(summary.todayMinutes),
      caption: '/ ${formatHm(summary.goalMinutes)}',
      valueStyle: AppTextStyles.titleMd.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      captionStyle: AppTextStyles.statMono.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );

    final rows = Column(
      spacing: AppSpacing.xs,
      children: [
        _StatRow(
          icon: Icons.local_fire_department_outlined,
          label: 'Seri Durumu',
          value: '${summary.streakDays} Gün',
          color: AppColors.subjectBrown,
        ),
        _StatRow(
          icon: Icons.check_circle_outline,
          label: 'Görevler',
          value: '${summary.todayCompletedTasks} / ${summary.totalTaskCount}',
          color: AppColors.subjectGreen,
        ),
        _StatRow(
          icon: Icons.timer_outlined,
          label: 'Pomodoro',
          value: '${summary.todaySessionCount} Oturum',
          color: AppColors.primary,
        ),
      ],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Günlük İlerleme',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppBadge(label: '%$percent Tamamlandı'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _sideBySideMinWidth) {
                return Row(
                  children: [
                    ring,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: rows),
                  ],
                );
              }
              return Column(
                children: [
                  ring,
                  const SizedBox(height: AppSpacing.md),
                  rows,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubdued,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            maxLines: 1,
            style: AppTextStyles.statMono.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
