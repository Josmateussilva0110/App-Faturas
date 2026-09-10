import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/toast/app_toast.dart';
import 'data/api/auth_storage.dart';
import 'data/api/secure_auth_storage.dart';
import 'data/api_fatura_repository.dart';
import 'features/shell/session_gate.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // From here on the session survives restarts; tests swap this for an
  // in-memory implementation.
  authStorage = SecureAuthStorage();
  runApp(const FaturaApp());
}

class FaturaApp extends StatelessWidget {
  const FaturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // `load` runs only once a session exists — see SessionGate.
      create: (_) => AppState(ApiFaturaRepository()),
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
