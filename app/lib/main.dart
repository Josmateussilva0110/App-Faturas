import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/toast/app_toast.dart';
import 'data/mock_fatura_repository.dart';
import 'features/onboarding/welcome_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(const FaturaApp());
}

class FaturaApp extends StatelessWidget {
  const FaturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(MockFaturaRepository())..load(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Fatura',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppToast.navigatorKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appState.themeMode,
            // The welcome screen doesn't need the loaded data, so it shows
            // right away while `AppState.load` runs in the background;
            // `AppEntry` (pushed after login) is what waits for it.
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
