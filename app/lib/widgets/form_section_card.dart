import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: dark ? Border.all(color: scheme.outlineVariant) : null,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
