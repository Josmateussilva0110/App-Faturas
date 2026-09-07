import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/purchase_tile.dart';
import '../../widgets/section_label.dart';
import '../../widgets/total_card.dart';
import '../purchase_form/edit_purchase_dialog.dart';

/// The "Meses" tab: browse any month (past or future) to see which
/// installments fall on it.
class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entries = appState.monthlyEntries;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => context.read<AppState>().changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(formatMonthLabel(appState.currentAbs + appState.monthOffset)),
            IconButton(
              onPressed: () => context.read<AppState>().changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TotalCard(
            kicker: 'Total do mês',
            value: formatMoney(appState.monthlyTotal),
            meta: entries.length == 1 ? '1 parcela' : '${entries.length} parcelas',
            icon: Icons.trending_up,
            valueFontSize: 26,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionLabel(
            'Parcelas do mês',
            icon: Icons.receipt_long_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (entries.isEmpty)
            const EmptyState(message: 'Nenhuma parcela neste mês.')
          else
            for (final entry in entries) ...[
              PurchaseTile(
                purchase: entry.purchase,
                status: entry.status,
                cardName: appState.cardName(entry.purchase.cardId),
                alwaysShowPersonTag: true,
                onTap: () => showEditPurchaseDialog(context, entry.purchase),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
