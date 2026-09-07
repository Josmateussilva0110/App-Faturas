import 'package:flutter/material.dart';

/// Generic "excluir permanentemente?" confirmation dialog. Import and call
/// this wherever a destructive delete needs a confirmation step, instead of
/// building a one-off dialog or inline confirm state per screen.
///
/// Returns `true` if the user confirmed, `false` if they cancelled or
/// dismissed the dialog.
Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Excluir',
}) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
