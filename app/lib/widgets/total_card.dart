import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// The accent-colored "kicker + big money value + meta" card used for the
/// monthly total (Home, Monthly) and the "Guardar" result (Deposit).
///
/// [centered] switches to a compact, centered presentation (meta as a pill
/// chip) meant for a single hero result like "Guardar" — the left-aligned
/// layout used elsewhere is unchanged.
///
/// Passing [goalProgress] and [onTapGoal] additionally renders a spending
/// goal progress bar next to the value (Home only, left-aligned) — tapping
/// it opens whatever the caller wants to edit the goal with.
class TotalCard extends StatelessWidget {
  const TotalCard({
    super.key,
    required this.kicker,
    required this.value,
    this.meta,
    this.icon,
    this.valueFontSize = 30,
    this.centered = false,
    this.goalProgress,
    this.goalLabel,
    this.onTapGoal,
  });

  final String kicker;
  final String value;
  final String? meta;
  final IconData? icon;
  final double valueFontSize;
  final bool centered;

  /// Fraction of the spending goal used so far (can exceed 1). Null hides
  /// the progress bar and shows a "set a goal" prompt instead, as long as
  /// [onTapGoal] is provided.
  final double? goalProgress;

  /// Text shown above the progress bar, e.g. "Limite utilizado: 65%".
  final String? goalLabel;

  final VoidCallback? onTapGoal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(centered ? 16 : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: centered ? _buildCentered(scheme) : _buildInline(scheme),
    );
  }

  Widget _buildCentered(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: scheme.onPrimary.withValues(alpha: 0.8)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              kicker.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w800, color: scheme.onPrimary),
        ),
        if (meta != null) ...[
          const SizedBox(height: AppSpacing.xsPlus),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              meta!,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onPrimary.withValues(alpha: 0.95)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInline(ColorScheme scheme) {
    final overLimit = (goalProgress ?? 0) >= 1.0;
    final goalColor = overLimit ? AppColors.overLimitOnPrimary : scheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: scheme.onPrimary.withValues(alpha: 0.85)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              kicker.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xsPlus),
        if (goalProgress == null && onTapGoal == null)
          Text(
            value,
            style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w800, color: scheme.onPrimary),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w800, color: scheme.onPrimary),
              ),
              const Spacer(),
              InkWell(
                onTap: onTapGoal,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: goalLabel != null
                      ? Text(goalLabel!, style: TextStyle(fontSize: 12, color: goalColor))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline, size: 13, color: scheme.onPrimary.withValues(alpha: 0.85)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Definir meta',
                              style: TextStyle(fontSize: 12, color: scheme.onPrimary.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        if (goalProgress != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goalProgress!.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
              color: goalColor,
            ),
          ),
        ],
        if (meta != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            meta!,
            style: TextStyle(fontSize: 11, color: scheme.onPrimary.withValues(alpha: 0.9)),
          ),
        ],
      ],
    );
  }
}
