import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

/// Quanto sobra para guardar no mês e o que isso representa do salário.
class SavingsSummary extends StatelessWidget {
  const SavingsSummary({super.key, required this.amount, required this.rate});

  final double amount;

  /// Fração do salário; nula sem salário lançado.
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = amount < 0 ? scheme.error : context.palette.iconTint(AppColors.hueSavings);
    final rate = this.rate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(formatMoney(amount), style: context.text.money.copyWith(color: color)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          rate == null ? 'Sem salário lançado' : '${(rate * 100).round()}% do salário',
          overflow: TextOverflow.ellipsis,
          style: context.text.caption,
        ),
      ],
    );
  }
}
