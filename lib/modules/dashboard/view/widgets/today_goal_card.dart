import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/goal_ring.dart';
import '../../models/dashboard_summary.dart';

/// Bugünün hedef halkası, hedefe kalan süre ve Pomodoro'ya giden düğme.
/// Halka ve yazılar yan yana durur; kart çok daralırsa halka üstte, yazılar
/// altında dizilir. Düğme her zaman altta ve tam genişliktedir.
class TodayGoalCard extends StatelessWidget {
  const TodayGoalCard({super.key, required this.summary, this.onStartTap});

  final DashboardSummary summary;

  /// "Pomodoro başlat" düğmesine basılınca çağrılır.
  final VoidCallback? onStartTap;

  /// Kartın iç genişliği bundan darsa yazılar halkanın altına iner.
  static const _sideBySideMinWidth = 250.0;

  @override
  Widget build(BuildContext context) {
    final ring = GoalRing(
      key: const Key('goal-ring'),
      progress: summary.progress,
      value: '${summary.todayMinutes}',
      caption: 'dk bugün',
    );

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= _sideBySideMinWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sideBySide)
                Row(
                  children: [
                    ring,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: _Texts(summary: summary)),
                  ],
                )
              else ...[
                Center(child: ring),
                const SizedBox(height: AppSpacing.md),
                _Texts(summary: summary, centered: true),
              ],
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Pomodoro başlat',
                onPressed: onStartTap,
                compact: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts({required this.summary, this.centered = false});

  final DashboardSummary summary;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final remaining = summary.remainingMinutes;
    final align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Günlük hedef ${summary.goalMinutes} dk',
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          remaining == 0
              ? 'Hedefe ulaştın'
              : '${formatMinutes(remaining)} kaldı',
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMd.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
