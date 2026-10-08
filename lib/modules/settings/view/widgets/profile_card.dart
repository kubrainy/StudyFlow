import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/utils/upper_tr.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/profile_stats.dart';

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
              _Avatar(name: name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasName ? name : 'Adını ekle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
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
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: formatMinutes(stats.totalStudyMinutes),
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
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '' : upperTr(trimmed.characters.first);

    return CircleAvatar(
      key: const Key('profile-avatar'),
      radius: 24,
      backgroundColor: AppColors.focusFill,
      child: trimmed.isEmpty
          ? const Icon(Icons.person_outline, color: AppColors.primary)
          : Text(
              initial,
              style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
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
        // "12 sa 40 dk" dar ekranda sığmazsa küçülür.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.statMono.copyWith(
              color: AppColors.textPrimary,
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
