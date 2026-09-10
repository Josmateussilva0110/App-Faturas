import '../../../widgets/empty_state.dart';
import '../../cards/cards_screen.dart';
import 'package:flutter/material.dart';

import '../../../models/card_model.dart';

/// Row of selectable chips for picking which card a purchase was made on.
/// Shared by the add and edit purchase forms.
class CardChoiceChips extends StatelessWidget {
  const CardChoiceChips({
    super.key,
    required this.cards,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CardModel> cards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Sem cartão nenhum o Wrap ficava vazio e o botão de salvar nunca
    // habilitava, porque a validação exige um cartão — sem nada na tela
    // dizendo o que faltava. É o caminho de todo usuário novo.
    if (cards.isEmpty) {
      return EmptyState(
        message: 'Cadastre um cartão para lançar a compra nele.',
        icon: Icons.credit_card_off_outlined,
        action: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CardsScreen()),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Cadastrar cartão'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final card in cards)
          ChoiceChip(
            label: Text(card.name),
            selected: card.id == selectedId,
            onSelected: (_) => onSelect(card.id),
            selectedColor: scheme.primaryContainer,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: card.id == selectedId ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
            side: BorderSide(color: scheme.outlineVariant),
          ),
      ],
    );
  }
}
