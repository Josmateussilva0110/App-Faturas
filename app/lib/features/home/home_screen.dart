import '../../core/theme/app_palette.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/purchase_tile.dart';
import '../../widgets/section_label.dart';
import '../../widgets/total_card.dart';
import '../deposit/deposit_screen.dart';
import '../purchase_form/edit_purchase_dialog.dart';
import 'widgets/spending_limit_dialog.dart';

/// The "Início" tab: this month's total, a shortcut to the deposit
/// calculator, and the list of purchases currently being paid off.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entries = appState.homeEntries;
    final goalRatio = appState.spendingGoalRatio;
    final savingsColor = context.palette.iconTint(AppColors.hueSavings);

    return Scaffold(
      // O mês ficava no slot `actions`, que é para ações — virou meta do
      // card, junto do que ele já contava.
      appBar: AppBar(title: const Text('Início')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().load(),
        child: ListView(
          // Sem isto, uma lista curta não rola e o gesto de puxar nunca
          // dispara — justo no caso que mais precisa dele, o de a carga
          // inicial ter falhado e a tela estar vazia.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TotalCard(
              kicker: 'Total do mês',
              value: formatMoney(appState.homeTotal),
              meta:
                  '${formatMonthLabel(appState.currentAbs)} · '
                  '${entries.length == 1 ? '1 compra ativa' : '${entries.length} compras ativas'}',
              icon: Icons.trending_up,
              goalProgress: goalRatio,
              goalLabel: goalRatio == null
                  ? null
                  : 'Limite utilizado: ${(goalRatio * 100).round()}%',
              onTapGoal: () => showSpendingLimitDialog(
                context,
                currentLimit: appState.spendingLimit,
                onSave: (limit) async {
                  try {
                    await context.read<AppState>().setSpendingLimit(limit);
                    AppToast.success(
                      limit == null ? 'Meta de gastos removida.' : 'Meta de gastos definida.',
                    );
                  } catch (_) {
                    AppToast.error('Não foi possível salvar a meta.');
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const DepositScreen())),
              child: Row(
                children: [
                  IconBadge(icon: Icons.savings_outlined, color: savingsColor),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Depositar',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Text(
                    formatMoney(appState.guardar),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionLabel(
              'Compras ativas',
              icon: Icons.receipt_long_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (appState.loadError != null)
              EmptyState.error(
                message: appState.loadError!,
                onRetry: () => context.read<AppState>().load(),
              )
            else if (entries.isEmpty)
              const EmptyState(message: 'Nenhuma compra ativa este mês.')
            else
              for (final entry in entries) ...[
                PurchaseTile(
                  purchase: entry.purchase,
                  status: entry.status,
                  cardName: appState.cardName(entry.purchase.cardId),
                  cardHue: appState.cardHue(entry.purchase.cardId),
                  onTap: () => showEditPurchaseDialog(context, entry.purchase),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}
