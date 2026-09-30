import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/card_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section_card.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/section_label.dart';
import '../../widgets/segmented_choice.dart';
import 'purchase_form_values.dart';
import 'widgets/amount_hero.dart';
import 'widgets/card_choice_chips.dart';
import 'widgets/installment_picker.dart';

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
  late int _installments = int.tryParse(widget.initialInstallments) ?? 1;

  @override
  void dispose() {
    _personController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? get _parsedAmount => double.tryParse(_amountController.text.replaceAll(',', '.'));

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      (_parsedAmount ?? 0) > 0 &&
      _installments >= 1 &&
      _cardId != null &&
      (!_isOther || _personController.text.trim().isNotEmpty);

  void _submit() {
    if (!_isValid) return;
    widget.onSubmit(PurchaseFormValues(
      name: _nameController.text.trim(),
      amount: _parsedAmount!,
      installments: _installments,
      isOther: _isOther,
      person: _isOther ? _personController.text.trim() : '',
      cardId: _cardId!,
      startOffset: _startOffset,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    // Campos brancos com borda clara que escurece no foco, só neste
    // formulário — o tema geral usa campo cinza.
    final fieldFill = palette.softSurface;
    final fieldBorder = palette.softBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FormSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountHero(
                controller: _amountController,
                amount: _parsedAmount,
                installments: _installments,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              InstallmentPicker(
                value: _installments,
                onChanged: (value) => setState(() => _installments = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FormSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: _isOther ? 'Descrição da compra' : 'Item ou conta',
                icon: Icons.local_offer_outlined,
                controller: _nameController,
                hintText: 'Ex: Notebook Dell',
                fillColor: fieldFill,
                borderColor: fieldBorder,
                focusedBorderColor: scheme.primary,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel('Quem comprou'),
              const SizedBox(height: AppSpacing.sm),
              SegmentedChoice<bool>(
                value: _isOther,
                options: const [(false, 'Minha compra'), (true, 'De outra pessoa')],
                onChanged: (v) => setState(() => _isOther = v),
                expand: true,
              ),
              if (_isOther) ...[
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Nome da pessoa',
                  icon: Icons.person_outline,
                  controller: _personController,
                  hintText: 'Ex: Maria',
                  fillColor: fieldFill,
                  borderColor: fieldBorder,
                  focusedBorderColor: scheme.primary,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FormSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionLabel(
                'Pagamento',
                icon: Icons.credit_card_outlined,
                iconColor: palette.iconTint(AppColors.hueCards),
              ),
              const SizedBox(height: AppSpacing.sm),
              CardChoiceChips(
                cards: widget.cards,
                selectedId: _cardId,
                onSelect: (id) => setState(() => _cardId = id),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel('Primeira parcela'),
              const SizedBox(height: AppSpacing.sm),
              // Mesmo seletor das telas de mês: o formulário navega entre
              // meses do jeito que o resto do app já ensinou.
              MonthSelector(
                offset: _startOffset,
                currentAbs: currentAbsoluteMonth(),
                onChanged: (value) => setState(() => _startOffset = value),
                color: palette.trackSurface,
              ),
            ],
          ),
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
