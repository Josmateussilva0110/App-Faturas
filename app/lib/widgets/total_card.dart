import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// The accent-colored "kicker + big money value + meta" card used for the
/// monthly total (Home, Monthly) and the "Guardar" result (Deposit).
class TotalCard extends StatelessWidget {
  const TotalCard({
    super.key,
    required this.kicker,
    required this.value,
    this.meta,
    this.icon,
    this.valueFontSize = 30,
    this.centered = false,
  });

  final String kicker;
  final String value;
  final String? meta;
  final IconData? icon;
  final double valueFontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: scheme.onPrimary.withValues(alpha: 0.85)),
                const SizedBox(width: 5),
              ],
              Text(
                kicker.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.1,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimary,
            ),
          ),
          if (meta != null) ...[
            const SizedBox(height: 4),
            Text(
              meta!,
              style: TextStyle(fontSize: 11, color: scheme.onPrimary.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }
}
