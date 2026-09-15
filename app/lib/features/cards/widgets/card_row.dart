import '../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/theme/app_colors.dart';
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
    required this.hue,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;

  /// Cor do cartão já resolvida — escolhida pelo usuário ou derivada do nome.
  final int hue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      accentColor: context.palette.avatarBackground(hue),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AvatarCircle(
            label: name,
            hue: hue,
            child: const Icon(Icons.credit_card, color: AppColors.avatarForeground, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            // Era um TextStyle solto repetindo o token `title` com outro
            // peso, o tipo de divergência que a escala existe para evitar.
            child: Text(name, style: context.text.title, overflow: TextOverflow.ellipsis),
          ),
          // Menores que o padrão do IconButton: são ações de apoio numa
          // linha de uma coisa só, e no tamanho cheio pesavam mais que o
          // nome do cartão. Não encolhem até virar alvo difícil, porque uma
          // das duas apaga.
          _RowAction(
            icon: Icons.edit_outlined,
            tooltip: 'Editar cartão',
            color: scheme.onSurfaceVariant,
            onPressed: onEdit,
          ),
          _RowAction(
            icon: Icons.delete_outline,
            tooltip: 'Excluir cartão',
            color: scheme.error,
            onPressed: () async {
              final confirmed = await showConfirmDeleteDialog(
                context,
                title: 'Excluir cartão?',
                message: 'Isso vai remover "$name" permanentemente.',
              );
              if (confirmed) onDelete();
            },
          ),
        ],
      ),
    );
  }
}

/// Ação de apoio numa linha de lista: ícone só, sem fundo.
///
/// 36x36 — abaixo do IconButton padrão, que num card de uma linha ocupava
/// mais altura que o conteúdo, e acima do aperto que faria o usuário errar
/// entre editar e excluir, que ficam lado a lado.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: color,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
