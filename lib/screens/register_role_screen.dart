import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/ui.dart';
import 'register_form_screen.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(String role) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterFormScreen(role: role)));
    return AuthLayout(
      icon: TablerIcons.user_plus,
      title: 'ເລືອກບົດບາດ',
      subtitle: 'ທ່ານຕ້ອງການໃຊ້ແອັບໃນຖານະໃດ?',
      step: 0,
      children: [
        _RoleCard(
          icon: TablerIcons.search,
          title: 'ຊອກຫາຫ້ອງເຊົ່າ',
          subtitle: 'ຄົ້ນຫາ, ບັນທຶກລາຍການທີ່ມັກ ແລະ ສົ່ງຄຳຂໍຈອງ',
          onTap: () => open('tenant'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: TablerIcons.building,
          title: 'ປ່ອຍເຊົ່າ',
          subtitle: 'ລົງປະກາດທີ່ພັກ, ຈັດການຫ້ອງ ແລະ ຮັບຄຳຂໍຈອງ',
          onTap: () => open('owner'),
        ),
        const SizedBox(height: 20),
        const InfoBox(icon: TablerIcons.alert_triangle, text: 'ບໍ່ສາມາດປ່ຽນບົດບາດໄດ້ຫຼັງຈາກສະໝັກແລ້ວ'),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarCircle(icon: icon, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: TextStyle(color: Palette.of(context).muted, fontSize: 13)),
                  ],
                ),
              ),
              Icon(TablerIcons.chevron_right, color: Palette.of(context).muted),
            ],
          ),
        ),
      ),
    );
  }
}
