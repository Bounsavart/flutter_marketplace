import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../theme.dart';
import '../widgets/auth_layout.dart';
import 'register_role_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return AuthLayout(
      icon: TablerIcons.home,
      title: 'ຍິນດີຕ້ອນຮັບ',
      subtitle: 'ຄົ້ນຫາ ຫຼື ປ່ອຍເຊົ່າຫ້ອງໃນວຽງຈັນ',
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'ອີເມວ', prefixIcon: Icon(TablerIcons.mail)),
                validator: (v) => v == null || !v.contains('@') ? 'ກະລຸນາປ້ອນອີເມວໃຫ້ຖືກຕ້ອງ' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'ລະຫັດຜ່ານ', prefixIcon: Icon(TablerIcons.lock)),
                validator: (v) => v == null || v.length < 6 ? 'ລະຫັດຜ່ານຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ' : null,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            // No password-reset flow exists in the backend yet.
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('ຟັງຊັນລືມລະຫັດຜ່ານຍັງບໍ່ທັນພ້ອມໃຊ້ງານ'))),
            child: const Text('ລືມລະຫັດຜ່ານ?', style: TextStyle(fontSize: 13)),
          ),
        ),
        if (auth.error != null) ...[
          Text(auth.error!, style: TextStyle(color: Palette.of(context).danger)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        FilledButton(
          onPressed: auth.busy
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;
                  await auth.login(email.text.trim(), password.text);
                },
          child: auth.busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('ເຂົ້າສູ່ລະບົບ'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterRoleScreen()));
          },
          child: const Text('ສະໝັກສະມາຊິກ'),
        ),
        const SizedBox(height: 26),
        const SocialConnect(),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: auth.browseAsGuest,
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
            child: const Text('ຂ້າມ', style: TextStyle(fontSize: 13, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}
