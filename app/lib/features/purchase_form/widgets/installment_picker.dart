import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Número de parcelas: atalhos para os valores comuns e um − / + para
/// qualquer outro, sem abrir teclado.
class InstallmentPicker extends StatelessWidget {
  const InstallmentPicker({super.key, required this.value, required this.onChanged});

  /// Os parcelamentos que mais aparecem em fatura.
  static const presets = [1, 2, 3, 6, 10, 12];

  /// Teto do + — acima disso já não é parcela de cartão.
  static const max = 48;

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.palette.trackSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove),
                tooltip: 'Menos uma parcela',
              ),
              Expanded(
                child: Text(
                  value <= 1 ? 'À vista' : '$value parcelas',
                  textAlign: TextAlign.center,
                  style: context.text.label,
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add),
                tooltip: 'Mais uma parcela',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xsPlus,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in presets)
              ChoiceChip(
                label: Text('${preset}x'),
                selected: preset == value,
                onSelected: (_) => onChanged(preset),
                showCheckmark: false,
                shape: const StadiumBorder(),
                // Compactos para os seis caberem numa linha num celular comum.
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                backgroundColor: context.palette.trackSurface,
                selectedColor: scheme.primary,
                side: BorderSide(color: scheme.outlineVariant),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: preset == value ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
