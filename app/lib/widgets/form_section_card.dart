import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';

/// White card used to visually group one section of a form (e.g. the "Nova
/// compra" screen's "Detalhes da compra", "Quando começa" and "Pagamento"
/// blocks) instead of thin dividers cutting across the screen. Sits best on
/// a slightly gray/off-white page background so the card reads as raised.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // No escuro a sombra some (ver AppPalette.shadowLow) e é a borda que
        // separa o card do fundo.
        border: palette.dark ? Border.all(color: palette.softBorder) : null,
        boxShadow: palette.shadowLow,
      ),
      child: child,
    );
  }
}
