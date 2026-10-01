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
import '../../widgets/purchase_list_card.dart';
import '../../widgets/section_label.dart';
import '../../widgets/split_bar.dart';
import '../../widgets/summary_block.dart';
import '../purchase_form/edit_purchase_dialog.dart';
import 'widgets/month_overview_card.dart';
import 'widgets/statement_wallet.dart';

/// The "Meses" tab: browse any month (past or future) to see which
/// installments fall on it.
class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key});

  /// A curva mostra [_chartMonths] meses, com o aberto na posição
  /// [_chartBefore]: dá para ver de onde veio e para onde vai.
  static const _chartMonths = 6;

  /// Precisa ser ao menos 1: o mês anterior da comparação sai da curva.
  static const _chartBefore = 3;

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
    // A curva já calcula o mês aberto e o anterior; os totais saem dela em
    // vez de percorrer as compras de novo.
    final chart = appState.totalsFrom(appState.monthOffset - _chartBefore, _chartMonths);
    final total = chart[_chartBefore];

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
              MonthOverviewCard(
                total: total,
                previousTotal: chart[_chartBefore - 1],
                meta: entries.length == 1 ? '1 parcela' : '${entries.length} parcelas',
                chartTotals: chart,
                chartFirstMonthAbs: appState.currentAbs + appState.monthOffset - _chartBefore,
                chartHighlight: _chartBefore,
              ),
              const SizedBox(height: AppSpacing.md),
              SummaryBlock(
                title: 'Por cartão',
                child: SplitBar(
                  shares: appState.cardSharesFor(appState.monthOffset),
                  total: total,
                  fullLegend: true,
                ),
              ),
              if (checks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionLabel(
                  'Conferência da fatura',
                  icon: Icons.fact_check_outlined,
                  iconColor: context.palette.iconTint(AppColors.hueCards),
                ),
                const SizedBox(height: AppSpacing.md),
                StatementWallet(checks: checks, onTap: (check) => _editStatement(context, check)),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (appState.loadError != null)
                EmptyState.error(
                  message: appState.loadError!,
                  onRetry: () => context.read<AppState>().load(),
                )
              else
                PurchaseListCard(
                  title: 'Parcelas do mês',
                  entries: entries,
                  emptyMessage: 'Nenhuma parcela neste mês.',
                  cardName: appState.cardName,
                  cardHue: appState.cardHue,
                  alwaysShowPerson: true,
                  onTap: (purchase) => showEditPurchaseDialog(context, purchase),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
