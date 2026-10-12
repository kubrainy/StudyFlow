import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../models/range_stats.dart';

/// 2x2 özet kartları: toplam çalışma, Pomodoro, görev başarısı, günlük ortalama.
class StatCards extends StatelessWidget {
  const StatCards({super.key, required this.stats, required this.goalMinutes});

  final RangeStats stats;
  final int goalMinutes;

  @override
  Widget build(BuildContext context) {
    final change = stats.changePercent;
    final label = stats.comparisonLabel;
    final sessionDiff = stats.previousSessionCount == null
        ? null
        : stats.sessionCount - stats.previousSessionCount!;

    final cards = [
      _StatCard(
        title: 'Toplam Çalışma',
        icon: Icons.donut_large,
        value: formatHm(stats.totalMinutes),
        valueColor: AppColors.primary,
        footer: change != null && label != null
            ? Row(
                children: [
                  Flexible(
                    child: AppBadge(
                      label: '${change >= 0 ? '+' : '-'}%${change.abs()}',
                      fill: change >= 0
                          ? AppColors.mint
                          : const Color(0xFFFEE2E2),
                      color: change >= 0
                          ? AppColors.mintText
                          : AppColors.subjectRed,
                      icon: change >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _Caption(label)),
                ],
              )
            : _Caption(
                label == null ? 'başlangıçtan beri' : 'karşılaştırma yok',
              ),
      ),
      _StatCard(
        title: 'Pomodoro',
        icon: Icons.local_fire_department_outlined,
        value: '${stats.sessionCount} Oturum',
        footer: sessionDiff == null
            ? const _Caption('başlangıçtan beri')
            : Row(
                children: [
                  Flexible(
                    child: AppBadge(
                      label: sessionDiff == 0
                          ? 'aynı'
                          : '${sessionDiff > 0 ? '+' : '-'}${sessionDiff.abs()} seans',
                      fill: sessionDiff >= 0
                          ? AppColors.mint
                          : const Color(0xFFFEE2E2),
                      color: sessionDiff >= 0
                          ? AppColors.mintText
                          : AppColors.subjectRed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _Caption(label ?? '')),
                ],
              ),
      ),
      _StatCard(
        title: 'Görev Başarısı',
        icon: Icons.check_circle_outline,
        value: '%${stats.taskPercent}',
        footer: _Caption(
          '${stats.completedTasks}/${stats.totalTasks} Tamamlandı',
        ),
      ),
      _StatCard(
        title: 'Günlük Ortalama',
        icon: Icons.schedule,
        value: formatHm(stats.averageMinutes),
        footer: Text(
          stats.averageMinutes >= goalMinutes
              ? 'Hedefin üstünde 🎯'
              : 'Hedefin altında',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm.copyWith(
            color: stats.averageMinutes >= goalMinutes
                ? AppColors.subjectGreen
                : AppColors.mediumText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];

    return Column(
      spacing: AppSpacing.sm,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Expanded(child: cards[0]),
              Expanded(child: cards[1]),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Expanded(child: cards[2]),
              Expanded(child: cards[3]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.footer,
    this.valueColor = AppColors.textPrimary,
  });

  final String title;
  final IconData icon;
  final String value;
  final Widget footer;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.chipFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.statMono.copyWith(
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          footer,
        ],
      ),
    );
  }
}
