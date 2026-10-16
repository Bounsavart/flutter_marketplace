import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../constants/stat_colors.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'add_property_screen.dart';
import 'room_detail_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<Property> properties = [];
  bool loading = true;
  String? error;

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
    try {
      properties = await context.read<AuthState>().api.myProperties();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openAddProperty([Property? existing]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPropertyScreen(existing: existing)),
    );
    _load();
  }

  Future<void> _deleteProperty(Property property) async {
    final ok = await showDeleteConfirmationDialog(
      context: context,
      title: 'ລຶບທີ່ພັກ?',
      description: 'ທ່ານຕ້ອງການລຶບທີ່ພັກນີ້ບໍ? ຈະລຶບຫ້ອງທັງໝົດພາຍໃນທີ່ພັກນຳ.',
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthState>().api.deleteProperty(property.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ລຶບທີ່ພັກແລ້ວ')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = properties.expand((p) => p.rooms).toList();
    final available = rooms.where((r) => r.status == 'available').length;
    final pending = rooms.where((r) => r.status == 'pending').length;
    return HeroScaffold(
      eyebrow: 'ແດຊບອດເຈົ້າຂອງຫ້ອງ',
      title: 'ຈັດການທີ່ພັກ ແລະ ຫ້ອງ',
      trailingIcon: TablerIcons.building_estate,
      floatingActionButton: AppFab(
        icon: TablerIcons.plus,
        label: 'ເພີ່ມທີ່ພັກ',
        onPressed: _openAddProperty,
      ),
      pinned: Padding(
        padding: const EdgeInsets.all(12),
        child: StatGrid(
          columns: 2,
          gap: 8,
          children: [
            StatCard(
              value: '${properties.length}',
              label: 'ທີ່ພັກ',
              icon: TablerIcons.home_2,
              color: StatColor.coral,
              horizontal: true,
            ),
            StatCard(
              value: '${rooms.length}',
              label: 'ຫ້ອງທັງໝົດ',
              icon: TablerIcons.door,
              color: StatColor.teal,
              horizontal: true,
            ),
            StatCard(
              value: '$available',
              label: 'ຫວ່າງ',
              icon: TablerIcons.home_check,
              color: StatColor.green,
              horizontal: true,
            ),
            StatCard(
              value: '$pending',
              label: 'ລໍຢືນຢັນ',
              icon: TablerIcons.clock_hour_4,
              color: StatColor.amber,
              horizontal: true,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          // Bottom padding keeps the last card clear of the FAB.
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 88),
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: TextStyle(color: Palette.of(context).danger)),
            const SectionTitle('ທີ່ພັກຂອງຂ້ອຍ', size: 15),
            if (properties.isEmpty && !loading)
              const EmptyState(
                icon: TablerIcons.building,
                text: 'ຍັງບໍ່ມີປະກາດ ກົດປຸ່ມເພີ່ມທີ່ພັກດ້ານລຸ່ມ',
              ),
            ...properties.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PropertyCard(
                  property: p,
                  onAddRoom: () => _openAddProperty(p),
                  onDeleteProperty: () => _deleteProperty(p),
                  onOpenRoom: (r) async {
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailScreen(roomId: r.id),
                      ),
                    );
                    if (deleted == true) _load();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.onAddRoom,
    required this.onOpenRoom,
    required this.onDeleteProperty,
  });

  final Property property;
  final VoidCallback onAddRoom;
  final ValueChanged<Room> onOpenRoom;
  final VoidCallback onDeleteProperty;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final p = property;
    final tone = p.approvalStatus == 'approved'
        ? Tone.purple
        : approvalTone(p.approvalStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 8),
                StatusBadge(label: approvalLabel(p.approvalStatus), tone: tone),
                PopupMenuButton<String>(
                  tooltip: 'ເມນູ',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(TablerIcons.dots_vertical),
                  onSelected: (value) {
                    if (value == 'delete') onDeleteProperty();
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(TablerIcons.map_pin, size: 15, color: c.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${p.district}, ${p.province}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.muted, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                for (final r in p.rooms)
                  TapTarget(
                    onTap: () => onOpenRoom(r),
                    child: Material(
                      color: c.tint,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Text(
                          '${r.roomNumber} · ${roomStatusLabel(r.status)}',
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: onAddRoom,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('+ ເພີ່ມຫ້ອງ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
