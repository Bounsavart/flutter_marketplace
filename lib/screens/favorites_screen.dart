import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../models.dart';
import '../widgets/room_card.dart';
import '../widgets/ui.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'room_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Room> rooms = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    rooms = await context.read<AuthState>().api.myFavorites();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      title: 'ລາຍການທີ່ບັນທຶກ',
      trailingIcon: TablerIcons.heart,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rooms.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: EmptyState(
                  icon: TablerIcons.heart,
                  text: 'ຍັງບໍ່ມີຫ້ອງທີ່ບັນທຶກ',
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => Column(
                children: [
                  RoomCard(
                    room: rooms[i],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(roomId: rooms[i].id),
                        ),
                      );
                      _load();
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(TablerIcons.trash, color: Colors.red),
                      label: const Text('ລຶບອອກຈາກລາຍການມັກ'),
                      onPressed: () async {
                        final yes = await showDeleteConfirmationDialog(
                          context: context,
                          title: 'ລຶບລາຍການມັກ?',
                          description:
                              'ທ່ານຕ້ອງການລຶບຫ້ອງນີ້ອອກຈາກລາຍການມັກບໍ?',
                        );
                        if (yes != true || !context.mounted) return;
                        try {
                          await context.read<AuthState>().api.removeFavorite(
                            rooms[i].id,
                          );
                          await _load();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ລຶບລາຍການມັກແລ້ວ')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
