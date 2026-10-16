import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../widgets/ui.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: const [AdminDashboardScreen(), ProfileScreen()]),
      bottomNavigationBar: AppNavBar(
        index: index,
        onTap: (i) => setState(() => index = i),
        items: const [NavItem(TablerIcons.shield_check, 'ກວດສອບ'), NavItem(TablerIcons.user_circle, 'ໂປຣໄຟລ໌')],
      ),
    );
  }
}
