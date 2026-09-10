import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Os tokens de cor que dependem do tema, já resolvidos.
///
/// Existe para tirar `dark` das assinaturas: com as funções estáticas de
/// [AppColors], todo widget precisava recalcular
/// `Theme.of(context).brightness == Brightness.dark` antes de pedir uma cor
/// — eram 17 lugares fazendo a mesma conta. Aqui a extensão já nasce
/// sabendo o próprio brilho.
///
/// Use por `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.dark,
    required this.softSurface,
    required this.softBorder,
    required this.trackSurface,
  });

  factory AppPalette.of(ColorScheme scheme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return AppPalette(
      dark: dark,
      softSurface: dark ? scheme.surfaceContainerHigh : Colors.white,
      softBorder: dark ? scheme.outlineVariant : const Color(0xFFE2E8F0),
      trackSurface: dark ? scheme.surfaceContainerHighest : const Color(0xFFF0F1F5),
    );
  }

  final bool dark;

  /// Fundo de campos de formulário e "pílulas" sobre a página.
  final Color softSurface;

  /// Borda desses mesmos elementos.
  final Color softBorder;

  /// Trilho de fundo do seletor segmentado.
  final Color trackSurface;

  // ── Cores por matiz ─────────────────────────────────────────────────
  // Continuam sendo funções porque o matiz é dinâmico (hash de um nome, ou
  // a cor que o usuário escolheu para o cartão) — mas sem receber `dark`.

  Color avatarBackground(int hue) => AppColors.avatarBackground(hue, dark: dark);
  Color tagBackground(int hue) => AppColors.tagBackground(hue, dark: dark);
  Color tagForeground(int hue) => AppColors.tagForeground(hue, dark: dark);
  Color iconTint(double hue) => AppColors.iconTint(hue, dark: dark);

  // ── Sombras ─────────────────────────────────────────────────────────
  // Vazias no tema escuro. Sombra preta sobre fundo escuro não separa nada:
  // quem precisa de separação ali usa borda, que é o que o FormSectionCard
  // já fazia sozinho antes destes tokens existirem.

  /// Separação sutil, para blocos que já têm cor de fundo própria.
  List<BoxShadow> get shadowLow => dark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];

  /// Elementos que flutuam sobre o conteúdo: card primário, toast, pílula
  /// selecionada do seletor segmentado.
  List<BoxShadow> get shadowMedium => dark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ];

  @override
  AppPalette copyWith({
    bool? dark,
    Color? softSurface,
    Color? softBorder,
    Color? trackSurface,
  }) {
    return AppPalette(
      dark: dark ?? this.dark,
      softSurface: softSurface ?? this.softSurface,
      softBorder: softBorder ?? this.softBorder,
      trackSurface: trackSurface ?? this.trackSurface,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      // Booleano não interpola: acompanha o destino a partir da metade.
      dark: t < 0.5 ? dark : other.dark,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      softBorder: Color.lerp(softBorder, other.softBorder, t)!,
      trackSurface: Color.lerp(trackSurface, other.trackSurface, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
