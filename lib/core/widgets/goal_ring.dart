import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.progress,
    required this.value,
    required this.caption,
    this.size = 112,
    this.valueStyle,
    this.captionStyle,
  });

  final double progress;
  final String value;
  final String caption;
  final double size;
  final TextStyle? valueStyle;
  final TextStyle? captionStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Halkanın içine sığmazsa yazı küçülür.
              SizedBox(
                width: size - 36,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style:
                        valueStyle ??
                        AppTextStyles.headlineLg.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                style:
                    captionStyle ??
                    AppTextStyles.bodySm.copyWith(
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
      // Renk geçişi yalnızca dolu yay boyunca uzanır; yayın başı teal, sonu
      // indigo olur (tam turda başlangıç ucu da indigoya dönmesin).
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi * progress,
        colors: AppColors.timerGradient,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
