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

  /// Esquema monocromático com as superfícies ajustadas à mão.
  ///
  /// O `monochrome` do Material dá cinzas harmônicos, mas as superfícies dele
  /// ficam todas no mesmo tom. O visual pede página cinza-clara e blocos
  /// brancos por cima — a separação vem desse degrau, não de borda ou sombra.
  static ColorScheme _scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    if (brightness == Brightness.dark) {
      return base.copyWith(
        primary: const Color(0xFFEDEDEF),
        onPrimary: const Color(0xFF151517),
        primaryContainer: const Color(0xFF2E2E33),
        onPrimaryContainer: const Color(0xFFEDEDEF),
        surface: const Color(0xFF0F0F11),
        surfaceContainerLowest: const Color(0xFF0B0B0C),
        surfaceContainerLow: const Color(0xFF141416),
        surfaceContainer: const Color(0xFF18181B),
        surfaceContainerHigh: const Color(0xFF1D1D20),
        surfaceContainerHighest: const Color(0xFF28282C),
        outlineVariant: const Color(0xFF2C2C31),
      );
    }
    return base.copyWith(
      primary: const Color(0xFF232326),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6E6EA),
      onPrimaryContainer: const Color(0xFF1B1B1E),
      surface: const Color(0xFFF3F3F5),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8F8FA),
      surfaceContainer: const Color(0xFFEFEFF2),
      surfaceContainerHigh: Colors.white,
      surfaceContainerHighest: const Color(0xFFE8E8EC),
      outlineVariant: const Color(0xFFE4E4E8),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);
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
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
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
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }
}
