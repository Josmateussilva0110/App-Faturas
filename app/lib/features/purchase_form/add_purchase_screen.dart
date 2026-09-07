import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../core/utils/formatters.dart';
import '../../models/purchase.dart';
import '../../state/app_state.dart';
import 'purchase_form_fields.dart';

/// Full-screen "Nova compra" form, pushed from the Home tab's FAB.
class AddPurchaseScreen extends StatelessWidget {
  const AddPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Nova compra'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PurchaseFormFields(
          cards: appState.cards,
          submitLabel: 'Salvar compra',
          onSubmit: (values) async {
            try {
              await context.read<AppState>().addPurchase(Purchase(
                    id: '',
                    name: values.name,
                    amount: values.amount,
                    installments: values.installments,
                    isOther: values.isOther,
                    person: values.person,
                    cardId: values.cardId,
                    startAbs: currentAbsoluteMonth() + values.startOffset,
                  ));
              if (context.mounted) Navigator.of(context).pop();
              AppToast.success('Compra "${values.name}" adicionada.');
            } catch (_) {
              AppToast.error('Não foi possível salvar a compra.');
            }
          },
        ),
      ),
    );
  }
}
