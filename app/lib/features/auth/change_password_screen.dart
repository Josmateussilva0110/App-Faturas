import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/toast/app_toast.dart';
import '../../data/api/api_response.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/profile_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section_card.dart';
import '../../widgets/section_label.dart';
import '../onboarding/welcome_screen.dart';

/// Troca de senha, em duas entradas.
///
/// Pelo Perfil ([forced] falso) o usuário informa a senha atual. Depois de um
/// reset atendido à mão ([forced] verdadeiro, vindo de
/// `AppUser.mustChangePassword`) ele não sabe a senha atual — ela é
/// temporária —, então o campo some e o backend aceita a troca sem ele.
///
/// No modo obrigatório a tela não tem saída para o app, só para o logout:
/// prender alguém que não consegue definir uma senha seria pior que a porta
/// de saída.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;

  String? _currentError;
  String? _nextError;
  String? _confirmError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Espelha as regras do `passwordField` do backend, para o usuário saber o
  /// que falta antes de gastar uma ida ao servidor.
  static String? _passwordRuleError(String value) {
    if (value.length < 8) return 'Use ao menos 8 caracteres.';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Inclua ao menos uma letra maiúscula.';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Inclua ao menos um número.';
    if (!value.contains(RegExp(r'[^A-Za-z0-9]'))) return 'Inclua ao menos um caractere especial.';
    return null;
  }

  bool _validate() {
    final next = _next.text;
    setState(() {
      _currentError = !widget.forced && _current.text.isEmpty ? 'Informe a senha atual.' : null;
      _nextError = _passwordRuleError(next);
      _confirmError = _confirm.text != next ? 'As senhas não coincidem.' : null;
    });
    return _currentError == null && _nextError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    if (_submitting || !_validate()) return;

    setState(() => _submitting = true);
    final response = await changePassword(
      newPassword: _next.text,
      confirmPassword: _confirm.text,
      currentPassword: widget.forced ? null : _current.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!response.success) {
      setState(() => _applyFieldErrors(response.errors));
      AppToast.error(response.message);
      return;
    }

    AppToast.success('Senha alterada.');

    if (widget.forced) {
      // O backend já baixou a flag; refletir no estado troca esta tela pelo
      // app sem uma ida a mais ao servidor.
      context.read<AppState>().clearMustChangePassword();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// O backend responde 422 apontando o campo; mostrar sob o input certo em
  /// vez de só dentro do toast.
  void _applyFieldErrors(List<ApiFieldError> errors) {
    for (final error in errors) {
      if (error.field == 'current_password') _currentError = error.message;
      if (error.field == 'new_password') _nextError = error.message;
      if (error.field == 'confirm_password') _confirmError = error.message;
    }
  }

  Future<void> _signOut() async {
    await logoutUser();
    await endSession();
    if (!mounted) return;

    context.read<AppState>().reset();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      // Sem isto o gesto de voltar do Android devolve o usuário ao app com a
      // senha temporária ainda valendo.
      canPop: !widget.forced,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(
          title: Text(widget.forced ? 'Defina uma nova senha' : 'Alterar senha'),
          backgroundColor: scheme.surfaceContainerLow,
          automaticallyImplyLeading: !widget.forced,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (widget.forced) ...[
                Text(
                  'Sua senha atual é temporária. Escolha uma nova para continuar.',
                  style: context.text.field,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              FormSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionLabel(
                      'Nova senha',
                      icon: Icons.lock_outline,
                      iconColor: scheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!widget.forced) ...[
                      AppTextField(
                        label: 'Senha atual',
                        controller: _current,
                        obscureText: _obscure,
                        errorText: _currentError,
                        enabled: !_submitting,
                        onChanged: (_) {
                          if (_currentError != null) setState(() => _currentError = null);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppTextField(
                      label: 'Nova senha',
                      controller: _next,
                      obscureText: _obscure,
                      errorText: _nextError,
                      enabled: !_submitting,
                      autofocus: widget.forced,
                      onChanged: (_) {
                        if (_nextError != null) setState(() => _nextError = null);
                      },
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Confirmar nova senha',
                      controller: _confirm,
                      obscureText: _obscure,
                      errorText: _confirmError,
                      enabled: !_submitting,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onChanged: (_) {
                        if (_confirmError != null) setState(() => _confirmError = null);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Mínimo de 8 caracteres, com uma letra maiúscula, um número e um '
                      'caractere especial.',
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Salvar senha'),
                ),
              ),
              if (widget.forced) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _submitting ? null : _signOut,
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: const Text('Sair da conta'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
