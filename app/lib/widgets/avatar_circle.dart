import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// Circular initial-letter avatar, colored by a hash of [label] (see
/// [TagChip] — the same hashing keeps a person's color consistent
/// everywhere they appear).
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.label,
    this.size = 32,
    this.child,
    this.hue,
  });

  final String label;
  final double size;

  /// Overrides the hash with a chosen hue (a card the user colored by hand).
  final int? hue;

  /// Overrides the initial-letter with a custom child (e.g. an icon for
  /// card avatars).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = hue ?? hueForLabel(label);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.avatarBackground(tint, dark: dark),
        shape: BoxShape.circle,
      ),
      child: child ??
          Text(
            label.isEmpty ? '?' : label.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: AppColors.avatarForeground,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.4,
            ),
          ),
    );
  }
}
