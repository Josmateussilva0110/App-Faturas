import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/avatar_circle.dart';
import '../../../widgets/grouped_list_card.dart';

/// Uma linha da aba Pessoas: avatar, nome, quanto do mês é dela, o total e o
/// botão de compartilhar. Vive dentro de um [GroupedListCard].
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.label,
    required this.total,
    required this.share,
    required this.onShare,
  });

  final String label;
  final double total;

  /// Fração do total do mês (0 a 1).
  final double share;

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: GroupedListCard.rowPadding.copyWith(right: AppSpacing.xs),
      child: Row(
        children: [
          AvatarCircle(label: label, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.title, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xxs),
                Text('${(share * 100).round()}% do mês', style: context.text.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // `money` e não `title`: a lista vem ordenada por valor — é ele
          // que explica a ordem.
          Text(formatMoney(total), style: context.text.money),
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 18),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tooltip: 'Compartilhar',
          ),
        ],
      ),
    );
  }
}
