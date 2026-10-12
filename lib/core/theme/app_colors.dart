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
  static const canvas = Color(0xFFF6F6FE); // lavanta tonu (Figma)
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubdued = Color(0xFFEFF0FF); // lavanta tonu (Figma)
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);

  // Figma tasarımı (2026-10-09): renkler görsellerden gözle okundu, tahmindir.
  /// Kartın çok açık kenarı (kart zaten gölgeli).
  static const cardBorder = Color(0xFFEDEEF8);

  /// İndigo çip / ikon kutusu zemini ve koyu mor yazısı.
  static const chipFill = Color(0xFFE3E6FF);

  /// Nane rozeti ("+%18", "KAZANILDI") zemini ve koyu yeşil yazısı.
  static const mint = Color(0xFF6EEBC0);
  static const mintText = Color(0xFF065F46);
  static const mintSoft = Color(0xFFD5F8EA);

  /// Ders / grafik renkleri: indigo, koyu yeşil, kahve, koyu kırmızı.
  static const subjectGreen = Color(0xFF047857);
  static const subjectBrown = Color(0xFF8B5E0B);
  static const subjectRed = Color(0xFFB91C1C);
  static const peachSoft = Color(0xFFFFE8CC);

  /// Öncelik rozetleri.
  static const mediumFill = Color(0xFFFFE6C7);
  static const mediumText = Color(0xFF9A5B00);

  /// Kahraman kartı gradyanı (Özet "Kaldığın yerden devam et", Dersler alt kart).
  static const heroGradient = [Color(0xFF4F46E5), Color(0xFF6A5BF0)];

  // Chips (fill / text / border)
  static const highFill = Color(0xFFFEF2F2);
  static const highBorder = Color(0xFFFEE2E2);
  static const focusFill = Color(0xFFEEF2FF);
  static const focusBorder = Color(0xFFE0E7FF);
  static const doneFill = Color(0xFFECFDF5);
  static const doneBorder = Color(0xFFD1FAE5);

  // Timer
  // Çalışma süresi çipi (tahmin, DESIGN.md renk vermiyor): cyan ailesi.
  static const durationFill = Color(0xFFECFEFF);
  static const durationBorder = Color(0xFFCFFAFE);
  static const durationText = Color(0xFF0E7490);
  static const timerTrack = Color(0xFFEEF2FF);
  // Halka yukarıdan başlar: teal → indigo (Figma).
  static const timerGradient = [Color(0xFF34D3B5), primary];

  // Grafiklerde ders rengi: ilk dört renk Figma'daki (indigo, yeşil, kahve, kırmızı);
  // 10'dan fazla derste başa dönülür.
  static const subjectPalette = [
    primary, // indigo
    subjectGreen,
    subjectBrown,
    subjectRed,
    Color(0xFFEC4899), // pembe
    Color(0xFF8B5CF6), // mor
    Color(0xFF3B82F6), // mavi
    Color(0xFFF97316), // turuncu
    Color(0xFF14B8A6), // turkuaz
    Color(0xFF84CC16), // limon yeşili
  ];

  // Modal scrim: #0F172A %40
  static const scrim = Color(0x660F172A);
}
