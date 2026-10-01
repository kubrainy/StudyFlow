import 'package:flutter/material.dart';

/// Elevation seviyeleri (DESIGN.md → Elevation & Depth).
abstract final class AppShadows {
  /// Level 1 – dinlenme halindeki kart (border ile birlikte kullanılır).
  static const level1 = [
    BoxShadow(
      color: Color(0x0A0F172A), // %4
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x050F172A), // %2
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Level 2 – aktif/basılı kart, alt navigasyon.
  static const level2 = [
    BoxShadow(
      color: Color(0x144F46E5), // %8 indigo
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x080F172A), // %3
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  /// Level 3 – FAB indigo aurası.
  static const level3 = [
    BoxShadow(
      color: Color(0x594F46E5), // %35 indigo
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  /// Ana buton – hafif indigo parlaması.
  static const primaryGlow = [
    BoxShadow(
      color: Color(0x334F46E5), // %20 indigo
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Modal arka plan bulanıklığı (sigma).
  static const double modalBlur = 12;
}
