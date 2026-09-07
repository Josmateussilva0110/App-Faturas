import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// Small pill used to label a purchase's card or person, colored by a hash
/// of [label] so the same name always renders the same color.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.neutral = false});

  final String label;

  /// Neutral tags (e.g. the card name) use the theme's neutral surface
  /// instead of a hashed hue.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final Color background;
    final Color foreground;
    if (neutral) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
    } else {
      final hue = hueForLabel(label);
      background = AppColors.tagBackground(hue, dark: dark);
      foreground = AppColors.tagForeground(hue, dark: dark);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, letterSpacing: 0.02, color: foreground),
      ),
    );
  }
}
