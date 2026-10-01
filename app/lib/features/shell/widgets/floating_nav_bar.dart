import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// Um destino da [FloatingNavBar].
typedef NavDestination = ({IconData icon, IconData selectedIcon, String label});

/// Barra de abas em pílula, solta do rodapé.
///
/// Toda aba mostra ícone e nome: só o ícone obrigava a decorar o que cada
/// um abre. A aba atual se destaca por uma pílula escura atrás do ícone.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: palette.softSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: palette.dark ? Border.all(color: palette.softBorder) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: palette.dark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    scheme: scheme,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Tooltip(
      message: destination.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A pílula cresce de largura ao selecionar, a mesma ideia do
              // indicador do NavigationBar do Material.
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: selected ? 52 : 32,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(selected ? destination.selectedIcon : destination.icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
