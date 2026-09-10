import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/purchase.dart';
import 'app_card.dart';
import 'tag_chip.dart';

/// One purchase row: name and amount on top, then the card and person tags
/// with the installment progress at the trailing edge. Shared by the Home
/// and Monthly screens so the row layout only exists once.
///
/// The accent strip is keyed to the *card*, not the purchase, so a bill with
/// two cards separates at a glance — and the color means something instead of
/// being a hash of the purchase name.
class PurchaseTile extends StatelessWidget {
  const PurchaseTile({
    super.key,
    required this.purchase,
    required this.status,
    required this.cardName,
    required this.cardHue,
    required this.onTap,
    this.alwaysShowPersonTag = false,
  });

  final Purchase purchase;
  final PurchaseStatus status;
  final String cardName;

  /// Cor do cartão já resolvida (ver [AppState.cardHue]).
  final int cardHue;

  final VoidCallback onTap;

  /// Home hides the "Nós" tag for the user's own purchases; Monthly always
  /// shows who the purchase belongs to.
  final bool alwaysShowPersonTag;

  @override
  Widget build(BuildContext context) {
    final showPersonTag = alwaysShowPersonTag || purchase.isOther;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.avatarBackground(cardHue, dark: dark);

    return AppCard(
      onTap: onTap,
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  purchase.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.smPlus),
              // Maior que o nome de propósito: a lista vem ordenada por
              // valor, então é ele que explica por que a linha está ali.
              Text(
                formatMoney(purchase.amount),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TagChip(label: cardName, icon: Icons.credit_card, neutral: true),
                    if (showPersonTag)
                      TagChip(label: purchase.personLabel, icon: Icons.person_outline),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _InstallmentProgress(purchase: purchase, status: status, color: accent),
            ],
          ),
        ],
      ),
    );
  }
}

/// "3 de 10" with a ring showing how much of the purchase is already paid.
///
/// A single-installment purchase has no progress to show — it reads "à vista"
/// instead of the "1/1" that used to sit there looking like a countdown.
class _InstallmentProgress extends StatelessWidget {
  const _InstallmentProgress({
    required this.purchase,
    required this.status,
    required this.color,
  });

  final Purchase purchase;
  final PurchaseStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);

    if (purchase.installments <= 1) {
      return Text('à vista', style: labelStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: status.installmentNumber / purchase.installments,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.smPlus),
        Text('${status.installmentNumber} de ${purchase.installments}', style: labelStyle),
      ],
    );
  }
}
