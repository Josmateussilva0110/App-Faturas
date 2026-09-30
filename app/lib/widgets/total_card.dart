import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

/// The accent-colored "kicker + big money value + meta" card used for the
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
    this.icon,
    this.valueFontSize = 28,
    this.centered = false,
    this.detail,
    this.negative = false,
    this.goalProgress,
    this.goalLabel,
    this.onTapGoal,
  });

  /// A partir desta fração da meta o card avisa que o limite está perto.
  static const nearLimitRatio = 0.8;

  final String kicker;
  final String value;
  final String? meta;

  /// Pílula no canto superior direito (só no modo alinhado à esquerda).
  final String? badge;

  final IconData? icon;
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
    final base = centered && negative ? scheme.error : scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, context.palette.heroGradientEnd(base)],
        ),
        borderRadius: BorderRadius.circular(centered ? AppRadius.lg : AppRadius.md),
        boxShadow: context.palette.shadowMedium,
      ),
      child: centered ? _buildCentered(context, scheme) : _buildInline(context, scheme),
    );
  }

  Widget _buildCentered(BuildContext context, ColorScheme scheme) {
    final fg = negative ? scheme.onError : scheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg.withValues(alpha: 0.8)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              kicker.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: fg.withValues(alpha: 0.8),
              ),
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
    final fg = scheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg.withValues(alpha: 0.85)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                kicker.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w700,
                  color: fg.withValues(alpha: 0.85),
                ),
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
          _GoalSection(progress: goalProgress, label: goalLabel, onTap: onTapGoal!, color: fg),
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

/// Barra da meta de gastos com a porcentagem e o quanto resta, ou o convite
/// para definir uma meta. A área inteira é tocável e abre a edição.
class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.progress,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final double? progress;
  final String? label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: progress == null ? _prompt(context) : _bar(context, progress),
      ),
    );
  }

  Widget _prompt(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.add_circle_outline, size: 15, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Definir meta de gastos',
          style: context.text.field.copyWith(color: color.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, double progress) {
    final palette = context.palette;
    // Branco enquanto está folgado; âmbar perto do limite; vermelho depois.
    final tone = progress >= 1
        ? palette.overLimitOnPrimary
        : progress >= TotalCard.nearLimitRatio
            ? palette.nearLimitOnPrimary
            : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.25),
                  color: tone,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${(progress * 100).round()}%',
              style: context.text.field.copyWith(color: tone, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.xsPlus),
          Row(
            children: [
              Expanded(
                child: Text(
                  label!,
                  style: context.text.caption.copyWith(
                    color: tone == color ? color.withValues(alpha: 0.9) : tone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.edit_outlined, size: 14, color: color.withValues(alpha: 0.8)),
            ],
          ),
        ],
      ],
    );
  }
}
