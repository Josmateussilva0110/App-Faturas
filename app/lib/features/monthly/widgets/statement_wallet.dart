import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/app_state.dart';
import 'statement_card.dart';

/// A conferência da fatura como uma carteira: os cartões do mês saem de um
/// bolso, e o que o usuário toca sobe e mostra a própria conferência embaixo.
///
/// Um card de conferência por cartão empilhava três ou quatro blocos iguais
/// na tela; aqui se vê num relance quais cartões pedem atenção (pela cor do
/// ícone em cada um) e só um detalhe fica aberto por vez.
class StatementWallet extends StatefulWidget {
  const StatementWallet({super.key, required this.checks, required this.onTap});

  final List<StatementCheck> checks;

  /// Toque no detalhe aberto: abre a edição da fatura daquele cartão.
  final void Function(StatementCheck check) onTap;

  @override
  State<StatementWallet> createState() => _StatementWalletState();
}

class _StatementWalletState extends State<StatementWallet> {
  /// Guardado pelo id e não pela posição: ao trocar de mês a lista muda, e o
  /// mesmo índice apontaria para outro cartão.
  String? _selectedId;

  /// O selecionado, ou — sem escolha ainda, ou se ele sumiu no mês novo — o
  /// primeiro que pede atenção, que é o que o usuário veio ver.
  StatementCheck get _selected {
    final checks = widget.checks;
    for (final check in checks) {
      if (check.card.id == _selectedId) return check;
    }
    return checks.firstWhere(
      (c) => c.status != StatementStatus.matched,
      orElse: () => checks.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Wallet(
          checks: widget.checks,
          selectedId: selected.card.id,
          onSelect: (id) => setState(() => _selectedId = id),
        ),
        const SizedBox(height: AppSpacing.md),
        // Troca com um fade curto: sem ele o detalhe pulava de um cartão
        // para o outro e o olho não ligava a troca ao toque.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: StatementCard(
            key: ValueKey(selected.card.id),
            check: selected,
            onTap: () => widget.onTap(selected),
          ),
        ),
      ],
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.checks, required this.selectedId, required this.onSelect});

  final List<StatementCheck> checks;
  final String selectedId;
  final ValueChanged<String> onSelect;

  /// Quanto de cada cartão guardado aparece acima do da frente.
  static const _peek = 40.0;

  /// Quanto do selecionado fica à mostra: nome, chip e número.
  static const _selectedVisible = 104.0;

  /// Curto o bastante para a base do cartão da frente não escapar por
  /// baixo do bolso.
  static const _cardHeight = 136.0;

  /// Parte do cartão da frente que fica visível acima do bolso.
  static const _frontVisible = 48.0;

  static const _pocketHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    // O selecionado vai para o fundo da pilha, no alto e bem à mostra, e os
    // outros se enfileiram na frente dele. Subir o cartão no próprio lugar
    // não servia: ele cobria por inteiro os que estavam atrás, e aí não
    // havia mais onde tocar para escolhê-los.
    final selected = checks.firstWhere((c) => c.card.id == selectedId);
    final ordered = [selected, ...checks.where((c) => c.card.id != selectedId)];
    final n = ordered.length;

    double topOf(int k) => k == 0 ? 0 : _selectedVisible + (k - 1) * _peek;
    final pocketTop = n == 1 ? _selectedVisible : topOf(n - 1) + _frontVisible;

    return SizedBox(
      height: pocketTop + _pocketHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Do fundo para a frente; a chave mantém o mesmo widget em cada
          // cartão, então ele desliza até o lugar novo em vez de pular.
          for (var k = 0; k < n; k++)
            AnimatedPositioned(
              key: ValueKey(ordered[k].card.id),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              top: topOf(k),
              left: AppSpacing.md,
              right: AppSpacing.md,
              height: _cardHeight,
              child: _TiltedCard(
                check: ordered[k],
                selected: k == 0,
                onTap: () => onSelect(ordered[k].card.id),
              ),
            ),
          Positioned(
            top: pocketTop,
            left: 0,
            right: 0,
            height: _pocketHeight,
            child: _Pocket(check: selected, count: n),
          ),
        ],
      ),
    );
  }
}

/// A face do cartão, inclinada para trás quando está guardada e reta quando
/// é a selecionada — a perspectiva é o que dá a impressão de profundidade.
class _TiltedCard extends StatelessWidget {
  const _TiltedCard({required this.check, required this.selected, required this.onTap});

  final StatementCheck check;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final base = palette.avatarBackground(check.card.resolvedHue);
    final fg = palette.onHero;
    final style = StatementStyle.of(check.status, scheme: scheme, palette: palette);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 0 : 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        // Eixo na base: o cartão tomba para trás a partir de onde entra no
        // bolso, como se estivesse encostado nos outros.
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-0.32 * t);
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: transform,
          child: child,
        );
      },
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Cartão ${check.card.name}, ${style.label}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(base, Colors.white, 0.08)!,
                  Color.lerp(base, Colors.black, 0.22)!,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? 0.28 : 0.14),
                  blurRadius: selected ? 18 : 8,
                  offset: Offset(0, selected ? 8 : 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        check.card.name,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.title.copyWith(color: fg),
                      ),
                    ),
                    // Fundo branco para o ícone de status ler sobre qualquer
                    // cor de cartão — a cor dele é a mesma do detalhe.
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(style.icon, size: 16, color: style.color),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const _Chip(),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.contactless_outlined, size: 20, color: fg.withValues(alpha: 0.8)),
                    const Spacer(),
                    // O valor do mês no lugar do número do cartão, que o app
                    // não guarda: a fatura quando já foi informada, senão o
                    // que está registrado.
                    Text(
                      formatMoney(check.billed ?? check.registered),
                      style: context.text.body.copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O chip dourado do cartão.
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 22,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE9D08A), Color(0xFFB8963E)]),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }
}

/// O bolso da carteira: couro escuro com costura tracejada, cobrindo a parte
/// de baixo dos cartões. Mostra qual está selecionado.
class _Pocket extends StatelessWidget {
  const _Pocket({required this.check, required this.count});

  final StatementCheck check;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onHero;
    final style = StatementStyle.of(check.status, scheme: Theme.of(context).colorScheme, palette: palette);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.heroGradientEnd(palette.hero), palette.hero],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          // Sombra para cima: é o bolso que fica na frente dos cartões.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _StitchPainter(color: fg.withValues(alpha: 0.22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.card.name,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.label.copyWith(color: fg),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      count == 1 ? '1 cartão neste mês' : 'Toque num cartão · $count neste mês',
                      style: context.text.caption.copyWith(color: fg.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smPlus, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  style.label,
                  style: context.text.caption.copyWith(fontWeight: FontWeight.w600, color: _onDark(style.color)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// O bolso é escuro nos dois temas; a cor de status do tema claro (o
  /// grafite de "Registrado a mais", por exemplo) sumiria nele.
  static Color _onDark(Color color) {
    return HSLColor.fromColor(color).lightness < 0.55
        ? Color.lerp(color, Colors.white, 0.55)!
        : color;
  }
}

/// A costura tracejada rente à borda do bolso.
class _StitchPainter extends CustomPainter {
  const _StitchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 7.0;
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
        const Radius.circular(AppRadius.lg - inset),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_StitchPainter oldDelegate) => oldDelegate.color != color;
}
