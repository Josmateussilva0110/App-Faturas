import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/grouped_list_card.dart';
import '../../widgets/total_card.dart';
import '../share/share_bill_dialog.dart';
import 'widgets/person_row.dart';

/// The "Pessoas" tab: a given month's total broken down by who it belongs
/// to, each shareable as a formatted bill via [showShareBillDialog]. Month
/// browsing here is local to this screen, same as the Deposit screen —
/// independent of the "Meses" tab's own offset.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final people = appState.personSummariesFor(_monthOffset);
    final total = appState.totalFor(_monthOffset);

    return Scaffold(
      appBar: AppBar(title: const Text('Pessoas')),
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
              TotalCard(
                kicker: 'Total do mês',
                value: formatMoney(total),
                meta: people.length == 1 ? '1 pessoa' : '${people.length} pessoas',
              ),
              const SizedBox(height: AppSpacing.md),
              if (appState.loadError != null)
                EmptyState.error(
                  message: appState.loadError!,
                  onRetry: () => context.read<AppState>().load(),
                )
              else
                GroupedListCard(
                  title: 'Gastos por pessoa',
                  empty: const EmptyState(message: 'Nenhuma compra ativa neste mês.'),
                  children: [
                    for (final person in people)
                      PersonRow(
                        label: person.label,
                        total: person.total,
                        share: total > 0 ? person.total / total : 0,
                        onShare: () => showShareBillDialog(
                          context,
                          label: person.label,
                          monthAbs: appState.currentAbs + _monthOffset,
                          rows: appState.transactionsForPersonFor(_monthOffset, person.label),
                          subtotal: person.total,
                        ),
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
