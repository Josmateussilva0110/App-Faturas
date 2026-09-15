import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Small section heading, em capitalização normal ("Conferência da fatura").
///
/// Já foi caixa alta por padrão. O redesign tirou: com sete telas empilhando
/// títulos gritados, a caixa alta deixava de destacar e virava ruído — e ela
/// lê mais devagar que a frase normal. O texto sempre fica num cinza apagado;
/// passe [iconColor] para tingir só o ícone, e a seção lê como codificada por
/// cor sem o rótulo brigar por atenção.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon, this.iconColor});

  final String text;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = context.text.label.copyWith(color: textColor);
    if (icon == null) return Text(text, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? textColor),
        const SizedBox(width: AppSpacing.xsPlus),
        Text(text, style: style),
      ],
    );
  }
}
