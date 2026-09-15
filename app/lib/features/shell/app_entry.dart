import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../auth/change_password_screen.dart';
import 'app_shell.dart';

/// Gate between the login screen and the app itself: holds a spinner until
/// [AppState.load] has finished, since every tab reads data (and
/// `currentUser`) that only exists once the load completes.
///
/// É também onde a senha temporária é cobrada. Fica aqui, e não na tela de
/// login, porque os dois caminhos de entrada — login e sessão restaurada no
/// boot — passam por este ponto; na tela de login, quem já estava logado
/// entraria direto no app sem trocar nada.
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AppState, bool>((state) => state.isLoading);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mustChangePassword =
        context.select<AppState, bool>((state) => state.currentUser.mustChangePassword);
    if (mustChangePassword) {
      return const ChangePasswordScreen(forced: true);
    }

    return const AppShell();
  }
}
