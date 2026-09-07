import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_text_field.dart';

/// "Meta de gastos" dialog: lets the user set, change, or remove their
/// monthly spending goal. Only the user's own purchases count toward it —
/// purchases made by other people on the card are excluded, so this stays a
/// personal target rather than a per-card credit limit.
Future<void> showSpendingLimitDialog(
  BuildContext context, {
  required double? currentLimit,
  required ValueChanged<double?> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SpendingLimitDialog(currentLimit: currentLimit, onSave: onSave),
  );
}

class _SpendingLimitDialog extends StatefulWidget {
  const _SpendingLimitDialog({required this.currentLimit, required this.onSave});

  final double? currentLimit;
  final ValueChanged<double?> onSave;

  @override
  State<_SpendingLimitDialog> createState() => _SpendingLimitDialogState();
}

class _SpendingLimitDialogState extends State<_SpendingLimitDialog> {
  late final _controller = TextEditingController(
    text: widget.currentLimit == null ? '' : _stripTrailingZero(widget.currentLimit!),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsed => double.tryParse(_controller.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Meta de gastos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Só suas próprias compras contam para essa meta. Compras de outras '
            'pessoas no seu cartão são desconsideradas.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Meta mensal',
            prefixText: 'R\$ ',
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: '0,00',
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => setState(() {}),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: [
        if (widget.currentLimit != null)
          TextButton(
            onPressed: () {
              widget.onSave(null);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remover meta'),
          ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_parsed ?? 0) > 0
              ? () {
                  widget.onSave(_parsed);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String _stripTrailingZero(double amount) {
    final text = amount.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }
}
