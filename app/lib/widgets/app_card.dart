import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';

/// Base surface used by every list row and grouped-content block in the app
/// (purchase rows, person rows, card rows, form sections...). Centralizing
/// it here means the radius/background/tap-ripple only need tuning once.
///
/// O card é branco com uma borda discreta, não um cinza mais escuro que a
/// página: o contraste vem da borda, e não de empilhar tons de cinza. Sem
/// sombra de propósito — separação sutil lê como profundidade, sombra forte
/// lê como um card flutuando, e são dezenas deles numa lista.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.accentColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  /// Thin colored strip along the card's leading edge, used to give list
  /// rows (purchases, cards, people) a quick visual identity that matches
  /// their avatar's hue. Omit for plain, uncategorized cards.
  ///
  /// Estreita — 3px. A faixa carrega significado (é a cor do cartão, então
  /// uma fatura com dois cartões separa num relance), mas larga demais ela
  /// pesava mais que o valor da compra, que é o dado principal da linha.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: color ?? palette.softSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: palette.softBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: accentColor != null ? padding.add(const EdgeInsets.only(left: AppSpacing.xs)) : padding,
              child: child,
            ),
            if (accentColor != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: accentColor),
              ),
          ],
        ),
      ),
    );
  }
}
