import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Text input with a static label above the field (not Material's floating
/// `labelText`, which animates into the border on focus), optionally
/// preceded by a small icon in that label row. Use this everywhere a
/// labeled input is needed so every form in the app looks and behaves the
/// same way.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.icon,
    this.prefixText,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
  });

  final String label;

  /// Icon rendered next to the label, above the field.
  final IconData? icon;

  /// Fixed text shown inside the field before the value (e.g. "R\$ ").
  final String? prefixText;

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  /// Hides the typed characters, for password fields.
  final bool obscureText;

  /// Widget rendered at the trailing edge *inside* the field (e.g. the
  /// password visibility toggle).
  final Widget? suffixIcon;

  /// Validation message shown under the field; also turns its border red.
  final String? errorText;

  final bool enabled;

  /// Decoration overrides; left null to fall back to the app's shared
  /// [InputDecorationTheme].
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final radius = BorderRadius.circular(AppRadius.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: labelColor),
              const SizedBox(width: AppSpacing.xsPlus),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: labelColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xsPlus),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            errorText: errorText,
            filled: fillColor != null ? true : null,
            fillColor: fillColor,
            enabledBorder: borderColor == null
                ? null
                : OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor!)),
            focusedBorder: focusedBorderColor == null
                ? null
                : OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: focusedBorderColor!, width: 1.5),
                  ),
          ),
        ),
      ],
    );
  }
}
