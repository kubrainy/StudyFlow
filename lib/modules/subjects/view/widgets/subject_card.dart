import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../models/subject.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.onTap,
    this.onLongPress,
  });

  final Subject subject;
  final int totalTasks;
  final int completedTasks;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final description = subject.description;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        child: Row(
          children: [
            _ProgressRing(total: totalTasks, completed: completedTasks),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: '${subject.totalStudyMinutes} dk',
              type: AppChipType.duration,
              icon: Icons.timer_outlined,
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Görev yoksa boş gri halka + kitap ikonu, varsa yüzde, hepsi bittiyse yeşil halka + tik.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.total, required this.completed});

  final int total;
  final int completed;

  /// %50'nin altı sarı, %50 ve üstü indigo, tamamı yeşil.
  Color _colorFor(double fraction) {
    if (fraction >= 1) return AppColors.secondary;
    if (fraction >= 0.5) return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : completed / total;
    final allDone = total > 0 && completed == total;

    return SizedBox(
      key: const Key('subject-ring'),
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(44, 44),
            painter: _RingPainter(
              fraction: fraction,
              color: _colorFor(fraction),
            ),
          ),
          if (total == 0)
            const Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: AppColors.textDisabled,
            )
          else if (allDone)
            const Icon(Icons.check, size: 22, color: AppColors.secondary)
          else
            Text(
              '${(fraction * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    canvas.drawCircle(arcRect.center, arcRect.width / 2, track);
    if (fraction <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
