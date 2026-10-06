import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_sizes.dart';

/// Hangi aşamada olduğunu gösteren iki parçalı şerit; dokununca aşama değişir.
class PomodoroPhaseTabs extends StatelessWidget {
  const PomodoroPhaseTabs({super.key, required this.phase, this.onChanged});

  final PomodoroPhase phase;
  final ValueChanged<PomodoroPhase>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubdued,
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Odaklan',
            selected: phase == PomodoroPhase.work,
            onTap: () => onChanged?.call(PomodoroPhase.work),
          ),
          _Segment(
            label: 'Mola',
            selected: phase == PomodoroPhase.rest,
            selectedColor: AppColors.secondary,
            onTap: () => onChanged?.call(PomodoroPhase.rest),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.textPrimary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: PomodoroSizes.tabHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.segment),
            boxShadow: selected ? AppShadows.level1 : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? selectedColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ders hapının yanındaki yuvarlak ana düğme: hazırken ▶ (Başlat), çalışırken
/// ⏸ (Duraklat), duraklatılmışken ▶ (Devam). Molada yeşil olur. Hazırken büyük,
/// sayaç başlayınca küçülür (yanına durdur ikonu sığsın diye).
class PomodoroCircleButton extends StatelessWidget {
  const PomodoroCircleButton({
    super.key,
    required this.status,
    required this.phase,
    required this.onStart,
    required this.onPause,
    required this.onResume,
  });

  final PomodoroStatus status;
  final PomodoroPhase phase;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final isRest = phase == PomodoroPhase.rest;
    final idle = status == PomodoroStatus.idle;
    final running = status == PomodoroStatus.running;
    final fill = isRest ? AppColors.secondary : AppColors.primary;

    // Çalışmada sakin görünüm (dolgusuz); mola ve diğer durumlarda dolu.
    final ghost = running && !isRest;
    final size = idle ? PomodoroSizes.mainButton : PomodoroSizes.compactButton;

    final (label, icon, onTap) = switch (status) {
      PomodoroStatus.idle => ('Başlat', Icons.play_arrow_rounded, onStart),
      PomodoroStatus.running => ('Duraklat', Icons.pause_rounded, onPause),
      PomodoroStatus.paused => ('Devam', Icons.play_arrow_rounded, onResume),
    };

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: const Key('pomodoro-circle'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ghost ? AppColors.surface : fill,
            border: ghost ? Border.all(color: AppColors.border) : null,
            boxShadow: ghost || isRest ? null : AppShadows.primaryGlow,
          ),
          child: Icon(
            icon,
            size: idle ? PomodoroSizes.mainIcon : PomodoroSizes.compactIcon,
            color: ghost ? AppColors.textPrimary : AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// Sayaç başlayınca ana düğmenin yanında çıkan küçük durdur ikonu: çalışmada
/// ■ (Bitir, geçen dakikalar kaydedilir), molada ⏭ (Molayı atla).
class PomodoroStopButton extends StatelessWidget {
  const PomodoroStopButton({
    super.key,
    required this.phase,
    required this.onFinish,
    required this.onSkip,
  });

  final PomodoroPhase phase;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isRest = phase == PomodoroPhase.rest;

    return Tooltip(
      message: isRest ? 'Molayı atla' : 'Bitir',
      child: GestureDetector(
        onTap: isRest ? onSkip : onFinish,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: PomodoroSizes.compactButton,
          height: PomodoroSizes.compactButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            isRest ? Icons.skip_next_rounded : Icons.stop_rounded,
            size: PomodoroSizes.stopIcon,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
