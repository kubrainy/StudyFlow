import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/profile_stats.dart';

/// Ayarlar'ın üstündeki profil kartı: baş harf avatarı, ad (kalemle
/// düzenlenir) ve üç rakam (toplam çalışma, biten görev, ders).
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.stats,
    this.onEditTap,
  });

  final String name;
  final ProfileStats stats;

  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final hasName = name.trim().isNotEmpty;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(name: name, radius: 30),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasName ? name : 'Adını ekle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hasName
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'İsmi düzenle',
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textSecondary,
                onPressed: onEditTap,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubdued,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: formatHm(stats.totalStudyMinutes),
                    caption: 'toplam çalışma',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: '${stats.completedTaskCount}',
                    caption: 'biten görev',
                  ),
                ),
                Expanded(
                  child: _Stat(value: '${stats.subjectCount}', caption: 'ders'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // "128s 40dk" dar ekranda sığmazsa küçülür.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.statMono.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
