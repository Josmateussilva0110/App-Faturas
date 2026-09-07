import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_label.dart';
import 'card_name_dialog.dart';
import 'widgets/card_row.dart';

/// The "Cartões" tab: manage the credit cards purchases can be assigned to.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões'),
        actions: [
          IconButton(
            onPressed: () async {
              final name = await showCardNameDialog(context);
              if (name == null || !context.mounted) return;
              try {
                await context.read<AppState>().addCard(name);
                AppToast.success('Cartão "$name" adicionado.');
              } catch (_) {
                AppToast.error('Não foi possível adicionar o cartão.');
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SectionLabel(
            'Meus cartões',
            icon: Icons.credit_card_outlined,
            iconColor: AppColors.iconTint(AppColors.hueCards, dark: dark),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (appState.cards.isEmpty)
            const EmptyState(message: 'Nenhum cartão cadastrado.', icon: Icons.credit_card_outlined)
          else
            for (final card in appState.cards) ...[
              CardRow(
                name: card.name,
                onEdit: () async {
                  final name = await showCardNameDialog(context, existing: card);
                  if (name == null || !context.mounted) return;
                  try {
                    await context.read<AppState>().renameCard(card.id, name);
                    AppToast.success('Cartão atualizado.');
                  } catch (_) {
                    AppToast.error('Não foi possível renomear o cartão.');
                  }
                },
                onDelete: () async {
                  final hasPurchases = appState.purchases.any((p) => p.cardId == card.id);
                  try {
                    await context.read<AppState>().deleteCard(card.id);
                    if (hasPurchases) {
                      AppToast.warning('Cartão excluído — algumas compras ficaram sem cartão vinculado.');
                    } else {
                      AppToast.success('Cartão excluído.');
                    }
                  } catch (_) {
                    AppToast.error('Não foi possível excluir o cartão.');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
