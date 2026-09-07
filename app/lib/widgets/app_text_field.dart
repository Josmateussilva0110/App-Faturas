import 'package:flutter/material.dart';

/// Text input with a static label above the field (optionally preceded by
/// an icon), instead of Material's floating `labelText` that animates into
/// the border on focus. Use this everywhere a labeled input is needed so
/// every form in the app looks and behaves the same way.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.icon,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: labelColor),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}
