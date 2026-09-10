import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Base surface used by every list row and grouped-content block in the app
/// (purchase rows, person rows, card rows, form sections...). Centralizing
/// it here means the radius/background/tap-ripple only need tuning once.
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
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: color ?? scheme.surfaceContainerHigh,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
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
                child: Container(width: 4, color: accentColor),
              ),
          ],
        ),
      ),
    );
  }
}
