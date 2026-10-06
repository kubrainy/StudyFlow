import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Küçük `−  değer dk  +` kontrolü. Değeri kendisi tutmaz; [onChanged] ile
/// yeni değeri bildirir. Sınırda ilgili düğme pasif olur. [label] ekranda
/// görünmez; düğmelerin ipucu ve erişilebilirlik adı için kullanılır.
class DurationStepper extends StatelessWidget {
  const DurationStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  final bool enabled;

  bool get _canDecrease => enabled && value - step >= min;
  bool get _canIncrease => enabled && value + step <= max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          tooltip: '$label azalt',
          onPressed: _canDecrease ? () => onChanged(value - step) : null,
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$value dk',
            textAlign: TextAlign.center,
            style: AppTextStyles.statMono.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: '$label artır',
          onPressed: _canIncrease ? () => onChanged(value + step) : null,
        ),
      ],
    );
  }
}

const double _visualSize = 34;
const double _hitSize = 44;

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        // Dokunma alanı 44dp, görünen daire 34dp.
        child: SizedBox(
          width: _hitSize,
          height: _hitSize,
          child: Center(
            child: Container(
              width: _visualSize,
              height: _visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? AppColors.focusFill : AppColors.surfaceSubdued,
                border: Border.all(
                  color: enabled ? AppColors.focusBorder : AppColors.border,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
