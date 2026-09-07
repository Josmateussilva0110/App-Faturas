import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/avatar_circle.dart';
import '../../../widgets/confirm_delete_dialog.dart';

/// One row on the Cards screen: a credit-card avatar, the card's name, and
/// edit/delete buttons. Deleting asks for confirmation via
/// [showConfirmDeleteDialog].
class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
    required this.name,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      accentColor: AppColors.avatarBackground(hueForLabel(name), dark: dark),
      child: Row(
        children: [
          AvatarCircle(label: name, child: const Icon(Icons.credit_card, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18)),
          IconButton(
            onPressed: () async {
              final confirmed = await showConfirmDeleteDialog(
                context,
                title: 'Excluir cartão?',
                message: 'Isso vai remover "$name" permanentemente.',
              );
              if (confirmed) onDelete();
            },
            icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}
