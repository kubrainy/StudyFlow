import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dersin kartta ve listelerde görünen simgesi ve renkleri. Dersin kendi
/// simge/renk alanı yok; ders listesindeki sırasına göre döngüyle seçilir
/// (Figma'daki dört ders: telefon, ağaç, veritabanı, beyin).
class SubjectStyle {
  const SubjectStyle(this.icon, this.tint, this.color);

  final IconData icon;

  /// İkon kutusunun açık zemini.
  final Color tint;

  /// İkon, ilerleme çubuğu ve vurgu yazıları.
  final Color color;

  static const _all = [
    SubjectStyle(
      Icons.smartphone_outlined,
      AppColors.chipFill,
      AppColors.primary,
    ),
    SubjectStyle(
      Icons.account_tree_outlined,
      AppColors.mintSoft,
      AppColors.subjectGreen,
    ),
    SubjectStyle(Icons.storage_outlined, AppColors.chipFill, AppColors.primary),
    SubjectStyle(
      Icons.psychology_outlined,
      AppColors.peachSoft,
      AppColors.subjectBrown,
    ),
    SubjectStyle(Icons.school_outlined, AppColors.chipFill, AppColors.primary),
    SubjectStyle(
      Icons.science_outlined,
      AppColors.mintSoft,
      AppColors.subjectGreen,
    ),
    SubjectStyle(
      Icons.calculate_outlined,
      AppColors.peachSoft,
      AppColors.subjectBrown,
    ),
  ];

  /// [index] ders listesindeki sıradır; null (serbest çalışma, silinmiş ders)
  /// için nötr bir stil döner.
  static SubjectStyle of(int? index) => index == null
      ? const SubjectStyle(
          Icons.timer_outlined,
          AppColors.surfaceSubdued,
          AppColors.textSecondary,
        )
      : _all[index % _all.length];
}
