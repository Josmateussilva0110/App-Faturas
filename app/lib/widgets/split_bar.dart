import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';
import '../state/app_state.dart';

/// Uma barra em fatias, cada uma na sua cor, com a legenda embaixo: quanto
/// cada cartão pesa no mês, ou para onde vai o salário.
///
/// Com [fullLegend] a legenda lista todas as fatias com o valor; sem ela,
/// só a maior e a porcentagem — o que cabe num bloco de meia largura.
class SplitBar extends StatelessWidget {
  const SplitBar({
    super.key,
    required this.shares,
    required this.total,
    this.fullLegend = false,
    this.emptyMessage = 'Nada lançado neste mês.',
  });

  final List<ShareSlice> shares;
  final double total;
  final bool fullLegend;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (shares.isEmpty || total <= 0) {
      return Text(emptyMessage, style: context.text.caption);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: fullLegend ? 12 : 8,
            child: Row(
              // Sem stretch as fatias, que não têm filho, ficam com altura zero.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < shares.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    // Fatia mínima de 1: um cartão com poucos centavos ainda
                    // aparece, em vez de sumir da barra.
                    flex: (shares[i].total / total * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: palette.avatarBackground(shares[i].hue)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.smPlus),
        if (fullLegend)
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              for (final share in shares)
                _LegendItem(share: share, text: '${share.name} · ${formatMoney(share.total)}'),
            ],
          )
        else
          _LegendItem(
            share: shares.first,
            text: '${shares.first.name} · ${(shares.first.total / total * 100).round()}%',
            expand: true,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.share, required this.text, this.expand = false});

  final ShareSlice share;
  final String text;

  /// Ocupa a largura toda e corta com reticências, para o bloco estreito.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final label = Text(text, overflow: TextOverflow.ellipsis, style: context.text.caption);

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: context.palette.avatarBackground(share.hue),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xsPlus),
        if (expand) Expanded(child: label) else label,
      ],
    );
  }
}
