import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/subject_style.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../models/subject.dart';

/// Ders kartı (Figma): simge kutusu, ad, açıklama, "Toplam süre" ve "Görevler"
/// kutuları, görev ilerleme çubuğu ve "Hemen Çalış" düğmesi.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    this.index = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.nextTaskTitle,
    this.onTap,
    this.onLongPress,
    this.onStudy,
    this.onEdit,
    this.onDelete,
  });

  final Subject subject;

  /// Ders listesindeki sıra (simge ve renk seçimi için).
  final int index;
  final int totalTasks;
  final int completedTasks;
  final String? nextTaskTitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStudy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final style = SubjectStyle.of(index);
    final description = subject.description?.trim();
    final open = totalTasks - completedTasks;
    final fraction = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final percent = (fraction * 100).round();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: style.tint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.statMono.copyWith(
                              fontSize: 11,
                              color: style.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _Menu(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    icon: Icons.schedule,
                    caption: 'TOPLAM SÜRE',
                    value: formatHm(subject.totalStudyMinutes),
                    iconColor: style.color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoBox(
                    icon: Icons.checklist_rtl,
                    caption: 'GÖREVLER',
                    value: totalTasks == 0
                        ? 'Görev yok'
                        : open == 0
                        ? 'Hepsi bitti'
                        : '$open Görev bekliyor',
                    iconColor: style.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Görev İlerlemesi (%$percent)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$completedTasks / $totalTasks',
                  style: AppTextStyles.statMono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: style.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                key: const Key('subject-progress'),
                value: fraction,
                minHeight: 8,
                backgroundColor: AppColors.surfaceSubdued,
                valueColor: AlwaysStoppedAnimation(style.color),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _Status(
                    total: totalTasks,
                    open: open,
                    next: nextTaskTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  key: const Key('subject-study'),
                  onTap: onStudy,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_outlined,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hemen Çalış',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onDelete == null) return const SizedBox.shrink();
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<int>(
        tooltip: 'Daha fazla',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
        onSelected: (value) => value == 0 ? onEdit?.call() : onDelete?.call(),
        itemBuilder: (_) => [
          if (onEdit != null)
            const PopupMenuItem(value: 0, child: Text('Düzenle')),
          if (onDelete != null)
            const PopupMenuItem(value: 1, child: Text('Sil')),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.caption,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String caption;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubdued,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelCaps.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statMono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartın altındaki durum satırı: sıradaki görev, hepsi bittiyse yeşil tik.
class _Status extends StatelessWidget {
  const _Status({required this.total, required this.open, required this.next});

  final int total;
  final int open;
  final String? next;

  @override
  Widget build(BuildContext context) {
    if (total > 0 && open == 0) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.subjectGreen,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Tüm görevler tamam',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.subjectGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        if (next != null) ...[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            next ?? 'Henüz görev yok',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
