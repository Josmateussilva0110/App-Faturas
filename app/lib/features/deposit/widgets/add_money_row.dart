import 'package:flutter/material.dart';

/// "Nome / Valor / +" inline add row, used to append both a new salary and
/// a new expense on the Deposit screen.
class AddMoneyRow extends StatelessWidget {
  const AddMoneyRow({
    super.key,
    required this.nameController,
    required this.valueController,
    required this.onAdd,
    this.accentColor,
  });

  final TextEditingController nameController;
  final TextEditingController valueController;
  final VoidCallback onAdd;

  /// Tints the "+" button (e.g. green for salaries, coral for expenses) so
  /// the two sections read as visually distinct. Defaults to the theme's
  /// outlined-button style when omitted.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Nome'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: TextField(
            controller: valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0,00'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          style: accentColor == null
              ? null
              : IconButton.styleFrom(foregroundColor: accentColor, side: BorderSide(color: accentColor!)),
        ),
      ],
    );
  }
}
