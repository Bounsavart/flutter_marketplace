import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../widgets/ui.dart';
import 'bookings_screen.dart';
import 'owner_dashboard_screen.dart';
import 'profile_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [OwnerDashboardScreen(), BookingsScreen(), ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: AppNavBar(
        index: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          NavItem(TablerIcons.layout_grid, 'ແດຊບອດ'),
          NavItem(TablerIcons.inbox, 'ຄຳຂໍຈອງ'),
          NavItem(TablerIcons.user_circle, 'ໂປຣໄຟລ໌'),
        ],
      ),
    );
  }
}
