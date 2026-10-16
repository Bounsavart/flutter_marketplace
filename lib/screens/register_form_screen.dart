import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../theme.dart';
import '../widgets/auth_layout.dart';

class RegisterFormScreen extends StatefulWidget {
  const RegisterFormScreen({super.key, required this.role});
  final String role;

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isTenant = widget.role == 'tenant';
    return AuthLayout(
      icon: isTenant ? TablerIcons.search : TablerIcons.building,
      title: isTenant ? 'ສະໝັກເປັນຜູ້ເຊົ່າ' : 'ສະໝັກເປັນເຈົ້າຂອງຫ້ອງ',
      subtitle: 'ປ້ອນຂໍ້ມູນຂອງທ່ານລຸ່ມນີ້',
      step: 1,
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(hintText: 'ຊື່ ແລະ ນາມສະກຸນ', prefixIcon: Icon(TablerIcons.user)),
                validator: (v) => v == null || v.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'ອີເມວ', prefixIcon: Icon(TablerIcons.mail)),
                validator: (v) => v == null || !v.contains('@') ? 'ກະລຸນາປ້ອນອີເມວ' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'ເບີໂທ (WhatsApp)', prefixIcon: Icon(TablerIcons.phone)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'ລະຫັດຜ່ານ', prefixIcon: Icon(TablerIcons.lock)),
                validator: (v) => v == null || v.length < 6 ? 'ຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ' : null,
              ),
            ],
          ),
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          Text(auth.error!, style: TextStyle(color: Palette.of(context).danger)),
        ],
        const SizedBox(height: 16),
        Text(
          'ການສ້າງບັນຊີ ຖືວ່າທ່ານຍອມຮັບເງື່ອນໄຂການນຳໃຊ້ ແລະ ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.of(context).muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: auth.busy
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;
                  await auth.register(
                    name: name.text.trim(),
                    email: email.text.trim(),
                    password: password.text,
                    role: widget.role,
                    phone: phone.text.trim(),
                  );
                  if (auth.user != null && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
          child: auth.busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('ສ້າງບັນຊີ'),
        ),
        const SizedBox(height: 26),
        const SocialConnect(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ມີບັນຊີແລ້ວ?', style: TextStyle(color: Palette.of(context).muted, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('ເຂົ້າສູ່ລະບົບ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    );
  }
}
