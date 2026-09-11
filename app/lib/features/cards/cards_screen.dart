import '../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_label.dart';
import 'card_form_dialog.dart';
import 'widgets/card_row.dart';

/// The "Cartões" tab: manage the credit cards purchases can be assigned to.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cartões')),
      // Criar conteúdo é FAB em todo o app; antes disto era ícone na AppBar
      // aqui e FAB nas compras, para a mesma intenção.
      floatingActionButton: FloatingActionButton(
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
              SectionLabel(
                'Meus cartões',
                icon: Icons.credit_card_outlined,
                iconColor: context.palette.iconTint(AppColors.hueCards),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (appState.loadError != null)
                EmptyState.error(
                  message: appState.loadError!,
                  onRetry: () => context.read<AppState>().load(),
                )
              else if (appState.cards.isEmpty)
                const EmptyState(
                  message: 'Nenhum cartão cadastrado.',
                  icon: Icons.credit_card_outlined,
                )
              else
                for (final card in appState.cards) ...[
                  CardRow(
                    name: card.name,
                    hue: card.resolvedHue,
                    onEdit: () async {
                      final draft = await showCardDialog(context, existing: card);
                      if (draft == null || !context.mounted) return;

                      final saved = await context
                          .read<AppState>()
                          .updateCard(card.id, draft.name, draft.hue);
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
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
