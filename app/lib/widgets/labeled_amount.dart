import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Rótulo pequeno em cima, valor embaixo.
///
/// É o bloco que a conferência da fatura (Meses) e o resumo do Depositar
/// usam para apresentar um número com o nome dele. Vive aqui, e não numa das
/// duas telas, porque as duas precisam ler igual — foi o pedido explícito de
/// manter a mesma identidade entre elas.
///
/// Não embrulha em [Expanded] por conta própria: aparece tanto dentro de uma
/// `Row` (onde dividir a largura faz sentido) quanto solto numa `Column`
/// (onde flex vertical sem altura limitada quebra o layout). Quem sabe qual
/// é o caso é o chamador.
class LabeledAmount extends StatelessWidget {
  const LabeledAmount({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;

  /// Tinge o valor. O rótulo fica sempre apagado, para a cor significar
  /// alguma coisa sobre o número em vez de decorar a linha inteira.
  final Color? color;

  /// O resultado de um bloco — o saldo que fecha o resumo. Sobe o valor de
  /// tamanho para ele ganhar do que vem acima sem precisar de outra cor.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.caption),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: (emphasized ? text.money : text.body).copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
