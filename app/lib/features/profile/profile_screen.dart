import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/form_section_card.dart';
import '../../widgets/section_label.dart';
import '../../widgets/segmented_choice.dart';

/// The "Perfil" tab: placeholder account info, theme choice, and sign out.
/// The account fields are static today — they'll come from the backend's
/// auth session once one exists.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(appState.currentUser.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disponível quando houver login.')),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                alignment: Alignment.centerLeft,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ),
        ],
      ),
    );
  }
}
