import '../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../models/salary.dart';
import '../../state/app_state.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grouped_list_card.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/money_entry_dialog.dart';
import '../../widgets/split_bar.dart';
import '../../widgets/summary_block.dart';
import 'widgets/deposit_export_dialog.dart';
import 'widgets/money_list_row.dart';
import 'widgets/salary_split.dart';
import 'widgets/savings_hero.dart';

/// Full-screen salary / fixed-expenses calculator: how much is left to save
/// after a given month's credit card bill and expenses are paid. Salaries
/// and fixed expenses are a flat recurring budget, so only the card total
/// (and everything derived from it) changes as [_monthOffset] moves —
/// browsing months here is independent of the "Meses" tab's own offset.
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  int _monthOffset = 0;

  // Criar abre o mesmo diálogo da edição. Eram dois pares de campos sempre
  // abertos na tela, que pesavam mais que as próprias listas.
  Future<void> _addSalary() async {
    final entry = await showMoneyEntryDialog(context, title: 'Novo salário');
    if (entry == null || !mounted) return;

    await context.read<AppState>().addSalary(entry.name, entry.value);
  }

  Future<void> _addExpense() async {
    final entry = await showMoneyEntryDialog(context, title: 'Nova despesa');
    if (entry == null || !mounted) return;

    await context.read<AppState>().addExpense(entry.name, entry.value);
  }

  /// Excluir passa pela mesma confirmação de Cartões e Compras — aqui a
  /// linha sumia no toque, sem pergunta e sem aviso.
  Future<void> _removeSalary(Salary salary) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Excluir salário?',
      message: 'Isso vai remover "${salary.name}" permanentemente.',
    );
    if (!confirmed || !mounted) return;

    await context.read<AppState>().removeSalary(salary.id);
  }

  Future<void> _removeExpense(Expense expense) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Excluir despesa?',
      message: 'Isso vai remover "${expense.name}" permanentemente.',
    );
    if (!confirmed || !mounted) return;

    await context.read<AppState>().removeExpense(expense.id);
  }

  Future<void> _editSalary(Salary salary) async {
    final entry = await showMoneyEntryDialog(
      context,
      title: 'Editar salário',
      name: salary.name,
      value: salary.value,
    );
    if (entry == null || !mounted) return;

    await context.read<AppState>().updateSalary(salary.id, entry.name, entry.value);
  }

  Future<void> _editExpense(Expense expense) async {
    final entry = await showMoneyEntryDialog(
      context,
      title: 'Editar despesa',
      name: expense.name,
      value: expense.value,
    );
    if (entry == null || !mounted) return;

    await context.read<AppState>().updateExpense(expense.id, entry.name, entry.value);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final salaryColor = context.palette.iconTint(AppColors.hueSavings);
    final expenseColor = context.palette.iconTint(AppColors.hueExpense);
    final monthLabel = formatMonthLabel(appState.currentAbs + _monthOffset);

    final ownTotal = appState.ownTotalFor(_monthOffset);
    final afterCredit = appState.afterCreditFor(_monthOffset);
    final expenseRows = appState.expenseRowsFor(_monthOffset);
    final guardar = appState.guardarFor(_monthOffset);
    final savingsRate = appState.savingsRateFor(_monthOffset);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Depositar'),
        backgroundColor: scheme.surfaceContainerLow,
        actions: [
          IconButton(
            tooltip: 'Exportar resumo',
            onPressed: () => showDepositExportDialog(
              context,
              monthLabel: monthLabel,
              salaries: appState.salaries,
              totalSalaries: appState.totalSalaries,
              ownTotal: ownTotal,
              afterCredit: afterCredit,
              expenseRows: expenseRows,
              totalExpenses: appState.totalExpenses,
              guardar: guardar,
            ),
            icon: const Icon(Icons.ios_share),
          ),
        ],
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
              MonthSelector(
                offset: _monthOffset,
                currentAbs: appState.currentAbs,
                onChanged: (value) => setState(() => _monthOffset = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              SavingsHero(amount: guardar, rate: savingsRate),
              const SizedBox(height: AppSpacing.md),
              SummaryBlock(
                title: 'Para onde vai o salário',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SplitBar(
                      shares: salarySplit(card: ownTotal, expenses: appState.totalExpenses, savings: guardar),
                      total: appState.totalSalaries,
                      fullLegend: true,
                      emptyMessage: 'Lance um salário para ver a divisão.',
                    ),
                    if (appState.totalSalaries > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'De ${formatMoney(appState.totalSalaries)} de salário no mês',
                        style: context.text.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GroupedListCard(
                title: 'Salários',
                trailing: _AddButton(tooltip: 'Adicionar salário', onPressed: _addSalary),
                empty: const EmptyState(message: 'Nenhum salário lançado.', icon: Icons.payments_outlined),
                children: [
                  for (final salary in appState.salaries)
                    MoneyListRow(
                      icon: Icons.payments_outlined,
                      color: salaryColor,
                      name: salary.name,
                      valueLabel: formatMoney(salary.value),
                      onEdit: () => _editSalary(salary),
                      onRemove: () => _removeSalary(salary),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GroupedListCard(
                title: 'Despesas fixas',
                trailing: _AddButton(tooltip: 'Adicionar despesa', onPressed: _addExpense),
                empty: const EmptyState(message: 'Nenhuma despesa fixa lançada.', icon: Icons.trending_down),
                children: [
                  for (final row in expenseRows)
                    MoneyListRow(
                      icon: Icons.receipt_outlined,
                      color: expenseColor,
                      name: row.expense.name,
                      valueLabel: '- ${formatMoney(row.expense.value)}',
                      meta: 'Saldo restante: ${formatMoney(row.runningBalance)}',
                      onEdit: () => _editExpense(row.expense),
                      onRemove: () => _removeExpense(row.expense),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O "+" no título de cada lista.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.add, size: 18),
      visualDensity: VisualDensity.compact,
    );
  }
}
