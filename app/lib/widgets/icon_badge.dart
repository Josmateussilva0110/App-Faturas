import 'package:flutter/material.dart';

/// Icon inside a soft, tinted circle — the small colored badge used to lead
/// a row (e.g. the "Depositar" shortcut) instead of a bare icon.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 36, this.iconSize = 18});

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
