import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Modal açıkken arka planı 12px bulanıklaştırır (DESIGN.md → Elevation Level 3).
class ModalBlur extends StatelessWidget {
  const ModalBlur({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child,
    );
  }
}

/// Alt paneli tüm ekranı kaplayan #0F172A %40 perde ve 12px bulanıklıkla açar.
/// Bulanıklık yalnızca arkadaki sayfaya uygulanır, panel net kalır.
Future<T?> showBlurredSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.scrim,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, _, _) => Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: const SizedBox.expand(),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(top: false, child: builder(ctx)),
          ),
        ),
      ],
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
      child: child,
    ),
  );
}
