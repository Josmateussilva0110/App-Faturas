import '../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/card_model.dart';
import '../../widgets/app_text_field.dart';

/// Nome e cor escolhidos no diálogo. [hue] nulo é "automática".
typedef CardDraft = ({String name, int? hue});

/// "Novo cartão" / "Editar cartão" dialog. Returns the name and color the
/// user picked, or null if they cancelled.
Future<CardDraft?> showCardDialog(BuildContext context, {CardModel? existing}) {
  return showDialog<CardDraft>(
    context: context,
    builder: (_) => _CardDialog(existing: existing),
  );
}

class _CardDialog extends StatefulWidget {
  const _CardDialog({this.existing});

  final CardModel? existing;

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  late final _controller = TextEditingController(text: widget.existing?.name ?? '');
  late int? _hue = widget.existing?.hue;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  /// A bolinha "automática" mostra a cor que o nome digitado geraria, e
  /// acompanha o que está sendo digitado — senão o usuário escolheria no
  /// escuro.
  int get _autoHue => hueForLabel(_name);

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;

    return AlertDialog(
      title: Text(isNew ? 'Novo cartão' : 'Editar cartão'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nome do cartão',
            controller: _controller,
            autofocus: true,
            hintText: 'Ex: Nubank Gold',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Cor',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Swatch(
                hue: _autoHue,
                selected: _hue == null,
                auto: true,
                onTap: () => setState(() => _hue = null),
              ),
              for (final hue in AppColors.cardHues)
                _Swatch(
                  hue: hue,
                  selected: _hue == hue,
                  onTap: () => setState(() => _hue = hue),
                ),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _name.isEmpty
              ? null
              : () => Navigator.of(context).pop((name: _name, hue: _hue)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hue,
    required this.selected,
    required this.onTap,
    this.auto = false,
  });

  final int hue;
  final bool selected;
  final VoidCallback onTap;

  /// A opção "automática": mesma cor do hash do nome, marcada com um "A"
  /// para não parecer só mais uma bolinha da paleta.
  final bool auto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = context.palette.avatarBackground(hue);

    return Semantics(
      selected: selected,
      button: true,
      label: auto ? 'Cor automática' : 'Cor $hue',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // O anel de seleção fica fora da bolinha, com um vão: por dentro
            // ele brigaria com a cor que está sendo escolhida.
            border: selected
                ? Border.all(color: scheme.onSurface, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: auto
              ? const Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.avatarForeground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                )
              : selected
                  ? const Icon(Icons.check, size: 18, color: AppColors.avatarForeground)
                  : null,
        ),
      ),
    );
  }
}
