import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Uygulamanın Material 3 teması (DESIGN.md → Components).
abstract final class AppTheme {
  static const _inputBorderWidth = 1.0;
  static const _inputFocusWidth = 2.0;

  static OutlineInputBorder _inputBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: AppRadius.controlAll,
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      tertiary: AppColors.warning,
      onTertiary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.canvas,
      surfaceContainer: AppColors.surfaceSubdued,
      outline: AppColors.textSecondary,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: AppTextStyles.textTheme,
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headlineMd,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      // Primary buton: pill, indigo, beyaz metin.
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textDisabled,
              minimumSize: const Size(64, 48),
              shape: const StadiumBorder(),
              textStyle: AppTextStyles.titleMd.copyWith(fontSize: 16),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                AppColors.primaryPressed.withValues(alpha: 0.24),
              ),
            ),
      ),
      // Secondary buton: pill, beyaz, 1px border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: AppColors.textDisabled,
              minimumSize: const Size(64, 48),
              shape: const StadiumBorder(),
              side: const BorderSide(color: AppColors.border),
              textStyle: AppTextStyles.titleMd.copyWith(fontSize: 16),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                AppColors.surfaceSubdued,
              ),
            ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),
      // Input: 48dp, 8dp radius, 2px indigo focus halkası.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled),
        labelStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.primary,
        ),
        border: _inputBorder(AppColors.border, _inputBorderWidth),
        enabledBorder: _inputBorder(AppColors.border, _inputBorderWidth),
        focusedBorder: _inputBorder(AppColors.primaryLight, _inputFocusWidth),
        errorBorder: _inputBorder(AppColors.danger, _inputBorderWidth),
        focusedErrorBorder: _inputBorder(AppColors.danger, _inputFocusWidth),
        disabledBorder: _inputBorder(AppColors.border, _inputBorderWidth),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.checkbox),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondary
              : Colors.transparent,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: AppTextStyles.bodySm,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.focusFill,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(AppTextStyles.bodySm),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        contentTextStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onPrimary,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),
    );
  }
}
