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

  // ── Section accents ─────────────────────────────────────────────────
  // Fixed hues used to tint section icons across the app (savings, expenses,
  // people, cards...), independent of the per-label hash above. Money-related
  // icons reuse the theme's own `colorScheme.primary` instead of a fixed hue
  // here, so they stay in sync with the seed color.
  static const double hueSavings = 152;
  static const double hueExpense = 22;
  static const double huePeople = 271;
  static const double hueCards = 184;
  static const double hueWarning = 38;

  /// A moderately saturated tint for icons sitting on a plain surface —
  /// rich enough to read as "colorful" without shouting, and light/dark
  /// aware like the tokens above.
  static Color iconTint(double hue, {required bool dark}) {
    return HSLColor.fromAHSL(1, hue, 0.60, dark ? 0.68 : 0.42).toColor();
  }

  // ── Superfícies suaves ──────────────────────────────────────────────
  // No claro o app usa branco puro sobre o cinza da página, o que o
  // ColorScheme gerado não oferece; no escuro os tokens do próprio esquema
  // já resolvem. Ficam aqui para a decisão existir num lugar só.

  /// Fundo de campos de formulário e "pílulas" sobre a página.
  static Color softSurface(ColorScheme scheme, {required bool dark}) {
    return dark ? scheme.surfaceContainerHigh : Colors.white;
  }

  /// Borda desses mesmos elementos.
  static Color softBorder(ColorScheme scheme, {required bool dark}) {
    return dark ? scheme.outlineVariant : const Color(0xFFE2E8F0);
  }

  /// Trilho de fundo do seletor segmentado.
  static Color trackSurface(ColorScheme scheme, {required bool dark}) {
    return dark ? scheme.surfaceContainerHighest : const Color(0xFFF0F1F5);
  }

  /// Destaque do valor quando o gasto passa do limite, sobre o card
  /// primário. Não usa `scheme.error` porque o card já é colorido e a cor de
  /// erro do esquema não contrasta com ele.
  static const Color overLimitOnPrimary = Color(0xFFFFB4AB);

  /// A fixed, fairly dark saturated fill for toast/snackbar backgrounds.
  /// Deliberately not light/dark-mode aware — a floating toast wants strong,
  /// consistent contrast with its white text regardless of the app's theme.
  static Color toastBackground(double hue) => HSLColor.fromAHSL(1, hue, 0.55, 0.32).toColor();
}
