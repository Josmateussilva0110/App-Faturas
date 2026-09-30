import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';
import '../models/purchase.dart';
import 'avatar_circle.dart';
import 'grouped_list_card.dart';

/// Linha compacta de compra, para listas agrupadas num bloco só: avatar na
/// cor do cartão, nome e detalhes à esquerda, valor e parcela à direita.
///
/// Várias linhas dividem o mesmo fundo, como um extrato — use dentro de um
/// [GroupedListCard], não uma por card.
class PurchaseRow extends StatelessWidget {
  const PurchaseRow({
    super.key,
    required this.purchase,
    required this.status,
    required this.cardName,
    required this.cardHue,
    required this.onTap,
    this.alwaysShowPerson = false,
  });

  final Purchase purchase;
  final PurchaseStatus status;
  final String cardName;

  /// Cor do cartão já resolvida (ver [AppState.cardHue]).
  final int cardHue;

  final VoidCallback onTap;

  /// Meses mostra de quem é toda compra; a Home só as de outra pessoa.
  final bool alwaysShowPerson;

  @override
  Widget build(BuildContext context) {
    final installment = purchase.installments <= 1
        ? 'à vista'
        : '${status.installmentNumber}/${purchase.installments}';
    // Na Home a pessoa só aparece quando não é o próprio usuário: "Nós" em
    // toda linha seria ruído ali.
    final details = [cardName, if (alwaysShowPerson || purchase.isOther) purchase.personLabel].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: GroupedListCard.rowPadding,
        child: Row(
          children: [
            AvatarCircle(label: purchase.name, hue: cardHue, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(purchase.name, overflow: TextOverflow.ellipsis, style: context.text.title),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(details, overflow: TextOverflow.ellipsis, style: context.text.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatMoney(purchase.amount), style: context.text.money),
                const SizedBox(height: AppSpacing.xxs),
                Text(installment, style: context.text.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
