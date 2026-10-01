import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

/// O topo de Depositar: quanto guardar no mês, em destaque no card escuro.
///
/// Era o último bloco da tela, pequeno e centralizado — a resposta que a
/// tela existe para dar só aparecia depois de rolar todas as contas.
class SavingsHero extends StatelessWidget {
  const SavingsHero({super.key, required this.amount, required this.rate});

  final double amount;

  /// Fração do salário; nula sem salário lançado.
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onHero;
    final negative = amount < 0;
    final rate = this.rate;

    final String detail;
    if (rate == null) {
      detail = 'Lance um salário para calcular';
    } else if (negative) {
      detail = 'Faltam ${formatMoney(-amount)} para fechar o mês';
    } else {
      detail = '${(rate * 100).round()}% do salário';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.hero, palette.heroGradientEnd(palette.hero)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: palette.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sem o mês aqui: o seletor logo acima já diz qual é.
          Text('Guardar', style: context.text.field.copyWith(color: fg.withValues(alpha: 0.7))),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            // Vermelho claro quando não sobra: o card é escuro nos dois
            // temas, então o tom é o mesmo do aviso de meta estourada.
            child: Text(
              formatMoney(amount),
              style: context.text.hero.copyWith(color: negative ? palette.overLimitOnHero : fg),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: context.text.caption.copyWith(
              color: negative ? palette.overLimitOnHero : fg.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
