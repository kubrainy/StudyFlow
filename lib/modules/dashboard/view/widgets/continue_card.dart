import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../models/subject.dart';

/// "Kaldığın yerden devam et" kartı: indigo gradyanlı, dersin adı ve açıklaması,
/// "Başlat" düğmesi. Ders yoksa ders eklemeye yönlendirir.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.subject,
    required this.pomodoroMinutes,
    required this.onStart,
    required this.onAddSubject,
  });

  final Subject? subject;
  final int pomodoroMinutes;
  final VoidCallback onStart;
  final VoidCallback onAddSubject;

  @override
  Widget build(BuildContext context) {
    final subject = this.subject;
    final description = subject?.description?.trim();
    final subtitle = subject == null
        ? 'Çalışmaya başlamak için önce bir ders ekle'
        : (description != null && description.isNotEmpty
              ? description
              : 'Toplam ${formatHm(subject.totalStudyMinutes)} çalışıldı');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 18,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'KALDIĞIN YERDEN DEVAM ET',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelCaps.copyWith(
                    fontSize: 10,
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$pomodoroMinutes dk Seans',
                  maxLines: 1,
                  style: AppTextStyles.statMono.copyWith(
                    fontSize: 11,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subject?.name ?? 'Henüz ders yok',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (subject != null) ...[
                Icon(
                  Icons.headphones_outlined,
                  size: 18,
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Toplam ${formatHm(subject.totalStudyMinutes)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(width: AppSpacing.sm),
              _WhitePill(
                key: const Key('continue-start'),
                icon: subject == null ? Icons.add : Icons.play_arrow_rounded,
                label: subject == null ? 'Ders ekle' : 'Başlat',
                onTap: subject == null ? onAddSubject : onStart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
