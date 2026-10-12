import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/range_stats.dart';

/// 90 dk → "1.5 Saat".
String hoursText(int minutes) => '${(minutes / 60).toStringAsFixed(1)} Saat';

/// Seçili aralığın sütun grafiği: sütuna dokununca o sütun seçilir ve altta
/// "Seçili gün: Perşembe (6.1 Saat)" yazar. Hedef varsa kesikli çizgi çizilir.
class RangeBarChart extends StatefulWidget {
  const RangeBarChart({super.key, required this.stats});

  final RangeStats stats;

  @override
  State<RangeBarChart> createState() => _RangeBarChartState();
}

class _RangeBarChartState extends State<RangeBarChart> {
  /// Kullanıcının dokunduğu sütun; aralık değişince başa (varsayılan) döner.
  int? _picked;

  @override
  void didUpdateWidget(RangeBarChart old) {
    super.didUpdateWidget(old);
    if (old.stats.chartTitle != widget.stats.chartTitle ||
        old.stats.bars.length != widget.stats.bars.length) {
      _picked = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final bars = stats.bars;
    final selected = (_picked ?? stats.selectedIndex).clamp(0, bars.length - 1);
    final goal = stats.goalLineMinutes;
    final maxBar = bars.fold(0, (m, b) => math.max(m, b.minutes));
    final top = math.max(math.max(maxBar * 1.2, (goal ?? 0) * 1.25), 60.0);
    final manyBars = bars.length > 12;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stats.chartTitle,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            stats.chartSubtitle,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: top,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length || !bars[i].showLabel) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            bars[i].label,
                            maxLines: 1,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11,
                              color: i == selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: i == selected
                                  ? FontWeight.w700
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (goal != null)
                      HorizontalLine(
                        y: goal.toDouble(),
                        color: AppColors.warning.withValues(alpha: 0.7),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(bottom: 2),
                          style: AppTextStyles.statMono.copyWith(
                            fontSize: 10,
                            color: AppColors.mediumText,
                          ),
                          labelResolver: (_) => '${formatHm(goal)} Hedef',
                        ),
                      ),
                  ],
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    getTooltipItem: (_, _, _, _) => null,
                  ),
                  touchCallback: (event, response) {
                    final index = response?.spot?.touchedBarGroupIndex;
                    if (event is FlTapUpEvent && index != null) {
                      setState(() => _picked = index);
                    }
                  },
                ),
                barGroups: [
                  for (var i = 0; i < bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i].minutes.toDouble(),
                          width: manyBars ? 6 : 28,
                          color: i == selected
                              ? AppColors.primary
                              : const Color(0xFFC7C8FB),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(manyBars ? 3 : 8),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            key: const Key('chart-selection'),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubdued,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${stats.selectionPrefix}: ',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text:
                        '${bars[selected].caption} '
                        '(${hoursText(bars[selected].minutes)})',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.statMono.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
