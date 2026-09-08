import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/toast/app_toast.dart';
import '../../data/api/api_response.dart';
import '../../data/services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_illustration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section_card.dart';
import '../shell/app_entry.dart';

/// Email + password sign in against the backend's `POST /api/login`.
///
/// A successful login starts the session (`startSession`), so every later
/// call made through `requestData` carries the token — and gets refreshed
/// automatically when it expires. The session is then stored, so the user
/// stays signed in across restarts until they sign out. The app's *data*
/// still comes from `MockFaturaRepository`; auth and the profile are real.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Mirrors the backend's `LoginSchema`: a well-formed email and a
  /// non-empty password (login doesn't enforce the complexity rules that
  /// apply when a password is *set*).
  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailLooksValid = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$').hasMatch(email);

    setState(() {
      _emailError = email.isEmpty
          ? 'Informe seu email.'
          : emailLooksValid
              ? null
              : 'Email inválido.';
      _passwordError = password.isEmpty ? 'Informe sua senha.' : null;
    });

    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (_submitting || !_validate()) return;

    setState(() => _submitting = true);

    final response = await loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    final session = response.data;
    if (!response.success || session == null) {
      setState(() {
        _submitting = false;
        _applyFieldErrors(response.errors);
      });
      AppToast.error(response.message);
      return;
    }

    await startSession(session);
    if (!mounted) return;

    // Load with the token already active, so the app doesn't open on a
    // spinner.
    await context.read<AppState>().load();
    if (!mounted) return;

    AppToast.success('Bem-vindo de volta!');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppEntry()),
      (route) => false,
    );
  }

  /// The backend answers a 422 pointing at the offending field; show it
  /// under that input instead of only inside the toast.
  void _applyFieldErrors(List<ApiFieldError> errors) {
    for (final error in errors) {
      if (error.field == 'email') _emailError = error.message;
      if (error.field == 'password') _passwordError = error.message;
    }
  }

  /// `POST /auth/password-reset-request` — there's no self-service reset
  /// link; the backend registers the request and the team makes contact.
  Future<void> _requestReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Informe seu email para recuperar a senha.');
      return;
    }

    setState(() => _submitting = true);
    final response = await requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (response.success) {
      AppToast.success(
        response.message.isEmpty ? 'Solicitação enviada.' : response.message,
      );
    } else {
      AppToast.error(response.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: const AspectRatio(
                    aspectRatio: 200 / 150,
                    child: AppIllustration('login_shield', semanticLabel: 'Escudo com cadeado'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Bem-vindo de volta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Entre para ver a fatura do mês e suas parcelas.',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              FormSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Email',
                      icon: Icons.alternate_email,
                      controller: _emailController,
                      hintText: 'voce@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_submitting,
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !_submitting,
                      errorText: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                      onSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting ? null : _requestReset,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Problemas para acessar? Fale com a equipe.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
