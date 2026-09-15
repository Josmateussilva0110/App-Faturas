import '../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../models/salary.dart';
import '../../state/app_state.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/form_section_card.dart';
import '../../widgets/labeled_amount.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/money_entry_dialog.dart';
import '../../widgets/section_label.dart';
import '../../widgets/total_card.dart';
import 'widgets/add_money_row.dart';
import 'widgets/deposit_export_dialog.dart';
import 'widgets/money_list_row.dart';

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
  final _salaryName = TextEditingController();
  final _salaryValue = TextEditingController();
  final _expenseName = TextEditingController();
  final _expenseValue = TextEditingController();

  int _monthOffset = 0;

  @override
  void dispose() {
    _salaryName.dispose();
    _salaryValue.dispose();
    _expenseName.dispose();
    _expenseValue.dispose();
    super.dispose();
  }

  Future<void> _addSalary() async {
    final name = _salaryName.text.trim();
    final value = parseMoney(_salaryValue.text);
    if (name.isEmpty || value == null) {
      // Antes o clique simplesmente não fazia nada. Agora que adicionar é
      // uma chamada de rede, silêncio é indistinguível de falha de conexão.
      AppToast.error('Informe um nome e um valor maior que zero.');
      return;
    }

    await context.read<AppState>().addSalary(name, value);
    if (!mounted) return;

    _salaryName.clear();
    _salaryValue.clear();
  }

  Future<void> _addExpense() async {
    final name = _expenseName.text.trim();
    final value = parseMoney(_expenseValue.text);
    if (name.isEmpty || value == null) {
      AppToast.error('Informe um nome e um valor maior que zero.');
      return;
    }

    await context.read<AppState>().addExpense(name, value);
    if (!mounted) return;

    _expenseName.clear();
    _expenseValue.clear();
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
              FormSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionLabel('Salários', icon: Icons.payments_outlined, iconColor: salaryColor),
                    const SizedBox(height: AppSpacing.sm),
                    if (appState.salaries.isEmpty)
                      const EmptyState(
                        message: 'Nenhum salário lançado.',
                        icon: Icons.payments_outlined,
                      )
                    else
                      // Divisor entre as linhas, não espaço: sem o fundo
                      // cinza que elas tinham, é a régua que diz onde uma
                      // acaba e a outra começa.
                      for (var i = 0; i < appState.salaries.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        MoneyListRow(
                          name: appState.salaries[i].name,
                          valueLabel: formatMoney(appState.salaries[i].value),
                          onEdit: () => _editSalary(appState.salaries[i]),
                          onRemove: () => _removeSalary(appState.salaries[i]),
                        ),
                      ],
                    const SizedBox(height: AppSpacing.md),
                    AddMoneyRow(
                      nameController: _salaryName,
                      valueController: _salaryValue,
                      onAdd: _addSalary,
                      accentColor: salaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionLabel('Resumo', icon: Icons.calculate_outlined, iconColor: scheme.primary),
                    const SizedBox(height: AppSpacing.lg),
                    // Empilhado, e não rótulo à esquerda com valor à direita:
                    // é o mesmo bloco do card de conferência da tela Meses,
                    // então as duas telas apresentam número do mesmo jeito.
                    LabeledAmount(
                      label: 'Total de salários',
                      value: formatMoney(appState.totalSalaries),
                      color: salaryColor,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LabeledAmount(
                      label: 'Crédito no cartão',
                      value: '- ${formatMoney(ownTotal)}',
                      color: scheme.error,
                    ),
                    const Divider(height: AppSpacing.xl),
                    LabeledAmount(
                      label: 'Saldo após o cartão',
                      value: formatMoney(afterCredit),
                      // Verde quando sobra, vermelho quando falta: a cor diz
                      // o sinal do número, que é o que se quer saber aqui.
                      color: afterCredit < 0 ? scheme.error : salaryColor,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionLabel('Despesas', icon: Icons.trending_down, iconColor: expenseColor),
                    const SizedBox(height: AppSpacing.sm),
                    if (expenseRows.isEmpty)
                      const EmptyState(
                        message: 'Nenhuma despesa fixa lançada.',
                        icon: Icons.trending_down,
                      )
                    else
                      for (var i = 0; i < expenseRows.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        MoneyListRow(
                          name: expenseRows[i].expense.name,
                          valueLabel: '- ${formatMoney(expenseRows[i].expense.value)}',
                          meta: 'Saldo restante: ${formatMoney(expenseRows[i].runningBalance)}',
                          onEdit: () => _editExpense(expenseRows[i].expense),
                          onRemove: () => _removeExpense(expenseRows[i].expense),
                        ),
                      ],
                    const SizedBox(height: AppSpacing.md),
                    AddMoneyRow(
                      nameController: _expenseName,
                      valueController: _expenseValue,
                      onAdd: _addExpense,
                      accentColor: expenseColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: TotalCard(
                    kicker: 'Guardar',
                    value: formatMoney(guardar),
                    meta: monthLabel,
                    icon: Icons.savings_outlined,
                    valueFontSize: 22,
                    centered: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
