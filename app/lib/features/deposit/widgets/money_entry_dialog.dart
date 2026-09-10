import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_text_field.dart';

/// The name/value pair a [showMoneyEntryDialog] returns.
typedef MoneyEntry = ({String name, double value});

/// "Editar salário" / "Editar despesa" dialog. Returns the edited pair, or
/// null if the user cancelled. Adding still happens inline through
/// `AddMoneyRow` — this is the editing counterpart, in the shape of
/// `showCardNameDialog`.
Future<MoneyEntry?> showMoneyEntryDialog(
  BuildContext context, {
  required String title,
  required String name,
  required double value,
}) {
  return showDialog<MoneyEntry>(
    context: context,
    builder: (_) => _MoneyEntryDialog(title: title, name: name, value: value),
  );
}

class _MoneyEntryDialog extends StatefulWidget {
  const _MoneyEntryDialog({required this.title, required this.name, required this.value});

  final String title;
  final String name;
  final double value;

  @override
  State<_MoneyEntryDialog> createState() => _MoneyEntryDialogState();
}

class _MoneyEntryDialogState extends State<_MoneyEntryDialog> {
  late final _name = TextEditingController(text: widget.name);
  // Vírgula, como o usuário digitaria: `parseMoney` aceita as duas formas.
  late final _value = TextEditingController(
    text: widget.value.toStringAsFixed(2).replaceAll('.', ','),
  );

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  MoneyEntry? get _entry {
    final name = _name.text.trim();
    final value = parseMoney(_value.text);
    if (name.isEmpty || value == null) return null;
    return (name: name, value: value);
  }

  void _submit() {
    final entry = _entry;
    if (entry == null) return;
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nome',
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Valor',
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: '0,00',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _entry == null ? null : _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
