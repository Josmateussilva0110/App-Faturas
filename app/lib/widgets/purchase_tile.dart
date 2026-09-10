import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/purchase.dart';
import 'app_card.dart';
import 'avatar_circle.dart';
import 'tag_chip.dart';

/// One purchase row: name, card tag, person tag (unless it's the user's own
/// on the Home screen), installment progress and the amount. Shared by the
/// Home and Monthly screens so the row layout only exists once.
class PurchaseTile extends StatelessWidget {
  const PurchaseTile({
    super.key,
    required this.purchase,
    required this.status,
    required this.cardName,
    required this.onTap,
    this.alwaysShowPersonTag = false,
  });

  final Purchase purchase;
  final PurchaseStatus status;
  final String cardName;
  final VoidCallback onTap;

  /// Home hides the "Nós" tag for the user's own purchases; Monthly always
  /// shows who the purchase belongs to.
  final bool alwaysShowPersonTag;

  @override
  Widget build(BuildContext context) {
    final showPersonTag = alwaysShowPersonTag || purchase.isOther;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = hueForLabel(purchase.name);

    return AppCard(
      onTap: onTap,
      accentColor: AppColors.avatarBackground(hue, dark: dark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarCircle(label: purchase.name, child: const Icon(Icons.shopping_bag_outlined, color: AppColors.avatarForeground, size: 16)),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        purchase.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.smPlus),
                    Text(
                      formatMoney(purchase.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xsPlus),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TagChip(label: cardName, neutral: true),
                    if (showPersonTag) TagChip(label: purchase.personLabel),
                    Text(
                      'Parcela ${status.installmentNumber}/${purchase.installments}',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
