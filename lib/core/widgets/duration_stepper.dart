import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Küçük `−  değer  +` kontrolü (lavanta hap içinde). Değeri kendisi tutmaz;
/// [onChanged] ile yeni değeri bildirir. Sınırda ilgili düğme pasif olur.
/// [label] ekranda görünmez; düğmelerin ipucu ve erişilebilirlik adı içindir.
/// [format] değerin yazısını belirler (varsayılan "25 dk").
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
    this.format,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  final bool enabled;
  final String Function(int value)? format;

  bool get _canDecrease => enabled && value - step >= min;
  bool get _canIncrease => enabled && value + step <= max;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.chipFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            tooltip: '$label azalt',
            onPressed: _canDecrease ? () => onChanged(value - step) : null,
          ),
          // Çok uzun değer yazısı ("4 Oturumda Bir") büyük yazıda dar ekrana
          // sığmazsa küçülür.
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 52),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  format?.call(value) ?? '$value dk',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statMono.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: '$label artır',
            onPressed: _canIncrease ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

const double _hitWidth = 36;
const double _hitHeight = 44;

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
        child: SizedBox(
          width: _hitWidth,
          height: _hitHeight,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
