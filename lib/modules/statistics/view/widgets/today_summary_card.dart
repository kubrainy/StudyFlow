import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/goal_ring.dart';
import '../../models/statistics_summary.dart';

/// Sayfanın üstündeki kart: bugünün hedef halkası, haftalık toplam ve biten görevler.
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.summary,
    required this.goalMinutes,
    this.onTasksTap,
  });

  final StatisticsSummary summary;

  /// Ayarlar'daki günlük hedef; istatistik sonucu olmadığı için modelde değil.
  final int goalMinutes;

  /// "N görev bitti" rozetine basılınca çağrılır; null ise rozet tıklanmaz.
  final VoidCallback? onTasksTap;

  @override
  Widget build(BuildContext context) {
    final progress = (summary.todayMinutes / goalMinutes).clamp(0.0, 1.0);

    return AppCard(
      child: Row(
        children: [
          GoalRing(
            key: const Key('today-ring'),
            progress: progress,
            value: '${summary.todayMinutes}',
            caption: 'dk bugün',
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu hafta',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatMinutes(summary.weekMinutes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DoneBadge(
                  label: '${summary.weekCompletedTasks} görev bitti',
                  onTap: onTasksTap,
                ),
                Text(
                  'Günlük hedef $goalMinutes dk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AppChip(done) görünümünde ama dar alanda küçülüp "..." ile kesilebilen etiket.
class _DoneBadge extends StatelessWidget {
  const _DoneBadge({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  /// Görünen rozet 28dp; basma alanı dokunma için 44dp'ye çıkarılır.
  static const _tapHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _tapHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.doneFill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.doneBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check,
                  size: AppIconSize.chip,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: AppIconSize.chip,
                    color: AppColors.secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
