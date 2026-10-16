import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../theme.dart';
import '../theme_controller.dart';
import '../widgets/ui.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _deleteAccount(BuildContext context, AuthState auth) async {
    if (await showDeleteConfirmationDialog(
              context: context,
              title: 'ລຶບບັນຊີ?',
              description: 'ທ່ານຕ້ອງການລຶບບັນຊີນີ້ບໍ?',
              deleteLabel: 'ລຶບບັນຊີ',
            ) !=
            true ||
        !context.mounted) {
      return;
    }
    if (await showDeleteConfirmationDialog(
              context: context,
              title: 'ຢືນຢັນການລຶບບັນຊີອີກຄັ້ງ',
              description: 'ບັນຊີ ແລະ ຂໍ້ມູນຂອງທ່ານຈະຖືກລຶບ. ຢືນຢັນບໍ?',
              deleteLabel: 'ລຶບບັນຊີ',
            ) !=
            true ||
        !context.mounted) {
      return;
    }
    try {
      await auth.api.deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ລຶບບັນຊີແລ້ວ')));
      }
      await auth.logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = context.watch<ThemeController>();
    final c = Palette.of(context);
    final user = auth.user;
    if (user == null) return const SizedBox();
    return HeroScaffold(
      title: 'ໂປຣໄຟລ໌',
      trailingIcon: TablerIcons.user_circle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AvatarCircle(
                    text: user.name.characters.firstOrNull,
                    size: 60,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: c.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                          label: roleLabel(user.role),
                          tone: Tone.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user.role == 'tenant') ...[
            const SizedBox(height: 12),
            StatGrid(
              columns: 2,
              children: [
                StatCard(
                  value: '${user.favoriteCount}',
                  label: 'ຫ້ອງທີ່ບັນທຶກ',
                ),
                StatCard(value: '${user.bookingCount}', label: 'ການຈອງ'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (user.role == 'tenant') ...[
                  ListTile(
                    leading: Icon(TablerIcons.heart, color: c.accent),
                    title: const Text('ລາຍການທີ່ມັກ'),
                    trailing: Icon(
                      TablerIcons.chevron_right,
                      color: Palette.of(context).muted,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                  ),
                  const Divider(indent: 56),
                ],
                SwitchListTile(
                  secondary: Icon(
                    theme.isDark ? TablerIcons.moon : TablerIcons.sun,
                    color: c.accent,
                  ),
                  title: const Text('ໂໝດມືດ'),
                  value: theme.isDark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.primary,
                  onChanged: theme.setDark,
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: Icon(TablerIcons.logout, color: Tone.danger.fgOn(c)),
                  title: Text(
                    'ອອກຈາກລະບົບ',
                    style: TextStyle(color: Tone.danger.fgOn(c)),
                  ),
                  onTap: auth.logout,
                ),
              ],
            ),
          ),
          if (user.role == 'tenant' || user.role == 'owner') ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: dangerButtonStyle,
              onPressed: () => _deleteAccount(context, auth),
              icon: const Icon(TablerIcons.trash),
              label: const Text('ລຶບບັນຊີຂອງຂ້ອຍ'),
            ),
          ],
        ],
      ),
    );
  }
}
