import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import 'spending_goal_bar.dart';

/// The dark "kicker + big money value + meta" card used for the
/// monthly total (Home, Monthly, People) and the "Guardar" result (Deposit).
///
/// [centered] switches to a compact, centered presentation (meta as a pill
/// chip) meant for a single hero result like "Guardar". In that mode,
/// [detail] adds a small context line under the value and [negative] swaps
/// the card to the error color, so a shortfall doesn't look like a result to
/// celebrate.
///
/// In the left-aligned layout, [badge] puts a pill (the month, on Home) in
/// the top-right corner, and passing [onTapGoal] adds the spending goal
/// section under the value — a progress bar with [goalProgress] and
/// [goalLabel], or a "set a goal" prompt when there's no goal yet.
class TotalCard extends StatelessWidget {
  const TotalCard({
    super.key,
    required this.kicker,
    required this.value,
    this.meta,
    this.badge,
    this.valueFontSize = 32,
    this.centered = false,
    this.detail,
    this.negative = false,
    this.goalProgress,
    this.goalLabel,
    this.onTapGoal,
  });

  final String kicker;
  final String value;
  final String? meta;

  /// Pílula no canto superior direito (só no modo alinhado à esquerda).
  final String? badge;

  final double valueFontSize;
  final bool centered;

  /// Linha de contexto entre o valor e o mês (só no modo [centered]).
  final String? detail;

  /// Valor negativo: fundo de erro em vez da cor primária (só no modo [centered]).
  final bool negative;

  /// Fraction of the spending goal used so far (can exceed 1). Null shows a
  /// "set a goal" prompt instead of the bar, as long as [onTapGoal] is given.
  final double? goalProgress;

  /// Text under the progress bar, e.g. "Restam R$ 1.260,00 de R$ 3.600,00".
  final String? goalLabel;

  final VoidCallback? onTapGoal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = centered && negative ? scheme.error : context.palette.hero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, context.palette.heroGradientEnd(base)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.palette.shadowMedium,
      ),
      child: centered ? _buildCentered(context, scheme) : _buildInline(context, scheme),
    );
  }

  Widget _buildCentered(BuildContext context, ColorScheme scheme) {
    final fg = negative ? scheme.onError : context.palette.onHero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kicker,
              style: context.text.field.copyWith(color: fg.withValues(alpha: 0.7)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: context.text.hero.copyWith(fontSize: valueFontSize, color: fg),
        ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: context.text.caption.copyWith(color: fg.withValues(alpha: 0.9)),
          ),
        ],
        if (meta != null) ...[
          const SizedBox(height: AppSpacing.xsPlus),
          _Pill(label: meta!, color: fg),
        ],
      ],
    );
  }

  Widget _buildInline(BuildContext context, ColorScheme scheme) {
    final fg = context.palette.onHero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kicker,
                overflow: TextOverflow.ellipsis,
                style: context.text.field.copyWith(color: fg.withValues(alpha: 0.7)),
              ),
            ),
            if (badge != null) _Pill(label: badge!, color: fg),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Sozinho na linha e encolhendo só se não couber: antes dividia o
        // espaço com o rótulo da meta e era o número que perdia.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.text.hero.copyWith(fontSize: valueFontSize, color: fg),
          ),
        ),
        if (meta != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            meta!,
            style: context.text.caption.copyWith(color: fg.withValues(alpha: 0.85)),
          ),
        ],
        if (onTapGoal != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SpendingGoalBar(progress: goalProgress, label: goalLabel, onTap: onTapGoal!, color: fg),
        ],
      ],
    );
  }
}

/// Pílula translúcida sobre o card (o mês, no Início e no Guardar).
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
