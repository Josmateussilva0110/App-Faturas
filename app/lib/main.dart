import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/mock_fatura_repository.dart';
import 'features/shell/app_shell.dart';
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
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appState.themeMode,
            home: appState.isLoading
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : const AppShell(),
          );
        },
      ),
    );
  }
}
