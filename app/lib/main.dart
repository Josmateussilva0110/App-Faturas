import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/settings/secure_settings_storage.dart';
import 'core/settings/settings_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/toast/app_toast.dart';
import 'data/api/auth_storage.dart';
import 'data/api/secure_auth_storage.dart';
import 'data/api_fatura_repository.dart';
import 'features/shell/session_gate.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // From here on the session survives restarts; tests swap this for an
  // in-memory implementation.
  authStorage = SecureAuthStorage();
  settingsStorage = SecureSettingsStorage();

  // Lido antes do runApp de propósito: com a leitura depois, o app abriria no
  // padrão e piscaria para o tema escolhido no primeiro frame.
  final storedTheme = await settingsStorage.readThemeMode();

  runApp(FaturaApp(initialThemeMode: storedTheme));
}

class FaturaApp extends StatelessWidget {
  const FaturaApp({super.key, this.initialThemeMode});

  /// A preferência lida do disco, ou null para seguir o sistema.
  final ThemeMode? initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // `load` runs only once a session exists — see SessionGate.
      create: (_) => AppState(ApiFaturaRepository(), themeMode: initialThemeMode),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Faturas',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppToast.navigatorKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appState.themeMode,
            home: const SessionGate(),
          );
        },
      ),
    );
  }
}
