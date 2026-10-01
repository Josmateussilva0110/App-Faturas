import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/grouped_list_card.dart';
import '../../../widgets/icon_badge.dart';

/// Uma linha de salário ou despesa, dentro de um [GroupedListCard]: ícone na
/// cor da seção, nome, valor e o botão de remover, com uma linha opcional
/// embaixo (o saldo que sobra depois de cada despesa).
///
/// Tocar na linha edita; o X remove. Os dois gestos ficam separados para um
/// valor digitado errado não precisar ser apagado e lançado de novo.
class MoneyListRow extends StatelessWidget {
  const MoneyListRow({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.valueLabel,
    required this.onRemove,
    this.onEdit,
    this.meta,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String valueLabel;
  final String? meta;
  final VoidCallback onRemove;

  /// Abre a edição ao tocar na linha. Nula deixa a linha inerte.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: GroupedListCard.rowPadding.copyWith(right: AppSpacing.xs),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color, size: 40, iconSize: 18),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: text.title, overflow: TextOverflow.ellipsis),
                  if (meta != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    // Secundário de propósito: primeiro o usuário quer ver
                    // quanto aquela linha custa, e só depois o que sobrou.
                    Text(meta!, style: text.caption, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(valueLabel, style: text.money),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              color: scheme.onSurfaceVariant,
              tooltip: 'Remover',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
