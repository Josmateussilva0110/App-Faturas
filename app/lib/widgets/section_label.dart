import 'package:flutter/material.dart';

/// Small section heading, uppercase by default (e.g. "COMPRAS ATIVAS").
/// Pass [uppercase]: false for contexts that want sentence case instead
/// (e.g. "Quem comprou"). The text always stays a muted gray; pass
/// [iconColor] to tint just the icon (e.g. `AppColors.iconTint(...)`) so
/// sections read as color-coded without the label itself shouting.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon, this.uppercase = true, this.iconColor});

  final String text;
  final IconData? icon;
  final bool uppercase;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      letterSpacing: uppercase ? 0.05 : 0,
      color: textColor,
    );
    final label = uppercase ? text.toUpperCase() : text;
    if (icon == null) return Text(label, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? textColor),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}
