import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar_circle.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Row(
            children: [
              AvatarCircle(label: 'Você', size: 56),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Você', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('voce@email.com', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionLabel('Aparência'),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedChoice<ThemeMode>(
              value: appState.themeMode,
              options: const [(ThemeMode.light, 'Claro'), (ThemeMode.dark, 'Escuro')],
              onChanged: (mode) => context.read<AppState>().setThemeMode(mode),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disponível quando houver login.')),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
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
