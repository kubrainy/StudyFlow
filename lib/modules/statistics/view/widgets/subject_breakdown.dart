import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/subject_share.dart';

class SubjectBreakdown extends StatelessWidget {
  const SubjectBreakdown({
    super.key,
    required this.shares,
    this.scrollable = false,
  });

  final List<SubjectShare> shares;

  final bool scrollable;

  Color _colorOf(int index) => shares[index].subjectId == null
      ? AppColors.textDisabled
      : AppColors.subjectPalette[index % AppColors.subjectPalette.length];

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) {
      return AppCard(
        child: Text(
          'Henüz ders bazlı çalışma yok.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final total = shares.fold(0, (sum, s) => sum + s.minutes);
    final legend = Column(
      spacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < shares.length; i++)
          _LegendRow(
            share: shares[i],
            color: _colorOf(i),
            percent: (shares[i].minutes * 100 / total).round(),
          ),
      ],
    );

    return AppCard(
      child: Column(
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              key: const Key('breakdown-strip'),
              height: 14,
              child: Row(
                spacing: 2,
                // Çocuksuz ColoredBox yüksekliği 0 olur; stretch ile şerit
                // boyunu doldurur.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < shares.length; i++)
                    Expanded(
                      flex: shares[i].minutes,
                      child: ColoredBox(color: _colorOf(i)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (scrollable)
            Expanded(child: SingleChildScrollView(child: legend))
          else
            legend,
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.share,
    required this.color,
    required this.percent,
  });

  final SubjectShare share;
  final Color color;
  final int percent;

  @override
  Widget build(BuildContext context) {
    // Dar kartta (iki kolonlu tablet düzeni) büyük yazıyla satır sığmaz; ders
    // adı kısaltılabilir ama süre ve yüzde kısaltılamaz. Bu yüzden satırın
    // yazısı en çok 1.3 kat büyür.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: _row(),
    );
  }

  Widget _row() {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            share.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatMinutes(share.minutes),
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '%$percent',
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
