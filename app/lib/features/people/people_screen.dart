import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../share/share_bill_dialog.dart';
import 'widgets/person_row.dart';

/// The "Pessoas" tab: this month's total broken down by who it belongs to,
/// each shareable as a formatted bill via [showShareBillDialog].
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final people = appState.personSummaries;

    return Scaffold(
      appBar: AppBar(title: const Text('Por pessoa')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (people.isEmpty)
            const EmptyState(message: 'Nenhuma compra ativa este mês.')
          else
            for (final person in people) ...[
              PersonRow(
                label: person.label,
                total: person.total,
                onShare: () => showShareBillDialog(
                  context,
                  label: person.label,
                  rows: appState.transactionsForPerson(person.label),
                  subtotal: person.total,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const Divider(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text('Total geral', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                Text(
                  formatMoney(appState.grandTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
