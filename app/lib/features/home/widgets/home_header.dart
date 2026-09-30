import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/avatar_circle.dart';

/// Saudação no topo da Home: avatar, a data de hoje e o primeiro nome.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name, required this.today});

  final String name;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().split(' ').first;

    return Row(
      children: [
        AvatarCircle(label: name, size: 44),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDayLabel(today), style: context.text.caption),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                firstName.isEmpty ? 'Olá!' : 'Olá, $firstName',
                overflow: TextOverflow.ellipsis,
                style: context.text.label.copyWith(fontSize: 17),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
