import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_selector.dart';
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
      appBar: AppBar(title: const Text('Meses')),
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
              // O seletor desceu da AppBar para o corpo: é o mesmo widget que
              // Pessoas e Depositar usam, e as três telas passam a navegar entre
              // meses do mesmo jeito.
              MonthSelector(
                offset: appState.monthOffset,
                currentAbs: appState.currentAbs,
                onChanged: (value) => context.read<AppState>().setMonthOffset(value),
              ),
              const SizedBox(height: AppSpacing.lg),
              TotalCard(
                kicker: 'Total do mês',
                value: formatMoney(appState.monthlyTotal),
                meta: entries.length == 1 ? '1 parcela' : '${entries.length} parcelas',
                icon: Icons.trending_up,
              ),
              if (checks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionLabel(
                  'Conferência da fatura',
                  icon: Icons.fact_check_outlined,
                  iconColor: context.palette.iconTint(AppColors.hueCards),
                ),
                const SizedBox(height: AppSpacing.md),
                // O respiro fica *entre* os cards, não depois de cada um: com
                // um SizedBox por item, o último somava com o espaço de seção
                // e a distância até "Parcelas do mês" saía maior que as outras.
                for (var i = 0; i < checks.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  StatementCard(check: checks[i], onTap: () => _editStatement(context, checks[i])),
                ],
              ],
              const SizedBox(height: AppSpacing.xl),
              SectionLabel(
                'Parcelas do mês',
                icon: Icons.receipt_long_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              if (appState.loadError != null)
                EmptyState.error(
                  message: appState.loadError!,
                  onRetry: () => context.read<AppState>().load(),
                )
              else if (entries.isEmpty)
                const EmptyState(message: 'Nenhuma parcela neste mês.')
              else
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  PurchaseTile(
                    purchase: entries[i].purchase,
                    status: entries[i].status,
                    cardName: appState.cardName(entries[i].purchase.cardId),
                    cardHue: appState.cardHue(entries[i].purchase.cardId),
                    alwaysShowPersonTag: true,
                    onTap: () => showEditPurchaseDialog(context, entries[i].purchase),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
