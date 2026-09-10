import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';

/// The month browser used by every screen that looks at one month at a time
/// (Meses, Pessoas, Depositar).
///
/// [offset] is counted from the current month, and [onChanged] receives the
/// new one — a single callback instead of three, so the screen keeps one
/// source of truth for which month it is showing. The "Hoje" shortcut only
/// appears away from the current month, where it has something to do.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.offset,
    required this.currentAbs,
    required this.onChanged,
  });

  final int offset;
  final int currentAbs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.softBorder),
      ),
      child: Row(
        children: [
          _Arrow(
            icon: Icons.chevron_left,
            tooltip: 'Mês anterior',
            onPressed: () => onChanged(offset - 1),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    formatMonthLabel(currentAbs + offset),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: context.text.body,
                  ),
                ),
              ],
            ),
          ),
          _Arrow(
            icon: Icons.chevron_right,
            tooltip: 'Próximo mês',
            onPressed: () => onChanged(offset + 1),
          ),
          if (offset != 0)
            TextButton(
              onPressed: () => onChanged(0),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text('Hoje', style: context.text.field),
            ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}
