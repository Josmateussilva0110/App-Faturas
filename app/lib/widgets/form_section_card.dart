import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';

/// White card used to visually group one section of a form (e.g. the "Nova
/// compra" screen's "Detalhes da compra", "Quando começa" and "Pagamento"
/// blocks) instead of thin dividers cutting across the screen.
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
        // Plano como o AppCard: no claro o branco sobre o cinza já separa; no
        // escuro esse degrau é pequeno e a borda volta.
        border: palette.dark ? Border.all(color: palette.softBorder) : null,
      ),
      child: child,
    );
  }
}
