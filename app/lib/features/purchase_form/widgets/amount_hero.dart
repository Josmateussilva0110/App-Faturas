import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

/// O valor da parcela em destaque, centralizado e grande, com o resumo do
/// parcelamento logo abaixo — o dado principal do formulário aparece como
/// tal, e não como mais um campo na lista.
class AmountHero extends StatelessWidget {
  const AmountHero({
    super.key,
    required this.controller,
    required this.amount,
    required this.installments,
    required this.onChanged,
  });

  final TextEditingController controller;

  /// Valor já interpretado, ou nulo enquanto o texto não é um número válido.
  final double? amount;

  final int installments;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heroStyle = context.text.hero;
    final amount = this.amount;

    return Column(
      children: [
        Text('Valor da parcela', style: context.text.field),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('R\$ ', style: heroStyle.copyWith(fontSize: 22, color: scheme.onSurfaceVariant)),
            // Largura do próprio texto: com o campo esticado, o "R$" ficava
            // colado na borda e o valor centralizado longe dele.
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, maxWidth: 220),
              child: IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: heroStyle,
                  decoration: InputDecoration(
                    hintText: '0,00',
                    hintStyle: heroStyle.copyWith(color: scheme.outlineVariant),
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          amount == null || amount <= 0
              ? 'Quanto vem em cada fatura'
              : installments <= 1
                  ? 'À vista'
                  : '$installments× · total ${formatMoney(amount * installments)}',
          style: context.text.caption,
        ),
      ],
    );
  }
}
