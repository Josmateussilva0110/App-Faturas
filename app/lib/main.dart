import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/settings/secure_settings_storage.dart';
import 'core/settings/settings_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_bars.dart';
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

  // O Android 15+ já força isto; declarar aqui faz as versões anteriores se
  // comportarem igual, em vez de a barra de navegação mudar de aparência
  // conforme o aparelho. Quem cuida de não ficar conteúdo embaixo das barras
  // é o SafeArea das telas — ver SystemBarsStyle.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
      // `Selector` e não `Consumer`: o MaterialApp só depende do themeMode, e
      // com o Consumer ele reconstruía a cada notificação do estado — trocar
      // de mês, salvar uma compra, qualquer coisa.
      child: Selector<AppState, ThemeMode>(
        selector: (_, appState) => appState.themeMode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Faturas',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppToast.navigatorKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            builder: (context, child) => SystemBarsStyle(child: child ?? const SizedBox.shrink()),
            home: const SessionGate(),
          );
        },
      ),
    );
  }
}
