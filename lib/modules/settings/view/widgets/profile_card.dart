import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';

/// Ayarlar'ın en üstündeki profil kartı: baş harf avatarı, isim, düzenle
/// düğmesi ve üç özet rakam. İsim boşsa avatarda simge, isim yerine
/// "Adını ekle" görünür.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.totalStudyMinutes,
    required this.completedTaskCount,
    required this.subjectCount,
    this.onEditTap,
  });

  final String name;
  final int totalStudyMinutes;
  final int completedTaskCount;
  final int subjectCount;

  /// İsim satırındaki kalem düğmesine basılınca çağrılır.
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
                  value: formatMinutes(totalStudyMinutes),
                  caption: 'toplam çalışma',
                ),
              ),
              Expanded(
                child: _Stat(
                  value: '$completedTaskCount',
                  caption: 'biten görev',
                ),
              ),
              Expanded(
                child: _Stat(value: '$subjectCount', caption: 'ders'),
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
    final first = trimmed.isEmpty ? '' : trimmed.characters.first;
    // Dart "i"yi "I" yapar; Türkçede noktalı İ olmalı (ör. "irem" → İ).
    final initial = first == 'i' ? 'İ' : first.toUpperCase();

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
