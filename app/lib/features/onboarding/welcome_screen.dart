import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_illustration.dart';
import '../../widgets/form_section_card.dart';
import '../auth/login_screen.dart';

/// First screen the app opens on: introduces what Fatura does and hands off
/// to [LoginScreen]. There is no sign-up flow — accounts are created by the
/// team on the backend — so the only action here is "Entrar".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _features = [
    (
      asset: 'feature_installments',
      title: 'Parcelas sob controle',
      description: 'Veja quanto cai na fatura de cada mês, sem planilha.',
    ),
    (
      asset: 'feature_cards',
      title: 'Cartões separados',
      description: 'Cada compra no seu cartão, com o total por fatura.',
    ),
    (
      asset: 'feature_people',
      title: 'Divisão entre pessoas',
      description: 'Saiba na hora quanto cada um ainda te deve.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.55],
            colors: [
              scheme.primaryContainer.withValues(alpha: palette.dark ? 0.30 : 0.55),
              scheme.surfaceContainerLow,
            ],
          ),
        ),
        child: SafeArea(
          // The intro scrolls when it doesn't fit, but "Entrar" stays pinned
          // to the bottom so the only action is always one tap away.
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _Wordmark(),
                            const SizedBox(height: AppSpacing.lg),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: const AspectRatio(
                                  aspectRatio: 360 / 260,
                                  child: AppIllustration(
                                    'welcome_finance',
                                    semanticLabel:
                                        'Carteira com cartões, moedas e um gráfico de gastos',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Suas contas do mês,\nsob controle.',
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Compras parceladas, cartões e o que cada pessoa deve — '
                              'tudo somado pra você.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            FormSectionCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final (index, feature) in _features.indexed) ...[
                                    if (index > 0) const SizedBox(height: AppSpacing.lg),
                                    _FeatureRow(
                                      asset: feature.asset,
                                      title: feature.title,
                                      description: feature.description,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Entrar'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Acesso apenas para contas já cadastradas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Faturas" logo lockup: the launcher icon's own artwork next to the
/// product name, so the two never drift apart.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A mesma arte do ícone do launcher, gerada por tool/generate_icons.py.
        const AppIllustration('app_mark', width: 34, height: 34, semanticLabel: 'Faturas'),
        const SizedBox(width: AppSpacing.md),
        Text(
          'Faturas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.asset, required this.title, required this.description});

  final String asset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIllustration(asset, width: 42, height: 42),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: TextStyle(fontSize: 12.5, height: 1.35, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
