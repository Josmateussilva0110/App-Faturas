import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/app_dialog.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/app_state.dart';
import '../../widgets/app_text_field.dart';

/// Shows the "Fatura — {person}" share dialog: a preview of the generated
/// bill text, an optional discount, and copy/share actions.
Future<void> showShareBillDialog(
  BuildContext context, {
  required String label,
  required List<PurchaseEntry> rows,
  required double subtotal,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ShareBillDialog(label: label, rows: rows, subtotal: subtotal),
  );
}

class ShareBillDialog extends StatefulWidget {
  const ShareBillDialog({
    super.key,
    required this.label,
    required this.rows,
    required this.subtotal,
  });

  final String label;
  final List<PurchaseEntry> rows;
  final double subtotal;

  @override
  State<ShareBillDialog> createState() => _ShareBillDialogState();
}

class _ShareBillDialogState extends State<ShareBillDialog> {
  final _discountController = TextEditingController();
  bool _copied = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  double get _discount => double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;

  String _shareText(AppState appState) => appState.buildShareText(
    label: widget.label,
    rows: widget.rows,
    subtotal: widget.subtotal,
    discount: _discount,
  );

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final text = _shareText(appState);

    return AppDialog(
      title: 'Fatura · ${widget.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Desconto (R\$)',
            controller: _discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: '0,00',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _copy(_shareText(appState)),
                  child: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: _shareText(appState))),
                  child: const Text('Compartilhar'),
                ),
              ),
            ],
          ),
          if (_copied) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text('Copiado!', style: TextStyle(fontSize: 12, color: scheme.primary)),
            ),
          ],
        ],
      ),
    );
  }
}
