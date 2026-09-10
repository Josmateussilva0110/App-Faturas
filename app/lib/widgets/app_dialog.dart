import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// O invólucro dos diálogos de conteúdo do app — os que têm cabeçalho com
/// título e botão de fechar, em oposição aos `AlertDialog` de confirmação.
///
/// Existia copiado em três arquivos (editar compra, compartilhar fatura,
/// exportar resumo) com três larguras (440/440/420) e três tamanhos de
/// título (18/16/18). Uma cópia só, uma largura, uma tipografia.
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    // Expanded para título longo truncar em vez de empurrar o
                    // botão de fechar para fora — o de "Editar compra" não
                    // tinha, e um nome comprido quebrava o layout.
                    Expanded(
                      child: Text(
                        title,
                        style: context.text.money,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
