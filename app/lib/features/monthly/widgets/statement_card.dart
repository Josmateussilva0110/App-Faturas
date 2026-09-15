import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/app_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/labeled_amount.dart';

/// One card's bill reconciliation: what the bank charges, what the app has
/// registered, and how far apart they are.
///
/// The four states differ in color, icon and the sentence under the numbers —
/// the sentence is the part that says what to *do*, which a color alone
/// can't. Note that [StatementStatus.extra] is informational blue rather than
/// an error: mid-month, a bill that hasn't closed yet is the normal case.
///
/// Os três números já foram uma linha só de colunas iguais. A diferença é a
/// resposta da tela — "confere ou não?" — e lado a lado com os outros dois
/// ela lia como mais um dado. Agora "Fatura" e "Registrado" dividem a linha,
/// que é a comparação, e a diferença fica sozinha embaixo, que é a conclusão.
class StatementCard extends StatelessWidget {
  const StatementCard({super.key, required this.check, required this.onTap});

  final StatementCheck check;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final style = _StatementStyle.of(check.status, scheme: scheme, palette: palette);
    final difference = check.difference;
    final detail = style.detail(check);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 18, color: style.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  check.card.name,
                  style: context.text.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(label: style.label, color: style.color, dark: palette.dark),
            ],
          ),
          if (check.progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: check.progress!.clamp(0.0, 1.0).toDouble(),
                minHeight: 5,
                backgroundColor: style.color.withValues(alpha: 0.16),
                color: style.color,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: LabeledAmount(
                  label: 'Fatura',
                  value: check.billed == null ? '—' : formatMoney(check.billed!),
                ),
              ),
              Expanded(
                child: LabeledAmount(label: 'Registrado', value: formatMoney(check.registered)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LabeledAmount(
            label: 'Diferença',
            value: difference == null ? '—' : _signed(difference),
            // A cor é o que destaca a diferença; o tamanho fica igual ao dos
            // outros dois, senão ela grita mais alto que o valor da fatura.
            color: difference == null ? null : style.color,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: 13, color: style.color),
              const SizedBox(width: AppSpacing.xsPlus),
              Expanded(child: Text(style.hint(check), style: context.text.field)),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(detail, style: context.text.caption),
          ],
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
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String label;

  /// A frase curta: o que aconteceu.
  final String Function(StatementCheck check) hint;

  /// A explicação, quando existe — segunda linha, menor. Separada do [hint]
  /// porque juntas viravam um bloco de texto que ninguém lia até o fim.
  final String? Function(StatementCheck check) detail;

  factory _StatementStyle.of(
    StatementStatus status, {
    required ColorScheme scheme,
    required AppPalette palette,
  }) {
    switch (status) {
      case StatementStatus.matched:
        return _StatementStyle(
          icon: Icons.check_circle_outline,
          color: palette.iconTint(AppColors.hueSavings),
          label: 'Confere',
          hint: (check) {
            final diff = check.difference ?? 0;
            if (diff.abs() < 0.005) return 'Bateu exatamente com a fatura.';
            return 'Dentro da tolerância de ${formatMoney(kStatementTolerance)}';
          },
          detail: (check) {
            final diff = check.difference ?? 0;
            if (diff.abs() < 0.005) return null;
            return 'Diferença causada pelo arredondamento do banco.';
          },
        );
      case StatementStatus.missing:
        return _StatementStyle(
          icon: Icons.error_outline,
          color: palette.iconTint(AppColors.hueWarning),
          label: 'Falta lançar',
          hint: (check) =>
              'Faltam ${formatMoney(check.difference!.abs())} em compras para lançar no app.',
          detail: (_) => null,
        );
      case StatementStatus.extra:
        return _StatementStyle(
          icon: Icons.info_outline,
          color: scheme.primary,
          label: 'Registrado a mais',
          hint: (check) => '${formatMoney(check.difference!.abs())} a mais que a fatura.',
          detail: (_) => 'Ela pode não ter fechado, ou há compra repetida.',
        );
      case StatementStatus.unset:
        return _StatementStyle(
          icon: Icons.receipt_long_outlined,
          color: scheme.onSurfaceVariant,
          label: 'Informar fatura',
          hint: (check) => 'Toque para informar o valor da fatura e conferir.',
          detail: (_) => null,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smPlus, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.caption.copyWith(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
