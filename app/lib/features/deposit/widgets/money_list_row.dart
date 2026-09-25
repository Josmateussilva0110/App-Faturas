import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One salary or expense row: name, formatted value, remove button, and an
/// optional meta line (the running balance under each expense). Shared by
/// the salaries and expenses lists on the Deposit screen.
///
/// Tapping the row edits it; the close button removes it. The two gestures
/// stay separate so a mistyped value doesn't have to be deleted and retyped.
///
/// A linha não tem fundo próprio. Era um card cinza dentro do card branco da
/// seção — card dentro de card, e o cinza pesava mais que o valor em
/// dinheiro, que é o dado da linha. Quem separa uma linha da outra agora é
/// um divisor fino, e a superfície branca é uma só.
class MoneyListRow extends StatelessWidget {
  const MoneyListRow({
    super.key,
    required this.name,
    required this.valueLabel,
    required this.onRemove,
    this.onEdit,
    this.meta,
  });

  /// Largura fixa do botão de remover. Exposta para o total no cabeçalho do
  /// card reservar o mesmo espaço e ficar alinhado com os valores das linhas.
  static const double trailingWidth = 28;

  final String name;
  final String valueLabel;
  final String? meta;
  final VoidCallback onRemove;

  /// Opens the edit dialog when the row is tapped. Null leaves the row inert
  /// to taps.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.smPlus),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: text.body, overflow: TextOverflow.ellipsis),
                  if (meta != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    // Secundário de propósito: primeiro o usuário quer ver
                    // quanto aquela linha custa, e só depois o que sobrou.
                    Text(meta!, style: text.caption.copyWith(fontSize: 10)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.smPlus),
            Text(valueLabel, style: text.body.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(
              width: trailingWidth,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
                color: scheme.error,
                tooltip: 'Remover',
                constraints: const BoxConstraints(minWidth: trailingWidth, minHeight: trailingWidth),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
