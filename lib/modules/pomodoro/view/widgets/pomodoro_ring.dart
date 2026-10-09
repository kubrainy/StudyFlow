import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/upper_tr.dart';
import 'pomodoro_sizes.dart';

class PomodoroRing extends StatelessWidget {
  const PomodoroRing({
    super.key,
    required this.progress,
    required this.timeText,
    required this.label,
    this.isRest = false,
    this.size = 220,
    this.footer,
  });

  final double progress;
  final String timeText;
  final String label;
  final bool isRest;
  final double size;

  final Widget? footer;

  /// İçeriğin halka çizgisinden (8 px) uzak durması için bırakılan pay.
  static const _contentInset = 12.0;

  @override
  Widget build(BuildContext context) {
    final accent = isRest ? AppColors.secondary : AppColors.textSecondary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: progress, isRest: isRest),
          ),
          // Halka sabit boyutlu; yazı büyütülünce (küçük halkada, örneğin yatay
          // telefonda) içerik halkadan taşmasın diye sığana kadar küçülür.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size - _contentInset * 2,
              maxHeight: size - _contentInset * 2,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style:
                        (size >= PomodoroSizes.ringLargeText
                                ? AppTextStyles.timerDisplay
                                : AppTextStyles.timerDisplayMobile)
                            .copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    upperTr(label),
                    style: AppTextStyles.bodySm.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.isRest});

  final double progress;
  final bool isRest;

  static const _stroke = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.timerTrack,
    );

    if (progress <= 0) return;

    // Gradyan yay: tepeden (-90°) saat yönünde dolar.
    final sweep = 2 * math.pi * progress;
    final colors = isRest
        ? [AppColors.secondary, AppColors.secondaryCyan]
        : AppColors.timerGradient;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: colors,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isRest != isRest;
}
