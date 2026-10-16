import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../widgets/ui.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final guest = context.watch<AuthState>().user == null;
    final pages = guest
        ? const [SearchScreen(), LoginRequired(title: 'ການຈອງຂອງຂ້ອຍ'), LoginRequired(title: 'ໂປຣໄຟລ໌')]
        : const [SearchScreen(), BookingsScreen(), ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: AppNavBar(
        index: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          NavItem(TablerIcons.search, 'ຄົ້ນຫາ'),
          NavItem(TablerIcons.calendar, 'ການຈອງ'),
          NavItem(TablerIcons.user_circle, 'ໂປຣໄຟລ໌'),
        ],
      ),
    );
  }
}
