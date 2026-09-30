import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'app_card.dart';
import 'empty_state.dart';

/// Um bloco só com título e várias linhas dentro, como um extrato — em vez
/// de um card por item. As linhas cuidam do próprio recuo lateral
/// ([GroupedListCard.rowPadding]) para o toque cobrir a largura toda.
class GroupedListCard extends StatelessWidget {
  const GroupedListCard({
    super.key,
    required this.title,
    required this.children,
    this.empty,
    this.trailing,
  });

  /// Recuo das linhas, alinhado com o título.
  static const rowPadding = EdgeInsets.symmetric(horizontal: AppSpacing.mdPlus, vertical: AppSpacing.smPlus);

  final String title;
  final List<Widget> children;

  /// Mostrado no lugar das linhas quando [children] está vazio.
  final EmptyState? empty;

  /// Ao lado do título, ex: um total.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.mdPlus, AppSpacing.xsPlus, AppSpacing.mdPlus, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(title, style: context.text.title)),
                ?trailing,
              ],
            ),
          ),
          // Largura cheia: a coluna alinha pelo início, e sem isto a mensagem
          // de vazio encolhia para o canto esquerdo em vez de centralizar.
          if (children.isEmpty && empty != null)
            SizedBox(width: double.infinity, child: empty)
          else
            ...children,
        ],
      ),
    );
  }
}
