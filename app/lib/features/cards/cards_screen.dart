import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import 'card_name_dialog.dart';
import 'widgets/card_row.dart';

/// The "Cartões" tab: manage the credit cards purchases can be assigned to.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões'),
        actions: [
          IconButton(
            onPressed: () async {
              final name = await showCardNameDialog(context);
              if (name != null && context.mounted) {
                await context.read<AppState>().addCard(name);
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (appState.cards.isEmpty)
            const EmptyState(message: 'Nenhum cartão cadastrado.', icon: Icons.credit_card_outlined)
          else
            for (final card in appState.cards) ...[
              CardRow(
                name: card.name,
                onEdit: () async {
                  final name = await showCardNameDialog(context, existing: card);
                  if (name != null && context.mounted) {
                    await context.read<AppState>().renameCard(card.id, name);
                  }
                },
                onDelete: () => context.read<AppState>().deleteCard(card.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
