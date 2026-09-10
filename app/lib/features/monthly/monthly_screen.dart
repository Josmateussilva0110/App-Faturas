import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_entry_dialog.dart';
import '../../widgets/purchase_tile.dart';
import '../../widgets/section_label.dart';
import '../../widgets/total_card.dart';
import '../purchase_form/edit_purchase_dialog.dart';
import 'widgets/statement_card.dart';

/// The "Meses" tab: browse any month (past or future) to see which
/// installments fall on it.
class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key});

  /// Abre o valor da fatura daquele cartão/mês. "Limpar" apaga a linha, o que
  /// devolve o card ao estado "Informar fatura".
  Future<void> _editStatement(BuildContext context, StatementCheck check) async {
    final appState = context.read<AppState>();
    final monthAbs = appState.currentAbs + appState.monthOffset;

    final result = await showAmountDialog(
      context,
      title: 'Fatura · ${check.card.name}',
      label: 'Valor da fatura em ${formatMonthLabel(monthAbs)}',
      helper: 'Registrado no app: ${formatMoney(check.registered)}',
      value: check.billed,
    );
    if (result == null || !context.mounted) return;

    final amount = result.amount;
    if (amount == null) {
      final existing = check.statement;
      if (existing == null) return;
      if (await appState.removeStatement(existing.id)) {
        AppToast.success('Fatura removida.');
      }
      return;
    }

    if (await appState.saveStatement(check.card.id, monthAbs, amount)) {
      AppToast.success('Fatura salva.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entries = appState.monthlyEntries;
    final checks = appState.monthlyStatementChecks;

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
          if (checks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionLabel(
              'Conferência da fatura',
              icon: Icons.fact_check_outlined,
              iconColor: AppColors.iconTint(
                AppColors.hueCards,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final check in checks) ...[
              StatementCard(check: check, onTap: () => _editStatement(context, check)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
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
                cardHue: appState.cardHue(entry.purchase.cardId),
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
