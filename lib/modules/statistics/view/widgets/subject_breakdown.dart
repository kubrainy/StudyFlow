import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/subject_share.dart';

/// "Ders Bazlı Süre Dağılımı": halka grafik + gösterge ve her ders için
/// süre çubuğu. [periodText] "Bu haftaki" gibi başlık altı yazısıdır.
class SubjectBreakdown extends StatelessWidget {
  const SubjectBreakdown({
    super.key,
    required this.shares,
    required this.periodText,
  });

  final List<SubjectShare> shares;
  final String periodText;

  /// Gösterge ve donut en çok bu kadar dilim gösterir; fazlası "Diğer" olur.
  static const _maxLegend = 5;

  Color _colorOf(int index) => shares[index].subjectId == null
      ? AppColors.textDisabled
      : AppColors.subjectPalette[index % AppColors.subjectPalette.length];

  @override
  Widget build(BuildContext context) {
    final total = shares.fold(0, (sum, s) => sum + s.minutes);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ders Bazlı Süre Dağılımı',
                  maxLines: 2,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(label: '${shares.length} Ders'),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$periodText konu odakları',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (shares.isEmpty)
            Text(
              'Bu aralıkta ders bazlı çalışma yok.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Row(
              children: [
                _Donut(shares: shares, total: total, colorOf: _colorOf),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _legend(total)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              spacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < shares.length; i++)
                  _SubjectBar(
                    share: shares[i],
                    color: _colorOf(i),
                    fraction: shares[i].minutes / total,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(int total) {
    final shown = shares.length > _maxLegend
        ? shares.take(_maxLegend - 1).toList()
        : shares;
    final restMinutes = shares.length > _maxLegend
        ? shares.skip(_maxLegend - 1).fold(0, (s, e) => s + e.minutes)
        : 0;

    Widget row(Color color, String name, int minutes) => Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '%${(minutes * 100 / total).round()}',
          style: AppTextStyles.statMono.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );

    return Column(
      spacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < shown.length; i++)
          row(_colorOf(i), shown[i].name, shown[i].minutes),
        if (restMinutes > 0) row(AppColors.textDisabled, 'Diğer', restMinutes),
      ],
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({
    required this.shares,
    required this.total,
    required this.colorOf,
  });

  final List<SubjectShare> shares;
  final int total;
  final Color Function(int index) colorOf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('breakdown-donut'),
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < shares.length; i++)
                  PieChartSectionData(
                    value: shares[i].minutes.toDouble(),
                    color: colorOf(i),
                    radius: 14,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(total / 60).toStringAsFixed(1)}s',
                style: AppTextStyles.statMono.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'TOPLAM',
                style: AppTextStyles.labelCaps.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({
    required this.share,
    required this.color,
    required this.fraction,
  });

  final SubjectShare share;
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubdued,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  share.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatHm(share.minutes),
                style: AppTextStyles.statMono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.chipFill,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
