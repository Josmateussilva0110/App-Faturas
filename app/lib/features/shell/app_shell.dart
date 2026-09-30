import 'package:flutter/material.dart';

import '../cards/cards_screen.dart';
import '../home/home_screen.dart';
import '../monthly/monthly_screen.dart';
import '../people/people_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/floating_nav_bar.dart';

/// Bottom-navigation shell holding the app's five tabs. "Nova compra" fica
/// no card da Home, não num FAB aqui.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    MonthlyScreen(),
    PeopleScreen(),
    CardsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      // O corpo passa por trás da barra: ela flutua, e o fundo da página
      // aparece em volta da pílula. O Scaffold soma a altura da barra ao
      // padding do corpo, então o SafeArea das telas já desvia dela.
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
        destinations: const [
          (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Início'),
          (icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Meses'),
          (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Pessoas'),
          (icon: Icons.credit_card_outlined, selectedIcon: Icons.credit_card, label: 'Cartões'),
          (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
        ],
      ),
    );
  }
}
