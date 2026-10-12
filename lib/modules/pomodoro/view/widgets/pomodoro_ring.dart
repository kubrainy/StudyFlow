import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'pomodoro_sizes.dart';

/// Uzun mola döngüsündeki bir oturumun durumu (halkanın altındaki noktalar).
enum PomodoroDot { done, current, todo }

class PomodoroRing extends StatelessWidget {
  const PomodoroRing({
    super.key,
    required this.progress,
    required this.timeText,
    required this.label,
    required this.sessionText,
    this.dots = const [],
    this.isRest = false,
    this.size = 260,
  });

  final double progress;
  final String timeText;

  /// Üstteki mono çip: "Odak Modu Aktif", "Mola Zamanı", "Hazır"...
  final String label;

  /// "Oturum 3 / 4".
  final String sessionText;
  final List<PomodoroDot> dots;
  final bool isRest;
  final double size;

  /// İçeriğin halka çizgisinden uzak durması için bırakılan pay.
  static const _contentInset = 28.0;

  @override
  Widget build(BuildContext context) {
    final accent = isRest ? AppColors.subjectGreen : AppColors.subjectBrown;

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
          // Halka sabit boyutlu; yazı büyütülünce içerik taşmasın diye sığana
          // kadar küçülür.
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.statMono.copyWith(
                        fontSize: 11,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    timeText,
                    style:
                        (size >= PomodoroSizes.ringLargeText
                                ? AppTextStyles.timerDisplay
                                : AppTextStyles.timerDisplayMobile)
                            .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    sessionText,
                    style: AppTextStyles.statMono.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (dots.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [for (final dot in dots) _Dot(state: dot)],
                    ),
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

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final PomodoroDot state;

  @override
  Widget build(BuildContext context) {
    final current = state == PomodoroDot.current;
    return Container(
      key: Key('pomodoro-dot-${state.name}'),
      width: current ? 22 : 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: switch (state) {
          PomodoroDot.done => AppColors.subjectGreen,
          PomodoroDot.current => AppColors.primary,
          PomodoroDot.todo => AppColors.chipFill,
        },
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.isRest});

  final double progress;
  final bool isRest;

  static const _stroke = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = (Offset.zero & size).deflate(_stroke / 2 + 4);

    // Yumuşak lavanta hare: halkanın içi ve çevresi.
    canvas.drawCircle(
      center,
      size.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.chipFill.withValues(alpha: 0.55),
            AppColors.chipFill.withValues(alpha: 0.25),
            AppColors.chipFill.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.8, 1.0],
        ).createShader(Offset.zero & size),
    );

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.surface.withValues(alpha: 0.7),
    );

    if (progress <= 0) return;

    // Gradyan yay: tepeden (-90°) saat yönünde dolar.
    final sweep = 2 * math.pi * progress;
    final colors = isRest
        ? [AppColors.mint, AppColors.subjectGreen]
        : [AppColors.primary, AppColors.primaryLight];

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
