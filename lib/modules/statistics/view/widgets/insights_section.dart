import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../view_model/statistics_view_model.dart';

/// "İçgörüler ve Rozetler": en verimli saat aralığı ve rozetler.
/// [periodLabel] sağ üstteki mono etiket ("Bu Hafta").
class InsightsSection extends StatelessWidget {
  const InsightsSection({
    super.key,
    required this.bestWindow,
    required this.badges,
    required this.periodLabel,
  });

  final ({int startHour, int endHour})? bestWindow;
  final List<StatsBadge> badges;
  final String periodLabel;

  String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final window = bestWindow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'İçgörüler ve Rozetler',
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              periodLabel,
              style: AppTextStyles.statMono.copyWith(
                fontSize: 12,
                color: AppColors.subjectGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.peachSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.subjectBrown,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VERİMLİLİK ANALİZİ',
                      style: AppTextStyles.labelCaps.copyWith(
                        fontSize: 10,
                        color: AppColors.subjectBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (window == null)
                      Text(
                        'Henüz yeterli veri yok. Pomodoro ile çalıştıkça en '
                        'verimli saat aralığın burada görünecek.',
                        style: AppTextStyles.bodyMd,
                      )
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'En verimli olduğun saat aralığı ',
                            ),
                            TextSpan(
                              text:
                                  '${_hour(window.startHour)} - ${_hour(window.endHour)}',
                              style: AppTextStyles.statMono.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '. Zor konuları bu zaman dilimine '
                                  'planlayarak odağını ikiye katla!',
                            ),
                          ],
                        ),
                        style: AppTextStyles.bodyMd,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
          spacing: AppSpacing.sm,
          children: [for (final badge in badges) _BadgeRow(badge: badge)],
        ),
      ],
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge});

  final StatsBadge badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: earned ? AppColors.chipFill : AppColors.surfaceSubdued,
              shape: BoxShape.circle,
            ),
            child: Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              color: earned ? AppColors.subjectBrown : AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      badge.title,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: earned
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    AppBadge(
                      label: earned ? 'KAZANILDI' : 'KİLİTLİ',
                      fill: earned ? AppColors.mint : AppColors.surfaceSubdued,
                      color: earned
                          ? AppColors.mintText
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  maxLines: 2,
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
