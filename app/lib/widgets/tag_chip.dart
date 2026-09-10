import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';

/// Small pill used to label a purchase's card or person, colored by a hash
/// of [label] so the same name always renders the same color.
///
/// Pass an [icon] when two chips sit side by side: hashed colors alone don't
/// say *which kind* of thing a pill is, so a card and a person read as the
/// same object until you stop and read them.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.icon, this.neutral = false});

  final String label;

  /// Small glyph before the label (e.g. a card for the card name).
  final IconData? icon;

  /// Neutral tags (e.g. the card name) use the theme's neutral surface
  /// instead of a hashed hue.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    final Color background;
    final Color foreground;
    if (neutral) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
    } else {
      final hue = hueForLabel(label);
      background = palette.tagBackground(hue);
      foreground = palette.tagForeground(hue);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: context.text.caption.copyWith(letterSpacing: 0.02, color: foreground),
          ),
        ],
      ),
    );
  }
}
