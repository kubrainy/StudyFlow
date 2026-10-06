import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

abstract final class Responsive {
  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < AppSpacing.mobileBreakpoint;

  static int columns(BuildContext context) {
    final width = widthOf(context);
    if (width < AppSpacing.mobileBreakpoint) return 1;
    if (width < AppSpacing.tabletBreakpoint) return 2;
    return 3;
  }

  static TextStyle headlineXl(BuildContext context) => isMobile(context)
      ? AppTextStyles.headlineXlMobile
      : AppTextStyles.headlineXl;

  static TextStyle timerDisplay(BuildContext context) => isMobile(context)
      ? AppTextStyles.timerDisplayMobile
      : AppTextStyles.timerDisplay;
}
