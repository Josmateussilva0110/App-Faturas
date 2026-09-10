import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_label.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pillFill = AppColors.softSurface(scheme, dark: dark);
    final pillBorder = AppColors.softBorder(scheme, dark: dark);
    final monthLabel = formatMonthLabel(appState.currentAbs + _monthOffset);

    return Scaffold(
      appBar: AppBar(title: const Text('Por pessoa')),
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
          SectionLabel(
            'Gastos por pessoa',
            icon: Icons.people_outline,
            iconColor: AppColors.iconTint(AppColors.huePeople, dark: dark),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (people.isEmpty)
            const EmptyState(message: 'Nenhuma compra ativa neste mês.')
          else
            for (final person in people) ...[
              PersonRow(
                label: person.label,
                total: person.total,
                onShare: () => showShareBillDialog(
                  context,
                  label: person.label,
                  rows: appState.transactionsForPersonFor(_monthOffset, person.label),
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
                    Icon(Icons.swap_vert, size: 16, color: scheme.primary),
                    const SizedBox(width: AppSpacing.xsPlus),
                    const Text('Total geral', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                Text(
                  formatMoney(appState.totalFor(_monthOffset)),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
