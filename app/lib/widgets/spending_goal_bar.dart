import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Barra da meta de gastos com a porcentagem e o quanto resta, ou o convite
/// para definir uma meta. A área inteira é tocável e abre a edição.
///
/// Feita para ficar sobre o card de destaque: [color] é o texto dele, e os
/// avisos usam os tons claros de [AppPalette.nearLimitOnHero].
class SpendingGoalBar extends StatelessWidget {
  const SpendingGoalBar({
    super.key,
    required this.progress,
    required this.label,
    required this.onTap,
    required this.color,
  });

  /// A partir desta fração da meta o aviso de limite perto aparece.
  static const nearLimitRatio = 0.8;

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
        ? palette.overLimitOnHero
        : progress >= nearLimitRatio
            ? palette.nearLimitOnHero
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
