import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/room_card.dart';
import '../widgets/ui.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'add_property_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId});
  final int roomId;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Room? room;
  bool loading = true;
  bool favorited = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthState>().api;
    final isTenant = context.read<AuthState>().user?.role == 'tenant';
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final loaded = await api.roomDetail(widget.roomId);
      var fav = false;
      if (isTenant) {
        fav = await api.isFavorite(widget.roomId);
      }
      setState(() {
        room = loaded;
        favorited = fav;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _askLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ກະລຸນາເຂົ້າສູ່ລະບົບກ່ອນ'),
        action: SnackBarAction(
          label: 'ເຂົ້າສູ່ລະບົບ',
          textColor: AppTheme.accentLight,
          onPressed: () => goToLogin(context),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (context.read<AuthState>().user == null) return _askLogin();
    final api = context.read<AuthState>().api;
    try {
      if (favorited) {
        await api.removeFavorite(widget.roomId);
      } else {
        await api.addFavorite(widget.roomId);
      }
      setState(() => favorited = !favorited);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _book() async {
    if (context.read<AuthState>().user == null) return _askLogin();
    try {
      await context.read<AuthState>().api.createBooking(widget.roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ສົ່ງຄຳຂໍຈອງແລ້ວ ລໍຖ້າເຈົ້າຂອງຢືນຢັນ')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editRoom() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => AddPropertyScreen(editRoom: room),
    ));
    if (saved == true && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ບັນທຶກການແກ້ໄຂຫ້ອງແລ້ວ')),
        );
      }
    }
  }

  Future<void> _deleteRoom() async {
    final yes = await showDeleteConfirmationDialog(
      context: context,
      title: 'ລຶບຫ້ອງ?',
      description: 'ທ່ານຕ້ອງການລຶບຫ້ອງນີ້ບໍ?',
    );
    if (yes != true || !mounted) return;
    try {
      await context.read<AuthState>().api.deleteRoom(widget.roomId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _whatsapp() async {
    final phone =
        room?.property?.owner?.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ເຈົ້າຂອງຍັງບໍ່ໄດ້ລະບຸເບີໂທ')),
      );
      return;
    }
    final text = Uri.encodeComponent(
      'ສະບາຍດີ, ສົນໃຈຫ້ອງ ${room!.roomNumber} ທີ່ ${room!.property?.name}',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$text');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthState>().user?.role;
    final currentUser = context.watch<AuthState>().user;
    // Guests (role == null) see tenant actions; tapping them asks to log in.
    final tenantView = role == null || role == 'tenant';
    final c = Palette.of(context);
    if (loading) {
      return Scaffold(
        backgroundColor: c.card,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null || room == null) {
      return HeroScaffold(
        title: 'ລາຍລະອຽດຫ້ອງ',
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: EmptyState(
            icon: TablerIcons.home_search,
            text: error ?? 'ບໍ່ພົບຫ້ອງ',
          ),
        ),
      );
    }
    final r = room!;
    final p = r.property;
    final ownerView = role == 'owner' && p?.ownerId == currentUser?.id;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.card,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  r.images.length > 1
                      ? PageView(
                          children: r.images
                              .map(
                                (e) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    RoomPhoto(path: e.imageUrl, iconSize: 64),
                                  ],
                                ),
                              )
                              .toList(),
                        )
                      : RoomPhoto(
                          path: r.images.isEmpty
                              ? null
                              : r.images.first.imageUrl,
                          iconSize: 64,
                        ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeroBackButton(solid: true),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: StatusBadge(label: roomStatusLabel(r.status), tone: roomTone(r.status)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (ownerView)
                    Positioned(right: 8, top: 76, child: PopupMenuButton<String>(
                              tooltip: 'ເມນູ',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(
                                TablerIcons.dots_vertical,
                                color: Colors.white,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') _editRoom();
                                if (value == 'delete') _deleteRoom();
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem<String>(
                                  value: 'edit', height: 48,
                                  child: Text('ແກ້ໄຂຫ້ອງ'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  height: 48,
                                  child: Text(
                                    'ລຶບຫ້ອງ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            )),
                  if (tenantView)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: CircleIconButton(
                        solid: true,
                        icon: favorited
                            ? TablerIcons.heart_filled
                            : TablerIcons.heart,
                        color: favorited
                            ? AppTheme.dangerFg
                            : AppTheme.textOnLight,
                        onTap: _toggleFavorite,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: c.card,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p != null)
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${lak.format(r.price)} ກີບ / ເດືອນ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: c.price,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ຫ້ອງ ${r.roomNumber} · ${r.roomType}',
                    style: TextStyle(color: Palette.of(context).muted),
                  ),
                  if (p != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(TablerIcons.map_pin, size: 16, color: c.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${p.address}, ${p.district}',
                            style: TextStyle(
                              color: Palette.of(context).muted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  Text(r.description ?? 'ບໍ່ມີລາຍລະອຽດເພີ່ມເຕີມ'),
                  const SizedBox(height: 18),
                  const SectionTitle('ສິ່ງອຳນວຍຄວາມສະດວກ'),
                  if (r.amenities.isEmpty)
                    Text(
                      '-',
                      style: TextStyle(color: Palette.of(context).muted),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: r.amenities
                          .map((a) => AmenityTag(a.name, large: true))
                          .toList(),
                    ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const AvatarCircle(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p?.owner?.name ?? 'ເຈົ້າຂອງຫ້ອງ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (p != null)
                                  Text(
                                    '${p.district}, ${p.province}',
                                    style: TextStyle(
                                      color: Palette.of(context).muted,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (tenantView)
                            Material(
                              color: c.tint,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'WhatsApp',
                                onPressed: _whatsapp,
                                icon: Icon(
                                  TablerIcons.message_circle,
                                  color: c.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: tenantView
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton(
                    onPressed: r.status == 'available' ? _book : null,
                    child: Text(
                      r.status == 'available' ? 'ຈອງຫ້ອງນີ້' : 'ຍັງຈອງບໍ່ໄດ້',
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
