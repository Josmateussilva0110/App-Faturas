import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';

/// Curva do total da fatura mês a mês, com o nome do mês no eixo.
///
/// A Home usa para os próximos meses; Meses, para os que levam até o mês
/// aberto — e aí [highlightIndex] marca com um ponto qual deles é.
class MonthTotalsChart extends StatelessWidget {
  const MonthTotalsChart({
    super.key,
    required this.totals,
    required this.firstMonthAbs,
    this.highlightIndex,
    this.height = 150,
  });

  final List<double> totals;

  /// Mês absoluto do primeiro ponto (ver [absoluteMonth]).
  final int firstMonthAbs;

  /// Ponto destacado na curva; nulo para nenhum.
  final int? highlightIndex;

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = context.palette.iconTint(AppColors.hueExpense);
    final muted = scheme.onSurfaceVariant;
    final top = totals.fold<double>(0, math.max);
    // Folga no topo para a curva não encostar na borda; e um piso para o
    // gráfico não ficar sem escala quando tudo é zero.
    final maxY = top <= 0 ? 1.0 : top * 1.2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: (totals.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 26,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: AppSpacing.sm,
                  child: Text(
                    formatMonthShort(firstMonthAbs + value.toInt()),
                    style: context.text.caption.copyWith(color: muted),
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.palette.hero,
              tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    formatMoney(spot.y),
                    context.text.caption.copyWith(color: context.palette.onHero, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < totals.length; i++) FlSpot(i.toDouble(), totals[i])],
              isCurved: true,
              preventCurveOverShooting: true,
              color: line,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: highlightIndex != null,
                checkToShowDot: (spot, _) => spot.x.toInt() == highlightIndex,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: line,
                  strokeWidth: 2.5,
                  strokeColor: scheme.surfaceContainerHigh,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [line.withValues(alpha: 0.22), line.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
