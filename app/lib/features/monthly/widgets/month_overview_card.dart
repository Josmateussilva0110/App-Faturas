import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/month_totals_chart.dart';

/// O topo da aba Meses: o total do mês aberto, a comparação com o anterior e
/// a curva dos meses em volta, com o mês aberto marcado.
class MonthOverviewCard extends StatelessWidget {
  const MonthOverviewCard({
    super.key,
    required this.total,
    required this.previousTotal,
    required this.meta,
    required this.chartTotals,
    required this.chartFirstMonthAbs,
    required this.chartHighlight,
  });

  final double total;
  final double previousTotal;

  /// Linha sob a comparação, ex: "6 parcelas".
  final String meta;

  final List<double> chartTotals;
  final int chartFirstMonthAbs;
  final int chartHighlight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        children: [
          Text('Total do mês', style: context.text.field),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatMoney(total), style: context.text.hero),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Comparison(total: total, previous: previousTotal),
          const SizedBox(height: AppSpacing.xxs),
          Text(meta, style: context.text.caption),
          const SizedBox(height: AppSpacing.lg),
          MonthTotalsChart(
            totals: chartTotals,
            firstMonthAbs: chartFirstMonthAbs,
            highlightIndex: chartHighlight,
            height: 140,
          ),
        ],
      ),
    );
  }
}

/// "12% menos que o mês anterior", em verde quando caiu e vermelho quando
/// subiu — para fatura, cair é a notícia boa.
class _Comparison extends StatelessWidget {
  const _Comparison({required this.total, required this.previous});

  final double total;
  final double previous;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = context.text.caption;

    // Sem mês anterior não há base: qualquer porcentagem seria infinita.
    if (previous <= 0) {
      return Text(total > 0 ? 'Nada no mês anterior' : 'Sem parcelas', style: style);
    }

    final change = (total - previous) / previous;
    final percent = (change.abs() * 100).round();
    if (percent == 0) return Text('Igual ao mês anterior', style: style);

    final lower = change < 0;
    final color = lower ? context.palette.iconTint(AppColors.hueSavings) : scheme.error;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$percent% ', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          TextSpan(text: lower ? 'menos que o mês anterior' : 'mais que o mês anterior'),
        ],
      ),
      style: style,
    );
  }
}
