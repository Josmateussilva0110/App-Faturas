import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/card_model.dart';
import '../../widgets/app_text_field.dart';

/// "Novo cartão" / "Renomear cartão" dialog. Returns the trimmed name the
/// user entered, or null if they cancelled.
Future<String?> showCardNameDialog(BuildContext context, {CardModel? existing}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CardNameDialog(existing: existing),
  );
}

class _CardNameDialog extends StatefulWidget {
  const _CardNameDialog({this.existing});

  final CardModel? existing;

  @override
  State<_CardNameDialog> createState() => _CardNameDialogState();
}

class _CardNameDialogState extends State<_CardNameDialog> {
  late final _controller = TextEditingController(text: widget.existing?.name ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Novo cartão' : 'Renomear cartão'),
      content: AppTextField(
        label: 'Nome do cartão',
        controller: _controller,
        autofocus: true,
        hintText: 'Ex: Nubank Gold',
        onSubmitted: (_) => setState(() {}),
        onChanged: (_) => setState(() {}),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
