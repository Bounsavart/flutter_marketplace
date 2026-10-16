import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../constants/stat_colors.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'room_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> stats = {};
  List<Property> pending = [];
  List<Property> allProperties = [];
  List<AppUser> users = [];
  bool loading = true;
  String? error;
  final NumberFormat _lak = NumberFormat.decimalPattern();
  final Set<int> _expandedPendingProperties = {};

  void _openRoom(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomDetailScreen(roomId: room.id)),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final api = context.read<AuthState>().api;
    try {
      stats = await api.adminStats();
      pending = await api.pendingProperties();
      allProperties = await api.allProperties();
      users = await api.adminUsers();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    _load();
  }

  Future<void> _deleteUser(int id) async {
    try {
      await context.read<AuthState>().api.adminDeleteUser(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ລຶບບັນຊີແລ້ວ')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteListing({required int id, required bool property}) async {
    final yes = await showDeleteConfirmationDialog(
      context: context,
      title: property ? 'ລຶບທີ່ພັກ?' : 'ລຶບຫ້ອງ?',
      description: property
          ? 'ທ່ານຕ້ອງການລຶບທີ່ພັກນີ້ບໍ?'
          : 'ທ່ານຕ້ອງການລຶບຫ້ອງນີ້ບໍ?',
      warning: property
          ? 'ການຈອງທີ່ລໍຖ້າ ຫຼື ຢືນຢັນແລ້ວໃນທີ່ພັກນີ້ຈະຖືກຍົກເລີກອັດຕະໂນມັດ.'
          : 'ການຈອງທີ່ລໍຖ້າ ຫຼື ຢືນຢັນແລ້ວໃນຫ້ອງນີ້ຈະຖືກຍົກເລີກອັດຕະໂນມັດ.',
    );
    if (yes != true || !mounted) return;
    try {
      if (property) {
        await context.read<AuthState>().api.deleteProperty(id);
      } else {
        await context.read<AuthState>().api.deleteRoom(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(property ? 'ລຶບທີ່ພັກແລ້ວ' : 'ລຶບຫ້ອງແລ້ວ')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Tone _roleTone(String role) {
    switch (role) {
      case 'owner':
        return Tone.purple;
      case 'tenant':
        return Tone.warning;
      default:
        return Tone.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final api = context.read<AuthState>().api;
    String stat(String key) => '${stats[key] ?? 0}';
    return HeroScaffold(
      eyebrow: 'ແດຊບອດຜູ້ດູແລລະບົບ',
      title: 'ກວດສອບ ແລະ ຜູ້ໃຊ້',
      trailingIcon: TablerIcons.shield_check,
      pinned: Padding(
        padding: const EdgeInsets.all(12),
        child: StatGrid(
          columns: 2,
          gap: 8,
          children: [
            StatCard(
              value: stat('users'),
              label: 'ຜູ້ໃຊ້ທັງໝົດ',
              icon: TablerIcons.users,
              color: StatColor.blue,
              horizontal: true,
            ),
            StatCard(
              value: stat('owners'),
              label: 'ເຈົ້າຂອງ',
              icon: TablerIcons.building,
              color: StatColor.purple,
              horizontal: true,
            ),
            StatCard(
              value: stat('tenants'),
              label: 'ຜູ້ເຊົ່າ',
              icon: TablerIcons.user_check,
              color: StatColor.teal,
              horizontal: true,
            ),
            StatCard(
              value: stat('properties'),
              label: 'ທີ່ພັກ',
              icon: TablerIcons.home_2,
              color: StatColor.coral,
              horizontal: true,
            ),
            StatCard(
              value: stat('pendingProperties'),
              label: 'ລໍກວດສອບ',
              icon: TablerIcons.clock_exclamation,
              color: StatColor.amber,
              horizontal: true,
            ),
            StatCard(
              value: stat('rooms'),
              label: 'ຫ້ອງ',
              icon: TablerIcons.door,
              color: StatColor.green,
              horizontal: true,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: TextStyle(color: Palette.of(context).danger)),
            // The approval queue stays so admins can still act on pending listings.
            if (pending.isNotEmpty) ...[
              const SectionTitle('ປະກາດລໍຖ້າກວດສອບ', size: 15),
              ...pending.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                label: approvalLabel(p.approvalStatus),
                                tone: approvalTone(p.approvalStatus),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                TablerIcons.map_pin,
                                size: 15,
                                color: c.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${p.district}, ${p.province}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ເຈົ້າຂອງ: ${p.owner?.name ?? '-'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          ...p.rooms
                              .take(
                                _expandedPendingProperties.contains(p.id)
                                    ? p.rooms.length
                                    : 3,
                              )
                              .map(
                                (room) => Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openRoom(room),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 48,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'ຫ້ອງ ${room.roomNumber} · ${room.roomType} · ${_lak.format(room.price)} ກີບ',
                                            ),
                                          ),
                                          Icon(
                                            TablerIcons.chevron_right,
                                            size: 18,
                                            color: c.muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          if (p.rooms.length > 3)
                            TextButton(
                              onPressed: () => setState(() {
                                if (!_expandedPendingProperties.add(p.id)) {
                                  _expandedPendingProperties.remove(p.id);
                                }
                              }),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              child: Text(
                                _expandedPendingProperties.contains(p.id)
                                    ? 'ສະແດງໜ້ອຍລົງ'
                                    : 'ເບິ່ງທັງໝົດ',
                              ),
                            ),
                          if (p.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              p.description!,
                              style: TextStyle(fontSize: 14, color: c.muted),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton(
                                style: dangerButtonStyle,
                                onPressed: () =>
                                    _run(() => api.rejectProperty(p.id)),
                                child: const Text('ປະຕິເສດ'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                style: compactPrimaryStyle,
                                onPressed: () =>
                                    _run(() => api.approveProperty(p.id)),
                                child: const Text('ອະນຸມັດ'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SectionTitle('ທີ່ພັກ ແລະ ຫ້ອງທັງໝົດ', size: 15),
            if (allProperties.isEmpty && !loading)
              const EmptyState(icon: TablerIcons.building, text: 'ບໍ່ມີທີ່ພັກ')
            else
              ...allProperties.map(
                (property) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'ເມນູ',
                              icon: const Icon(TablerIcons.dots_vertical),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteListing(
                                    id: property.id,
                                    property: true,
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  height: 48,
                                  child: Text(
                                    'ລຶບທີ່ພັກ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        for (final room in property.rooms)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openRoom(room),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'ຫ້ອງ ${room.roomNumber} · ${room.roomType} · ${_lak.format(room.price)} ກີບ',
                                      ),
                                    ),
                                    Icon(
                                      TablerIcons.chevron_right,
                                      size: 18,
                                      color: c.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SectionTitle('ຜູ້ໃຊ້ໃນລະບົບ', size: 15),
            if (users.isEmpty && !loading)
              const EmptyState(icon: TablerIcons.users, text: 'ຍັງບໍ່ມີຜູ້ໃຊ້')
            else if (users.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < users.length; i++) ...[
                      if (i > 0) const Divider(indent: 64),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AvatarCircle(
                              text: users[i].name.characters.firstOrNull,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    users[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    users[i].email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.muted,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: roleLabel(users[i].role),
                              tone: _roleTone(users[i].role),
                            ),
                            if (users[i].role != 'admin' &&
                                users[i].id !=
                                    context.read<AuthState>().user?.id)
                              PopupMenuButton<String>(
                                tooltip: 'ເມນູ',
                                icon: const Icon(TablerIcons.dots_vertical),
                                onSelected: (value) async {
                                  if (value != 'delete') return;
                                  final user = users[i];
                                  final yes = await showDeleteConfirmationDialog(
                                    context: context,
                                    title: 'ລຶບບັນຊີ?',
                                    description: 'ລຶບບັນຊີ ${user.name} ບໍ?',
                                    warning: user.role == 'owner'
                                        ? 'ການຈອງທີ່ຍັງລໍຖ້າ ຫຼື ຢືນຢັນແລ້ວຈະຖືກຍົກເລີກອັດຕະໂນມັດ.'
                                        : 'ການຈອງທີ່ຍັງລໍຖ້າ ຫຼື ຢືນຢັນແລ້ວຈະຖືກຍົກເລີກ.',
                                  );
                                  if (yes == true) _deleteUser(user.id);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    height: 48,
                                    child: Text(
                                      'ລຶບບັນຊີ',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
