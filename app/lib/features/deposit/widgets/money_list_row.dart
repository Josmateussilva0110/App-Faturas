import 'package:flutter/material.dart';

import '../../../widgets/app_card.dart';

/// One salary or expense row: name, formatted value, remove button, and an
/// optional meta line (the running balance under each expense). Shared by
/// the salaries and expenses lists on the Deposit screen.
class MoneyListRow extends StatelessWidget {
  const MoneyListRow({
    super.key,
    required this.name,
    required this.valueLabel,
    required this.onRemove,
    this.meta,
  });

  final String name;
  final String valueLabel;
  final String? meta;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(valueLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
                color: scheme.error,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (meta != null)
            Text(meta!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
