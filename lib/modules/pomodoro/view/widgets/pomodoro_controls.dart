import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../view_model/pomodoro_view_model.dart';
import 'pomodoro_sizes.dart';

/// Odaklan / Kısa Mola / Uzun Mola şeridi; dokununca aşama değişir. Her
/// sekmede ayarlardaki süre ("25dk") yazar.
class PomodoroPhaseTabs extends StatelessWidget {
  const PomodoroPhaseTabs({
    super.key,
    required this.phase,
    required this.minutesOf,
    this.onChanged,
  });

  final PomodoroPhase phase;
  final int Function(PomodoroPhase phase) minutesOf;
  final ValueChanged<PomodoroPhase>? onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (PomodoroPhase.work, Icons.track_changes, 'Odaklan'),
      (PomodoroPhase.rest, Icons.coffee_outlined, 'Kısa Mola'),
      (PomodoroPhase.longRest, Icons.weekend_outlined, 'Uzun Mola'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chipFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final (value, icon, label) in items)
            _Segment(
              icon: icon,
              label: '$label\n(${minutesOf(value)}dk)',
              selected: phase == value,
              onTap: () => onChanged?.call(value),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected ? AppShadows.level1 : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alttaki sıra: ⟲ sıfırla, ana "Başlat / Duraklat / Devam" hapı, ⏭ bitir.
/// Sıfırla hiçbir şey kaydetmeden başa döner; sağdaki düğme çalışmada geçen
/// dakikaları kaydedip bitirir, molada molayı atlar.
class PomodoroControls extends StatelessWidget {
  const PomodoroControls({
    super.key,
    required this.status,
    required this.phase,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onFinish,
    required this.onSkip,
  });

  final PomodoroStatus status;
  final PomodoroPhase phase;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final idle = status == PomodoroStatus.idle;
    final isWork = phase == PomodoroPhase.work;

    final (label, icon, onTap) = switch (status) {
      PomodoroStatus.idle => ('Başlat', Icons.play_arrow_rounded, onStart),
      PomodoroStatus.running => ('Duraklat', Icons.pause_rounded, onPause),
      PomodoroStatus.paused => ('Devam', Icons.play_arrow_rounded, onResume),
    };

    return Row(
      children: [
        _RoundButton(
          tooltip: 'Sıfırla',
          icon: Icons.replay_rounded,
          onTap: idle ? null : onReset,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Tooltip(
            message: label,
            child: GestureDetector(
              key: const Key('pomodoro-main'),
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: PomodoroSizes.controlButton,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.level3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.onPrimary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RoundButton(
          tooltip: isWork ? 'Bitir' : 'Molayı atla',
          icon: Icons.skip_next_rounded,
          onTap: idle ? null : (isWork ? onFinish : onSkip),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            width: PomodoroSizes.controlButton,
            height: PomodoroSizes.controlButton,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.level2,
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
