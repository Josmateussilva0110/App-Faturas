import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'app_shell.dart';

/// Gate between the login screen and the app itself: holds a spinner until
/// [AppState.load] has finished, since every tab reads data (and
/// `currentUser`) that only exists once the load completes.
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AppState, bool>((state) => state.isLoading);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const AppShell();
  }
}
