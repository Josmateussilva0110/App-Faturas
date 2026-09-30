import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../state/app_state.dart';
import 'empty_state.dart';
import 'grouped_list_card.dart';
import 'purchase_row.dart';

/// Bloco com título e as compras em linhas de [PurchaseRow], ou a mensagem de
/// vazio. É a lista da Home e da aba Meses.
///
/// Recebe nome e cor do cartão como funções em vez de ler o estado: o widget
/// só desenha, e quem sabe resolver um `cardId` é a tela.
class PurchaseListCard extends StatelessWidget {
  const PurchaseListCard({
    super.key,
    required this.title,
    required this.entries,
    required this.emptyMessage,
    required this.cardName,
    required this.cardHue,
    required this.onTap,
    this.alwaysShowPerson = false,
  });

  final String title;
  final List<PurchaseEntry> entries;
  final String emptyMessage;
  final String Function(String cardId) cardName;
  final int Function(String cardId) cardHue;
  final void Function(Purchase purchase) onTap;
  final bool alwaysShowPerson;

  @override
  Widget build(BuildContext context) {
    return GroupedListCard(
      title: title,
      empty: EmptyState(message: emptyMessage),
      children: [
        for (final entry in entries)
          PurchaseRow(
            purchase: entry.purchase,
            status: entry.status,
            cardName: cardName(entry.purchase.cardId),
            cardHue: cardHue(entry.purchase.cardId),
            alwaysShowPerson: alwaysShowPerson,
            onTap: () => onTap(entry.purchase),
          ),
      ],
    );
  }
}
