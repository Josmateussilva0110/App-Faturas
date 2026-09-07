import 'package:flutter/material.dart';

/// Small uppercase section heading, e.g. "COMPRAS ATIVAS".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      letterSpacing: 0.05,
      color: color,
    );
    if (icon == null) return Text(text.toUpperCase(), style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text.toUpperCase(), style: style),
      ],
    );
  }
}
