import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/formatters.dart';
import 'app_text_field.dart';

/// The name/value pair a [showMoneyEntryDialog] returns.
typedef MoneyEntry = ({String name, double value});

/// "Editar salário" / "Editar despesa" dialog: a name and an amount.
/// Returns the edited pair, or null if the user cancelled.
Future<MoneyEntry?> showMoneyEntryDialog(
  BuildContext context, {
  required String title,
  required String name,
  required double value,
}) async {
  final result = await showDialog<_DialogResult>(
    context: context,
    builder: (_) => _MoneyEntryDialog(title: title, name: name, value: value),
  );

  final amount = result?.amount;
  if (result == null || amount == null) return null;
  return (name: result.name, value: amount);
}

/// Amount-only variant, for values that have no name of their own — the card
/// bill on the reconciliation section.
///
/// Returns null when the user cancelled. Returns a record whose `amount` is
/// null when they chose to clear the value, which is why the two cases can't
/// collapse into a bare `double?`.
Future<({double? amount})?> showAmountDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? helper,
  double? value,
}) async {
  final result = await showDialog<_DialogResult>(
    context: context,
    builder: (_) => _MoneyEntryDialog(
      title: title,
      value: value,
      valueLabel: label,
      helper: helper,
      allowClear: value != null,
    ),
  );

  if (result == null) return null;
  return (amount: result.amount);
}

class _DialogResult {
  const _DialogResult({required this.name, required this.amount});

  final String name;

  /// Null when the user cleared the value instead of setting one.
  final double? amount;
}

class _MoneyEntryDialog extends StatefulWidget {
  const _MoneyEntryDialog({
    required this.title,
    this.name,
    this.value,
    this.valueLabel = 'Valor',
    this.helper,
    this.allowClear = false,
  });

  final String title;

  /// Null renders the amount-only layout, without the name field.
  final String? name;

  final double? value;
  final String valueLabel;
  final String? helper;
  final bool allowClear;

  @override
  State<_MoneyEntryDialog> createState() => _MoneyEntryDialogState();
}

class _MoneyEntryDialogState extends State<_MoneyEntryDialog> {
  late final _name = TextEditingController(text: widget.name ?? '');
  // Vírgula, como o usuário digitaria: `parseMoney` aceita as duas formas.
  late final _value = TextEditingController(
    text: widget.value == null ? '' : widget.value!.toStringAsFixed(2).replaceAll('.', ','),
  );

  bool get _hasName => widget.name != null;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  _DialogResult? get _result {
    final name = _name.text.trim();
    final value = parseMoney(_value.text);
    if (value == null) return null;
    if (_hasName && name.isEmpty) return null;
    return _DialogResult(name: name, amount: value);
  }

  void _submit() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasName) ...[
            AppTextField(
              label: 'Nome',
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            label: widget.valueLabel,
            controller: _value,
            autofocus: !_hasName,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: '0,00',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.helper != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.helper!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: [
        if (widget.allowClear)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _DialogResult(name: '', amount: null)),
            child: const Text('Limpar'),
          ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _result == null ? null : _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
