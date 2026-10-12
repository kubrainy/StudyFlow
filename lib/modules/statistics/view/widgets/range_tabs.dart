import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/range_stats.dart';

/// Günlük / Haftalık / Aylık / Tüm Zamanlar şeridi.
class RangeTabs extends StatelessWidget {
  const RangeTabs({super.key, required this.selected, required this.onChanged});

  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chipFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (final range in StatsRange.values)
            Expanded(
              child: GestureDetector(
                key: Key('range-${range.name}'),
                onTap: () => onChanged(range),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: range == selected
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: range == selected ? AppShadows.level1 : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      range.label,
                      maxLines: 1,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: range == selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
