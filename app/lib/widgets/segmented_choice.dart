import 'package:flutter/material.dart';

/// Two-option segmented toggle (e.g. "Minha compra / De outra pessoa",
/// "Claro / Escuro"), reused by the purchase form and the profile screen.
///
/// Renders as a light gray track with the selected option floating on top
/// as a rounded, shadowed pill — not a flush 50/50 split.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.expand = false,
    this.padding,
    this.fontSize = 13,
    this.icons,
  });

  final T value;
  final List<(T value, String label)> options;
  final ValueChanged<T> onChanged;

  /// Stretches the control to fill the available width, splitting the
  /// options evenly, instead of sizing to the labels' content.
  final bool expand;

  /// Padding inside each segment. Defaults to a compact pill; pass a larger
  /// value for a more prominent control (e.g. the Profile screen's theme
  /// picker).
  final EdgeInsetsGeometry? padding;

  final double fontSize;

  /// Optional icon per option, same order/length as [options]. Leave null
  /// (or use `null` entries) for label-only segments.
  final List<IconData?>? icons;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = dark ? scheme.surfaceContainerHighest : const Color(0xFFF0F1F5);
    const outerRadius = BorderRadius.all(Radius.circular(16));
    const innerRadius = BorderRadius.all(Radius.circular(12));

    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: trackColor, borderRadius: outerRadius),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _segment(
              context,
              label: options[i].$2,
              icon: icons == null ? null : icons![i],
              selected: options[i].$1 == value,
              onTap: () => onChanged(options[i].$1),
              radius: innerRadius,
            ),
          ],
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required IconData? icon,
    required bool selected,
    required VoidCallback onTap,
    required BorderRadius radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final segment = Container(
      decoration: BoxDecoration(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: radius,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: fontSize + 3, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expand ? Expanded(child: segment) : segment;
  }
}
