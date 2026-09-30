import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../models/card_model.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grouped_list_card.dart';
import 'card_form_dialog.dart';
import 'widgets/card_row.dart';

/// The "Cartões" tab: manage the credit cards purchases can be assigned to.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Uma passada só pelas compras para todos os cartões, não uma por linha.
    final monthTotals = appState.totalsByCardFor(0);

    return Scaffold(
      appBar: AppBar(title: const Text('Cartões')),
      // O Scaffold posiciona o FAB ignorando o padding de baixo, e é nele que
      // o shell reserva o espaço da barra flutuante — sem este recuo o botão
      // fica escondido atrás dela.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton(
          onPressed: () async {
            final draft = await showCardDialog(context);
            if (draft == null || !context.mounted) return;

            // O AppState já avisou o usuário se falhou; só o sucesso é nosso
            // para anunciar.
            final added = await context.read<AppState>().addCard(draft.name, draft.hue);
            if (added) AppToast.success('Cartão "${draft.name}" adicionado.');
          },
          heroTag: 'fab-card',
          tooltip: 'Novo cartão',
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<AppState>().load(),
          child: ListView(
            // Sem isto, uma lista curta não rola e o gesto de puxar nunca
            // dispara — justo no caso que mais precisa dele, o de a carga
            // inicial ter falhado e a tela estar vazia.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (appState.loadError != null)
                EmptyState.error(
                  message: appState.loadError!,
                  onRetry: () => context.read<AppState>().load(),
                )
              else
                GroupedListCard(
                  title: 'Meus cartões',
                  empty: const EmptyState(
                    message: 'Nenhum cartão cadastrado.',
                    icon: Icons.credit_card_outlined,
                  ),
                  children: [
                    for (final card in appState.cards) _cardRow(context, appState, card, monthTotals[card.id] ?? 0),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Uma linha da lista. Vive fora do `children` porque os dois callbacks
  /// ocupavam mais linhas que o resto da tela inteira, e o esqueleto dela
  /// sumia no meio deles.
  Widget _cardRow(BuildContext context, AppState appState, CardModel card, double monthTotal) {
    return CardRow(
      name: card.name,
      hue: card.resolvedHue,
      monthTotal: monthTotal,
      onEdit: () async {
        final draft = await showCardDialog(context, existing: card);
        if (draft == null || !context.mounted) return;

        final saved = await context.read<AppState>().updateCard(card.id, draft.name, draft.hue);
        if (saved) AppToast.success('Cartão atualizado.');
      },
      onDelete: () async {
        final hasPurchases = appState.purchases.any((p) => p.cardId == card.id);
        final deleted = await context.read<AppState>().deleteCard(card.id);
        if (!deleted) return;

        if (hasPurchases) {
          AppToast.warning('Cartão excluído — algumas compras ficaram sem cartão vinculado.');
        } else {
          AppToast.success('Cartão excluído.');
        }
      },
    );
  }
}
