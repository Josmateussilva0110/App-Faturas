import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';
import '../../state/app_state.dart';
import '../onboarding/welcome_screen.dart';
import 'app_entry.dart';

/// First screen at boot. Tries to bring back the stored session — refreshing
/// it when the access token has expired — and sends the user straight into
/// the app when that works. Only a missing or rejected session lands on
/// [WelcomeScreen], so signing in is something the user does once, until
/// they sign out.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _restored = _restore();

  Future<bool> _restore() async {
    final session = await restoreSession();
    if (session == null || !mounted) return false;

    // The session is active now, so `AppState.load` can already call the
    // authenticated endpoints.
    await context.read<AppState>().load();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restored,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data ?? false ? const AppEntry() : const WelcomeScreen();
      },
    );
  }
}
