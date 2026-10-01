import 'package:flutter/material.dart';

/// 8pt ritmi (DESIGN.md → Layout & Spacing).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Mobil sayfa kenar boşluğu / tablet kenar boşluğu.
  static const double margin = 16;
  static const double marginTablet = 32;
  static const double gutter = 16;
  static const double gutterTablet = 24;

  /// Görev kartları arası dikey boşluk.
  static const double listGap = 12;

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static double pageMargin(double width) =>
      width >= mobileBreakpoint ? marginTablet : margin;

  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.all(pageMargin(width));
}

/// Köşe yarıçapları (DESIGN.md → Shapes).
abstract final class AppRadius {
  static const double checkbox = 6;
  static const double control = 8; // input, segmented, list row
  static const double card = 16; // kart, modal
  static const double pill = 999; // buton, chip, FAB

  static const controlAll = BorderRadius.all(Radius.circular(control));
  static const cardAll = BorderRadius.all(Radius.circular(card));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
}

/// İkon boyutları (DESIGN.md boyut vermiyor, değerler bizim seçimimiz).
abstract final class AppIconSize {
  static const double chip = 16; // chip içi ikon
  static const double fab = 24; // FAB ikonu
  static const double state = 48; // loading/empty/error/success görünümleri
}
