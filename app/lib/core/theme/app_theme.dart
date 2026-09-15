import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the app's Material 3 themes from a single seed color, so light and
/// dark stay in sync without hand-tuned duplicate palettes.
class AppTheme {
  const AppTheme._();

  // Construídos uma vez: `_build` roda um `ColorScheme.fromSeed`, caro demais
  // para repetir a cada rebuild de quem consome o tema. Não dependem de
  // `context` nem de `MediaQuery`, então o valor é estável pela sessão.
  static final ThemeData _light = _build(Brightness.light);
  static final ThemeData _dark = _build(Brightness.dark);

  static ThemeData light() => _light;
  static ThemeData dark() => _dark;

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final cardRadius = BorderRadius.circular(AppRadius.md);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Os tokens do app vivem em extensões: assim todo widget os alcança
      // por `context.palette` / `context.text`, sem passar `dark` adiante.
      extensions: [AppPalette.of(scheme, brightness), AppTypography.of(scheme)],
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }
}
