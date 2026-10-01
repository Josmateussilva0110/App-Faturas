import '../../../core/theme/app_colors.dart';
import '../../../state/app_state.dart';

/// As três fatias do salário — Cartão, Despesas e Guardar —, usadas pela
/// tela de Depositar e pela imagem que ela compartilha, para as duas nunca
/// dividirem o salário de jeitos diferentes.
///
/// Guardar só entra quando sobra: com o mês no vermelho a barra mostra só
/// para onde o dinheiro foi, e o destaque de Guardar diz quanto falta.
List<ShareSlice> salarySplit({required double card, required double expenses, required double savings}) {
  return [
    if (card > 0) ShareSlice(name: 'Cartão', hue: AppColors.hueCards.toInt(), total: card),
    if (expenses > 0) ShareSlice(name: 'Despesas', hue: AppColors.hueExpense.toInt(), total: expenses),
    if (savings > 0) ShareSlice(name: 'Guardar', hue: AppColors.hueSavings.toInt(), total: savings),
  ];
}
