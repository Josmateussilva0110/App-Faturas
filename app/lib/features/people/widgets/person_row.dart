import '../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/avatar_circle.dart';

/// One row on the People screen: avatar, name, total, and a share button.
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.label,
    required this.total,
    required this.onShare,
  });

  final String label;
  final double total;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: context.palette.avatarBackground(hueForLabel(label)),
      child: Row(
        children: [
          AvatarCircle(label: label),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Text(label, style: context.text.title),
          ),
          Text(formatMoney(total), style: context.text.title),
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 18),
            tooltip: 'Compartilhar',
          ),
        ],
      ),
    );
  }
}
