import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';

/// Base surface used by every list row and grouped-content block in the app
/// (purchase rows, person rows, card rows, form sections...). Centralizing
/// it here means the radius/background/tap-ripple only need tuning once.
///
/// O card é branco sobre a página cinza-clara, sem borda: o degrau de tom já
/// separa. No escuro esse degrau é pequeno demais, então lá volta a borda.
/// Sem sombra de propósito — sombra forte lê como um card flutuando, e são
/// dezenas deles numa lista.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: color ?? palette.softSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: palette.dark ? BorderSide(color: palette.softBorder) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
