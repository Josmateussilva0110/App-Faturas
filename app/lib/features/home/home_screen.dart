import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/card_split_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_totals_chart.dart';
import '../../widgets/purchase_list_card.dart';
import '../../widgets/spending_goal_bar.dart';
import '../../widgets/summary_block.dart';
import '../deposit/deposit_screen.dart';
import '../purchase_form/add_purchase_screen.dart';
import '../purchase_form/edit_purchase_dialog.dart';
import 'widgets/balance_card.dart';
import 'widgets/home_header.dart';
import 'widgets/spending_limit_dialog.dart';
import 'widgets/summary_tiles.dart';

/// A aba "Início": saudação, o total do mês no card escuro, resumos por
/// cartão e do que sobra, a curva dos próximos meses e as compras ativas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Quantos meses a curva mostra, contando o atual.
  static const _chartMonths = 6;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entries = appState.homeEntries;
    final goalRatio = appState.spendingGoalRatio;
    // Cada derivado do estado percorre e ordena todas as compras; calculados
    // uma vez aqui em vez de a cada uso. O total do mês é o primeiro ponto
    // da curva, que já precisa ser calculada de qualquer jeito.
    final upcoming = appState.totalsFrom(0, _chartMonths);
    final total = upcoming.first;
    final shares = appState.cardSharesFor(0);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<AppState>().load(),
          child: ListView(
            // Sem isto, uma lista curta não rola e o gesto de puxar nunca
            // dispara — justo no caso que mais precisa dele, o de a carga
            // inicial ter falhado e a tela estar vazia.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            children: [
              HomeHeader(name: appState.currentUser.name, today: DateTime.now()),
              const SizedBox(height: AppSpacing.lg),
              BalanceCard(
                value: formatMoney(total),
                meta: entries.length == 1 ? '1 compra ativa' : '${entries.length} compras ativas',
                badge: formatMonthLabel(appState.currentAbs),
                cards: shares,
                goalProgress: goalRatio,
                goalLabel: _goalLabel(goalRatio, appState.spendingGoalRemaining, appState.spendingLimit),
                onTapGoal: () => _editGoal(context, appState.spendingLimit),
                onNewPurchase: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AddPurchaseScreen()),
                ),
                onDeposit: () => _openDeposit(context),
              ),
              const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SummaryBlock(
                        title: 'Por cartão',
                        child: CardSplitBar(shares: shares, total: total),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SummaryBlock(
                        title: 'A guardar',
                        onTap: () => _openDeposit(context),
                        child: SavingsSummary(amount: appState.guardar, rate: appState.savingsRateFor(0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SummaryBlock(
                title: 'Próximos meses',
                child: MonthTotalsChart(
                  totals: upcoming,
                  firstMonthAbs: appState.currentAbs,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (appState.loadError != null)
                EmptyState.error(
                  message: appState.loadError!,
                  onRetry: () => context.read<AppState>().load(),
                )
              else
                PurchaseListCard(
                  title: 'Compras ativas',
                  entries: entries,
                  emptyMessage: 'Nenhuma compra ativa este mês.',
                  cardName: appState.cardName,
                  cardHue: appState.cardHue,
                  onTap: (purchase) => showEditPurchaseDialog(context, purchase),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDeposit(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DepositScreen()));
  }

  void _editGoal(BuildContext context, double? currentLimit) {
    showSpendingLimitDialog(
      context,
      currentLimit: currentLimit,
      onSave: (limit) async {
        try {
          await context.read<AppState>().setSpendingLimit(limit);
          AppToast.success(limit == null ? 'Meta de gastos removida.' : 'Meta de gastos definida.');
        } catch (_) {
          AppToast.error('Não foi possível salvar a meta.');
        }
      },
    );
  }
}

/// Texto sob a barra da meta: quanto resta enquanto há folga, um aviso perto
/// do limite e quanto passou depois dele.
String? _goalLabel(double? ratio, double? remaining, double? limit) {
  if (ratio == null || remaining == null || limit == null) return null;
  if (remaining < 0) return 'Passou ${formatMoney(-remaining)} do limite';
  if (remaining == 0) return 'Limite atingido';
  if (ratio >= SpendingGoalBar.nearLimitRatio) return 'Quase no limite · restam ${formatMoney(remaining)}';
  return 'Restam ${formatMoney(remaining)} de ${formatMoney(limit)}';
}
