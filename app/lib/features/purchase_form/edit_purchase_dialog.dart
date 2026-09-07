import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../models/purchase.dart';
import '../../state/app_state.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'purchase_form_fields.dart';

/// Shows the "Editar compra" dialog for [purchase]. Reuses
/// [PurchaseFormFields] for the fields and adds a delete flow, confirmed via
/// [showConfirmDeleteDialog].
Future<void> showEditPurchaseDialog(BuildContext context, Purchase purchase) {
  return showDialog<void>(
    context: context,
    builder: (_) => EditPurchaseDialog(purchase: purchase),
  );
}

class EditPurchaseDialog extends StatelessWidget {
  const EditPurchaseDialog({super.key, required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editar compra',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                PurchaseFormFields(
                  cards: appState.cards,
                  submitLabel: 'Salvar alterações',
                  initialIsOther: purchase.isOther,
                  initialPerson: purchase.person,
                  initialName: purchase.name,
                  initialAmount: _stripTrailingZero(purchase.amount),
                  initialInstallments: purchase.installments.toString(),
                  initialStartOffset: purchase.startAbs - appState.currentAbs,
                  initialCardId: purchase.cardId,
                  onSubmit: (values) async {
                    try {
                      await context.read<AppState>().updatePurchase(purchase.copyWith(
                            name: values.name,
                            amount: values.amount,
                            installments: values.installments,
                            isOther: values.isOther,
                            person: values.person,
                            cardId: values.cardId,
                            startAbs: appState.currentAbs + values.startOffset,
                          ));
                      if (context.mounted) Navigator.of(context).pop();
                      AppToast.success('Compra atualizada.');
                    } catch (_) {
                      AppToast.error('Não foi possível salvar as alterações.');
                    }
                  },
                  trailing: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showConfirmDeleteDialog(
                          context,
                          title: 'Excluir compra?',
                          message: 'Isso vai remover "${purchase.name}" permanentemente.',
                        );
                        if (!confirmed || !context.mounted) return;
                        try {
                          await context.read<AppState>().deletePurchase(purchase.id);
                          if (context.mounted) Navigator.of(context).pop();
                          AppToast.success('Compra excluída.');
                        } catch (_) {
                          AppToast.error('Não foi possível excluir a compra.');
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                      child: const Text('Excluir'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stripTrailingZero(double amount) {
    final text = amount.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }
}
