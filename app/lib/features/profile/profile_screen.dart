import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/form_section_card.dart';
import '../../widgets/section_label.dart';
import '../../widgets/segmented_choice.dart';
import '../onboarding/welcome_screen.dart';

/// The "Perfil" tab: the signed-in account (from `GET /profile`), theme
/// choice, and sign out. "Sair da conta" revokes the token on the backend,
/// drops the stored session and clears the loaded state before returning to
/// the welcome screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);

    // Best effort: revoking server-side can fail (offline, token already
    // expired), but the local session has to go either way.
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
    final appState = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: scheme.surfaceContainerLow,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FormSectionCard(
            child: Row(
              children: [
                AvatarCircle(label: appState.currentUser.name, size: 56),
                const SizedBox(width: AppSpacing.mdPlus),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appState.currentUser.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    // When the account has no username the name already *is*
                    // the email — no point printing it twice.
                    if (appState.currentUser.name != appState.currentUser.email)
                      Text(appState.currentUser.email, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionLabel('Aparência', icon: Icons.palette_outlined, iconColor: scheme.primary),
                const SizedBox(height: AppSpacing.md),
                SegmentedChoice<ThemeMode>(
                  value: appState.themeMode,
                  options: const [(ThemeMode.light, 'Claro'), (ThemeMode.dark, 'Escuro')],
                  icons: const [Icons.light_mode_outlined, Icons.dark_mode_outlined],
                  onChanged: (mode) => context.read<AppState>().setThemeMode(mode),
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  fontSize: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signingOut ? null : _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                alignment: Alignment.centerLeft,
              ),
              icon: _signingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.logout),
              label: Text(_signingOut ? 'Saindo...' : 'Sair da conta'),
            ),
          ),
        ],
      ),
    );
  }
}
