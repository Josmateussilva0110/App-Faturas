import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'app_card.dart';

/// Bloco branco com título e, se tocável, uma seta — a base dos resumos da
/// Home e da aba Meses.
class SummaryBlock extends StatelessWidget {
  const SummaryBlock({super.key, required this.title, required this.child, this.onTap});

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.mdPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.title)),
              if (onTap != null) Icon(Icons.chevron_right, size: 18, color: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
