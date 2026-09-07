import 'package:flutter/material.dart';

/// Fixed color tokens that Material's generated [ColorScheme] doesn't cover:
/// hue-based tags/avatars for people and cards, matching the design
/// prototype's per-label color hashing.
class AppColors {
  const AppColors._();

  /// Accent seed color used to generate the whole Material color scheme.
  static const Color seed = Color(0xFF297CEF);

  static Color avatarBackground(int hue, {required bool dark}) {
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.62, dark ? 0.58 : 0.48).toColor();
  }

  static const Color avatarForeground = Colors.white;

  static Color tagBackground(int hue, {required bool dark}) {
    return HSLColor.fromAHSL(1, hue.toDouble(), dark ? 0.38 : 0.80, dark ? 0.24 : 0.93).toColor();
  }

  static Color tagForeground(int hue, {required bool dark}) {
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, dark ? 0.86 : 0.30).toColor();
  }
}
