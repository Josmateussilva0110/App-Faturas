import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/app_state.dart';
import '../../../widgets/spending_goal_bar.dart';

/// O card escuro da Home: os cartões do mês aparecendo por trás, o total, a
/// meta de gastos e as duas ações principais.
///
/// O olho esconde o valor — estado só de tela, por isso mora aqui e não no
/// [AppState].
class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.value,
    required this.meta,
    required this.badge,
    required this.cards,
    required this.goalProgress,
    required this.goalLabel,
    required this.onTapGoal,
    required this.onNewPurchase,
    required this.onDeposit,
  });

  final String value;
  final String meta;
  final String badge;

  /// Cartões que aparecem por trás, do maior para o menor. Só os dois
  /// primeiros são desenhados: mais que isso vira uma pilha ilegível.
  final List<CardShare> cards;

  final double? goalProgress;
  final String? goalLabel;
  final VoidCallback onTapGoal;
  final VoidCallback onNewPurchase;
  final VoidCallback onDeposit;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  /// Quanto de cada cartão fica à mostra acima do seguinte.
  static const _peek = 26.0;

  var _hidden = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onHero;
    final peeking = widget.cards.take(2).toList();

    return Stack(
      children: [
        for (var i = 0; i < peeking.length; i++)
          Positioned(
            top: i * _peek,
            left: AppSpacing.md + (peeking.length - 1 - i) * AppSpacing.sm,
            right: AppSpacing.md + (peeking.length - 1 - i) * AppSpacing.sm,
            child: _CardFace(card: peeking[i]),
          ),
        Container(
          margin: EdgeInsets.only(top: peeking.length * _peek),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.hero, palette.heroGradientEnd(palette.hero)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: palette.shadowMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total do mês',
                      style: context.text.field.copyWith(color: fg.withValues(alpha: 0.7)),
                    ),
                  ),
                  _Pill(label: widget.badge, color: fg),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _hidden ? 'R\$ ••••••' : widget.value,
                        style: context.text.hero.copyWith(color: fg),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    tooltip: _hidden ? 'Mostrar valor' : 'Esconder valor',
                    icon: Icon(
                      _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Text(widget.meta, style: context.text.caption.copyWith(color: fg.withValues(alpha: 0.6))),
              const SizedBox(height: AppSpacing.md),
              SpendingGoalBar(
                progress: widget.goalProgress,
                label: widget.goalLabel,
                onTap: widget.onTapGoal,
                color: fg,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _HeroAction(
                      icon: Icons.add,
                      label: 'Nova compra',
                      color: fg,
                      onPressed: widget.onNewPurchase,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _HeroAction(
                      icon: Icons.savings_outlined,
                      label: 'Depositar',
                      color: fg,
                      onPressed: widget.onDeposit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A borda de um cartão aparecendo por trás do card escuro.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.card});

  final CardShare card;

  @override
  Widget build(BuildContext context) {
    final base = context.palette.avatarBackground(card.hue);
    final fg = context.palette.onHero;

    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xsPlus, AppSpacing.lg, 0),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.15)!],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '••••  ${card.name}',
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.credit_card, size: 14, color: fg.withValues(alpha: 0.85)),
        ],
      ),
    );
  }
}

/// Botão em pílula translúcida sobre o card escuro.
class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.caption.copyWith(fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.9)),
      ),
    );
  }
}
