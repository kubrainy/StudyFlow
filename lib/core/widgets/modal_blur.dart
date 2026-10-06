import 'dart:ui';

import 'package:flutter/material.dart';

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
