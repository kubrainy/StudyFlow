import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/utils/weekday_short.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/daily_minutes.dart';

/// Dokunulan günün kutusundaki yazı: "Çar · 1 sa 3 dk".
String dayTooltipLabel(DailyMinutes day) =>
    '${weekdayShort(day.date)} · ${formatMinutes(day.minutes)}';

/// Haftanın günlerini (Pazartesi-Pazar) yumuşak (kübik) bir çizgi olarak
/// gösterir; çizgi bugünde biter, gelmemiş günler boş kalır. Parmakla dokunup
/// sürüklenince o günün değeri kutuda görünür. Bugün dolu bir noktayla vurgulanır.
class WeeklyLineChart extends StatelessWidget {
  const WeeklyLineChart({
    super.key,
    required this.data,
    this.todayIndex,
    this.height = 180,
  });

  final List<DailyMinutes> data;

  /// Bugünün [data] içindeki sırası; null ise son gün bugündür.
  final int? todayIndex;

  /// Sabit yükseklik; null verilirse grafik bulunduğu alanı doldurur.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = data.fold(0, (max, d) => math.max(max, d.minutes));
    final today = todayIndex ?? data.length - 1;

    final line = LineChartBarData(
      spots: [
        for (var i = 0; i <= today; i++)
          FlSpot(i.toDouble(), data[i].minutes.toDouble()),
      ],
      isCurved: true,
      preventCurveOverShooting: true,
      color: AppColors.primary,
      barWidth: 3,
      dotData: FlDotData(
        checkToShowDot: (spot, _) => spot.x == today,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 5,
          color: AppColors.primary,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
      ),
    );

    return AppCard(
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: 0,
            // En yüksek nokta tavana yapışmasın diye üstte pay bırakılır.
            maxY: maxMinutes == 0 ? 60 : maxMinutes * 1.25,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.canvas, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    final isToday = index == today;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        weekdayShort(data[index].date),
                        style: AppTextStyles.bodySm.copyWith(
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isToday ? FontWeight.w700 : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Parmağı grafiğin üzerinde basılı tutup sürükleyince o günün
            // değeri koyu bir kutuda görünür; parmak kalkınca kaybolur.
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      dayTooltipLabel(data[spot.spotIndex]),
                      AppTextStyles.bodySm.copyWith(color: AppColors.surface),
                    ),
                ],
              ),
            ),
            lineBarsData: [line],
          ),
        ),
      ),
    );
  }
}
