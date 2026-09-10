import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../models/salary.dart';
import '../../state/app_state.dart';
import '../../widgets/form_section_card.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final salaryColor = AppColors.iconTint(AppColors.hueSavings, dark: dark);
    final expenseColor = AppColors.iconTint(AppColors.hueExpense, dark: dark);
    final pillFill = AppColors.softSurface(scheme, dark: dark);
    final pillBorder = AppColors.softBorder(scheme, dark: dark);
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: pillFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: pillBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _monthOffset -= 1),
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          monthLabel,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _monthOffset += 1),
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                if (_monthOffset != 0)
                  TextButton(
                    onPressed: () => setState(() => _monthOffset = 0),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Hoje', style: TextStyle(fontSize: 12)),
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
                SectionLabel('Salários', icon: Icons.payments_outlined, iconColor: salaryColor),
                const SizedBox(height: AppSpacing.md),
                for (final salary in appState.salaries) ...[
                  MoneyListRow(
                    name: salary.name,
                    valueLabel: formatMoney(salary.value),
                    onEdit: () => _editSalary(salary),
                    onRemove: () => context.read<AppState>().removeSalary(salary.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
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
                const SizedBox(height: AppSpacing.md),
                _SummaryRow(label: 'Total salários', value: formatMoney(appState.totalSalaries), color: salaryColor),
                _SummaryRow(
                  label: 'Meu crédito no cartão',
                  value: '- ${formatMoney(ownTotal)}',
                  color: scheme.error,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  label: 'Saldo após crédito',
                  value: formatMoney(afterCredit),
                  color: scheme.primary,
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
                const SizedBox(height: AppSpacing.md),
                for (final row in expenseRows) ...[
                  MoneyListRow(
                    name: row.expense.name,
                    valueLabel: '- ${formatMoney(row.expense.value)}',
                    meta: 'Saldo: ${formatMoney(row.runningBalance)}',
                    onEdit: () => _editExpense(row.expense),
                    onRemove: () => context.read<AppState>().removeExpense(row.expense.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 15 : 13,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: emphasized ? 14 : 13, color: color)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
