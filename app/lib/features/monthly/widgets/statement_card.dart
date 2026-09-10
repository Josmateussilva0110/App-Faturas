import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/app_state.dart';
import '../../../widgets/app_card.dart';

/// One card's bill reconciliation: what the bank charges, what the app has
/// registered, and how far apart they are.
///
/// The four states differ in color, icon and the sentence under the numbers —
/// the sentence is the part that says what to *do*, which a color alone
/// can't. Note that [StatementStatus.extra] is informational blue rather than
/// an error: mid-month, a bill that hasn't closed yet is the normal case.
class StatementCard extends StatelessWidget {
  const StatementCard({super.key, required this.check, required this.onTap});

  final StatementCheck check;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = _StatementStyle.of(check.status, scheme: scheme, dark: dark);
    final difference = check.difference;

    return AppCard(
      color: AppColors.softSurface(scheme, dark: dark),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 20, color: style.color),
              const SizedBox(width: AppSpacing.smPlus),
              Expanded(
                child: Text(
                  check.card.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(label: style.label, color: style.color, dark: dark),
            ],
          ),
          if (check.progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: check.progress!.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                backgroundColor: style.color.withValues(alpha: 0.18),
                color: style.color,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Figure(
                label: 'Fatura atual',
                value: check.billed == null ? '—' : formatMoney(check.billed!),
              ),
              _Figure(label: 'Registrado', value: formatMoney(check.registered)),
              _Figure(
                label: 'Diferença',
                value: difference == null ? '—' : _signed(difference),
                color: difference == null ? null : style.color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smPlus),
          Text(
            style.hint(check),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Sinal explícito: sem ele, "R$ 235,00" não diz se sobra ou falta.
  static String _signed(double value) {
    final money = formatMoney(value.abs());
    if (value == 0) return money;
    return value > 0 ? '+ $money' : '- $money';
  }
}

class _StatementStyle {
  const _StatementStyle({
    required this.icon,
    required this.color,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String Function(StatementCheck check) hint;

  factory _StatementStyle.of(
    StatementStatus status, {
    required ColorScheme scheme,
    required bool dark,
  }) {
    switch (status) {
      case StatementStatus.matched:
        return _StatementStyle(
          icon: Icons.check_circle_outline,
          color: AppColors.iconTint(AppColors.hueSavings, dark: dark),
          label: 'Confere',
          hint: (check) {
            final diff = check.difference ?? 0;
            if (diff.abs() < 0.005) return 'Bateu exatamente com a fatura.';
            return 'Dentro da tolerância de ${formatMoney(kStatementTolerance)} — '
                'arredondamento do banco.';
          },
        );
      case StatementStatus.missing:
        return _StatementStyle(
          icon: Icons.error_outline,
          color: AppColors.iconTint(AppColors.hueWarning, dark: dark),
          label: 'Falta lançar',
          hint: (check) =>
              'Faltam ${formatMoney(check.difference!.abs())} em compras para lançar no app.',
        );
      case StatementStatus.extra:
        return _StatementStyle(
          icon: Icons.info_outline,
          color: scheme.primary,
          label: 'Registrado a mais',
          hint: (check) =>
              '${formatMoney(check.difference!.abs())} a mais que a fatura. '
              'Ela pode não ter fechado, ou há compra repetida.',
        );
      case StatementStatus.unset:
        return _StatementStyle(
          icon: Icons.receipt_long_outlined,
          color: scheme.onSurfaceVariant,
          label: 'Informar fatura',
          hint: (check) => 'Toque para informar o valor da fatura e conferir.',
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, required this.dark});

  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
