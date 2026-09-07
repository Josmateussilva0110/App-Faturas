import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/purchase_tile.dart';
import '../../widgets/section_label.dart';
import '../../widgets/total_card.dart';
import '../deposit/deposit_screen.dart';
import '../purchase_form/edit_purchase_dialog.dart';

/// The "Início" tab: this month's total, a shortcut to the deposit
/// calculator, and the list of purchases currently being paid off.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entries = appState.homeEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Center(
              child: Text(
                formatMonthLabel(appState.currentAbs).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TotalCard(
            kicker: 'Total do mês',
            value: formatMoney(appState.homeTotal),
            meta: entries.length == 1 ? '1 compra ativa' : '${entries.length} compras ativas',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DepositScreen()),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Depositar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Text(formatMoney(appState.guardar), style: const TextStyle(fontWeight: FontWeight.w800)),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Compras ativas', icon: Icons.receipt_long_outlined),
          const SizedBox(height: AppSpacing.sm),
          if (entries.isEmpty)
            const EmptyState(
              message: 'Nenhuma compra ativa este mês.',
              icon: Icons.inbox_outlined,
            )
          else
            for (final entry in entries) ...[
              PurchaseTile(
                purchase: entry.purchase,
                status: entry.status,
                cardName: appState.cardName(entry.purchase.cardId),
                onTap: () => showEditPurchaseDialog(context, entry.purchase),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
