import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/card_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/section_label.dart';
import '../../widgets/segmented_choice.dart';
import 'purchase_form_values.dart';
import 'widgets/card_choice_chips.dart';

/// The purchase name/amount/installments/card/date/person fields, shared by
/// both the "Nova compra" screen and the "Editar compra" dialog so the two
/// forms can never drift apart.
///
/// Owns all of its own input state; the parent only supplies initial values
/// and receives a [PurchaseFormValues] once the user submits a valid form.
class PurchaseFormFields extends StatefulWidget {
  const PurchaseFormFields({
    super.key,
    required this.cards,
    required this.submitLabel,
    required this.onSubmit,
    this.initialIsOther = false,
    this.initialPerson = '',
    this.initialName = '',
    this.initialAmount = '',
    this.initialInstallments = '',
    this.initialStartOffset = 0,
    this.initialCardId,
    this.trailing,
  });

  final List<CardModel> cards;
  final String submitLabel;
  final ValueChanged<PurchaseFormValues> onSubmit;

  final bool initialIsOther;
  final String initialPerson;
  final String initialName;
  final String initialAmount;
  final String initialInstallments;
  final int initialStartOffset;
  final String? initialCardId;

  /// Extra content rendered below the submit button (the edit dialog's
  /// delete / confirm-delete section).
  final Widget? trailing;

  @override
  State<PurchaseFormFields> createState() => _PurchaseFormFieldsState();
}

class _PurchaseFormFieldsState extends State<PurchaseFormFields> {
  late bool _isOther = widget.initialIsOther;
  late int _startOffset = widget.initialStartOffset;
  late String? _cardId = widget.initialCardId ?? (widget.cards.isNotEmpty ? widget.cards.first.id : null);

  late final _personController = TextEditingController(text: widget.initialPerson);
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _amountController = TextEditingController(text: widget.initialAmount);
  late final _installmentsController = TextEditingController(text: widget.initialInstallments);

  @override
  void dispose() {
    _personController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  double? get _parsedAmount => double.tryParse(_amountController.text.replaceAll(',', '.'));
  int? get _parsedInstallments => int.tryParse(_installmentsController.text);

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      (_parsedAmount ?? 0) > 0 &&
      (_parsedInstallments ?? 0) >= 1 &&
      _cardId != null &&
      (!_isOther || _personController.text.trim().isNotEmpty);

  void _submit() {
    if (!_isValid) return;
    widget.onSubmit(PurchaseFormValues(
      name: _nameController.text.trim(),
      amount: _parsedAmount!,
      installments: _parsedInstallments!,
      isOther: _isOther,
      person: _isOther ? _personController.text.trim() : '',
      cardId: _cardId!,
      startOffset: _startOffset,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = formatMonthLabel(currentAbsoluteMonth() + _startOffset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('Quem comprou'),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedChoice<bool>(
            value: _isOther,
            options: const [(false, 'Minha compra'), (true, 'De outra pessoa')],
            onChanged: (v) => setState(() => _isOther = v),
          ),
        ),
        if (_isOther) ...[
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Nome da pessoa',
            icon: Icons.person_outline,
            controller: _personController,
            hintText: 'Ex: Maria',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Divider(height: AppSpacing.xl),
        const SectionLabel('Detalhes da compra'),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: _isOther ? 'Descrição da compra' : 'Item ou conta',
          icon: Icons.local_offer_outlined,
          controller: _nameController,
          hintText: 'Ex: Notebook Dell',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Valor da parcela',
                icon: Icons.attach_money,
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hintText: '0,00',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Nº de parcelas',
                icon: Icons.format_list_numbered,
                controller: _installmentsController,
                keyboardType: TextInputType.number,
                hintText: '1',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Divider(height: AppSpacing.xl),
        const SectionLabel('Quando começa'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => setState(() => _startOffset -= 1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              onPressed: () => setState(() => _startOffset += 1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Divider(height: AppSpacing.xl),
        const SectionLabel('Pagamento', icon: Icons.credit_card_outlined),
        const SizedBox(height: AppSpacing.sm),
        CardChoiceChips(
          cards: widget.cards,
          selectedId: _cardId,
          onSelect: (id) => setState(() => _cardId = id),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isValid ? _submit : null,
            child: Text(widget.submitLabel),
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(height: AppSpacing.md),
          widget.trailing!,
        ],
      ],
    );
  }
}
