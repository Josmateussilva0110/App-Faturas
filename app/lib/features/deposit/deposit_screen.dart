import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/total_card.dart';
import 'widgets/add_money_row.dart';
import 'widgets/money_list_row.dart';

/// Full-screen salary / fixed-expenses calculator: how much is left to save
/// after this month's credit card bill and expenses are paid.
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

  @override
  void dispose() {
    _salaryName.dispose();
    _salaryValue.dispose();
    _expenseName.dispose();
    _expenseValue.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.'));

  Future<void> _addSalary() async {
    final name = _salaryName.text.trim();
    final value = _parse(_salaryValue);
    if (name.isEmpty || value == null || value <= 0) return;
    await context.read<AppState>().addSalary(name, value);
    _salaryName.clear();
    _salaryValue.clear();
  }

  Future<void> _addExpense() async {
    final name = _expenseName.text.trim();
    final value = _parse(_expenseValue);
    if (name.isEmpty || value == null || value <= 0) return;
    await context.read<AppState>().addExpense(name, value);
    _expenseName.clear();
    _expenseValue.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Depositar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionLabel('Salários'),
          const SizedBox(height: AppSpacing.sm),
          for (final salary in appState.salaries) ...[
            MoneyListRow(
              name: salary.name,
              valueLabel: formatMoney(salary.value),
              onRemove: () => context.read<AppState>().removeSalary(salary.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AddMoneyRow(
            nameController: _salaryName,
            valueController: _salaryValue,
            onAdd: _addSalary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryRow(label: 'Total salários', value: formatMoney(appState.totalSalaries)),
          _SummaryRow(
            label: 'Devendo no crédito',
            value: '- ${formatMoney(appState.grandTotal)}',
            color: scheme.error,
          ),
          const Divider(height: AppSpacing.xl),
          _SummaryRow(
            label: 'Saldo após crédito',
            value: formatMoney(appState.afterCredit),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionLabel('Despesas'),
          const SizedBox(height: AppSpacing.sm),
          for (final row in appState.expenseRows) ...[
            MoneyListRow(
              name: row.expense.name,
              valueLabel: '- ${formatMoney(row.expense.value)}',
              meta: 'Saldo: ${formatMoney(row.runningBalance)}',
              onRemove: () => context.read<AppState>().removeExpense(row.expense.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AddMoneyRow(
            nameController: _expenseName,
            valueController: _expenseValue,
            onAdd: _addExpense,
          ),
          const SizedBox(height: AppSpacing.xl),
          TotalCard(kicker: 'Guardar', value: formatMoney(appState.guardar), centered: true),
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
      fontSize: emphasized ? 14 : 13,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
