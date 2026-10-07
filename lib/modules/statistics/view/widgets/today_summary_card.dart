import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_minutes.dart';
import '../../../../core/widgets/app_widgets.dart';

/// Sayfanın üstündeki kart: bugünün hedef halkası, haftalık toplam ve biten görevler.
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.todayMinutes,
    required this.goalMinutes,
    required this.weekMinutes,
    required this.completedTasks,
    this.onTasksTap,
  });

  final int todayMinutes;
  final int goalMinutes;
  final int weekMinutes;
  final int completedTasks;

  /// "N görev bitti" rozetine basılınca çağrılır; null ise rozet tıklanmaz.
  final VoidCallback? onTasksTap;

  @override
  Widget build(BuildContext context) {
    final progress = (todayMinutes / goalMinutes).clamp(0.0, 1.0);

    return AppCard(
      child: Row(
        children: [
          _TodayRing(minutes: todayMinutes, progress: progress),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu hafta',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatMinutes(weekMinutes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DoneBadge(
                  label: '$completedTasks görev bitti',
                  onTap: onTasksTap,
                ),
                Text(
                  'Günlük hedef $goalMinutes dk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AppChip(done) görünümünde ama dar alanda küçülüp "..." ile kesilebilen etiket.
class _DoneBadge extends StatelessWidget {
  const _DoneBadge({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  /// Görünen rozet 28dp; basma alanı dokunma için 44dp'ye çıkarılır.
  static const _tapHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _tapHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.doneFill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.doneBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check,
                  size: AppIconSize.chip,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: AppIconSize.chip,
                    color: AppColors.secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayRing extends StatelessWidget {
  const _TodayRing({required this.minutes, required this.progress});

  static const _size = 112.0;

  final int minutes;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('today-ring'),
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(_size),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$minutes',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'dk bugün',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = AppColors.timerTrack;
    canvas.drawCircle(rect.center, rect.width / 2, track);
    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: AppColors.timerGradient,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
