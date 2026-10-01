import 'package:flutter/material.dart';

/// StudyFlow renk token'ları (DESIGN.md → Colors).
abstract final class AppColors {
  // Primary – Indigo
  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF6366F1);
  static const primaryPressed = Color(0xFF4338CA);
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary – Mint / Cyan
  static const secondary = Color(0xFF10B981);
  static const secondaryCyan = Color(0xFF06B6D4);
  static const onSecondary = Color(0xFFFFFFFF);

  // Tertiary – Amber / Coral
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Surfaces & neutrals
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubdued = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);

  // Chips (fill / text / border)
  static const highFill = Color(0xFFFEF2F2);
  static const highBorder = Color(0xFFFEE2E2);
  static const focusFill = Color(0xFFEEF2FF);
  static const focusBorder = Color(0xFFE0E7FF);
  static const doneFill = Color(0xFFECFDF5);
  static const doneBorder = Color(0xFFD1FAE5);

  // Timer
  static const timerTrack = Color(0xFFEEF2FF);
  static const timerGradient = [primary, secondaryCyan];

  // Modal scrim: #0F172A %40
  static const scrim = Color(0x660F172A);
}
