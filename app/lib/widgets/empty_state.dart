import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Centered icon + message shown when a list has nothing to display.
///
/// Use [EmptyState.error] quando a lista está vazia porque a busca falhou.
/// Sem essa distinção o usuário lê "Nenhuma compra ativa este mês" depois de
/// uma queda de rede — uma frase que ele não tem como saber que é falsa.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  }) : onRetry = null;

  /// A lista está vazia porque a carga falhou. Mostra "Tentar de novo" em vez
  /// de deixar o usuário sem saída — hoje a única alternativa dele é matar o
  /// app.
  const EmptyState.error({
    super.key,
    required this.message,
    required this.onRetry,
  })  : icon = Icons.cloud_off_outlined,
        action = null;

  final String message;
  final IconData icon;

  /// Botão sob a mensagem, para o vazio que tem uma saída óbvia (ex:
  /// "Cadastrar cartão" quando não há nenhum).
  final Widget? action;

  /// Preenchido só por [EmptyState.error].
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = onRetry != null;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.label.copyWith(color: color),
          ),
          if (isError) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar de novo'),
            ),
          ] else if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
