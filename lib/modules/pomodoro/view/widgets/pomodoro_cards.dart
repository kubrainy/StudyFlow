import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_widgets.dart';

/// "Bildirimler" kartı: oturum bitince bildirim gönderme ayarını açıp kapatır
/// (Ayarlar'daki anahtarla aynı ayar).
class PomodoroReminderCard extends StatelessWidget {
  const PomodoroReminderCard({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.subjectGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bitiş Bildirimi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Oturum bitince haber ver',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.subjectGreen
                  : null,
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.onPrimary
                  : null,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.transparent
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// "5 Oturum  HEDEF: 240 dk" kartı: bugünkü oturum sayısı ve toplam süre.
/// Dokununca Analiz sekmesi açılır.
class PomodoroDayCard extends StatelessWidget {
  const PomodoroDayCard({
    super.key,
    required this.sessionCount,
    required this.todayMinutes,
    required this.goalMinutes,
    required this.onTap,
  });

  final int sessionCount;
  final int todayMinutes;
  final int goalMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.chipFill.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.peachSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.subjectBrown,
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
                        '$sessionCount Oturum',
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      AppBadge(
                        label: 'HEDEF: $goalMinutes dk',
                        fill: AppColors.mint,
                        color: AppColors.mintText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bugün: $todayMinutes dk odaklanma tamamlandı',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
