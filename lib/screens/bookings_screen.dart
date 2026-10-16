import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/room_card.dart';
import '../widgets/ui.dart';
import 'room_detail_screen.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> bookings = [];
  bool loading = true;
  String? error;
  int tab = 0;

  bool get isOwner => context.read<AuthState>().user?.role == 'owner';

  // Tenants get three tabs; rejected bookings appear under the last one,
  // each card's badge still says whether it was rejected or cancelled.
  List<(String, List<String>)> get tabs => isOwner
      ? const [
          ('ລໍຖ້າຢືນຢັນ', ['pending']),
          ('ຢືນຢັນແລ້ວ', ['confirmed']),
          ('ປະຕິເສດ', ['rejected']),
          ('ຍົກເລີກ', ['cancelled']),
        ]
      : const [
          ('ລໍຖ້າຢືນຢັນ', ['pending']),
          ('ຢືນຢັນແລ້ວ', ['confirmed']),
          ('ຍົກເລີກ', ['cancelled', 'rejected']),
        ];

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
      final api = context.read<AuthState>().api;
      bookings = isOwner ? await api.ownerBookings() : await api.myBookings();
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    _load();
  }

  void _openRoom(Booking b) {
    if (b.room == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailScreen(roomId: b.room!.id)));
  }

  @override
  Widget build(BuildContext context) {
    final statuses = tabs[tab].$2;
    final items = bookings.where((b) => statuses.contains(b.status)).toList();
    return HeroScaffold(
      title: isOwner ? 'ຄຳຂໍຈອງທີ່ໄດ້ຮັບ' : 'ການຈອງຂອງຂ້ອຍ',
      trailingIcon: isOwner ? TablerIcons.inbox : TablerIcons.calendar,
      body: Column(
        children: [
          const SizedBox(height: 16),
          PillTabs(labels: tabs.map((t) => t.$1).toList(), index: tab, onChanged: (i) => setState(() => tab = i)),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null)
                    Text(error!, style: TextStyle(color: Palette.of(context).danger))
                  else ...[
                    if (!isOwner && tab == 0) ...[
                      const InfoBox(icon: TablerIcons.clock, text: 'ເຈົ້າຂອງຫ້ອງຈະຢືນຢັນພາຍໃນ 24 ຊົ່ວໂມງ'),
                      const SizedBox(height: 12),
                    ],
                    if (items.isEmpty)
                      const EmptyState(icon: TablerIcons.calendar_off, text: 'ຍັງບໍ່ມີລາຍການ')
                    else
                      ...items.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: isOwner ? _ownerCard(b) : _tenantCard(b),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerCard(Booking b) {
    final api = context.read<AuthState>().api;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.room?.property?.name ?? 'ຫ້ອງ ${b.roomId}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                  ),
                ),
                StatusBadge(label: bookingLabel(b.status), tone: bookingTone(b.status)),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(TablerIcons.door, 'ຫ້ອງ ${b.room?.roomNumber ?? '-'}'),
            _infoRow(TablerIcons.cash, '${lak.format(b.room?.price ?? 0)} ກີບ / ເດືອນ'),
            if (b.tenant != null) _infoRow(TablerIcons.user, '${b.tenant!.name} (${b.tenant!.phone ?? '-'})'),
            _infoRow(TablerIcons.clock, _dateFormat.format(b.createdAt.toLocal())),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: b.room == null ? null : () => _openRoom(b), child: const Text('ເບິ່ງຫ້ອງ')),
                const Spacer(),
                if (b.status == 'pending') ...[
                  FilledButton(
                    style: dangerButtonStyle,
                    onPressed: () => _run(() => api.rejectBooking(b.id)),
                    child: const Text('ປະຕິເສດ'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: compactPrimaryStyle,
                    onPressed: () => _run(() => api.confirmBooking(b.id)),
                    child: const Text('ຢືນຢັນ'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tenantCard(Booking b) {
    final room = b.room;
    final property = room?.property;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RoomPhoto(path: room != null && room.images.isNotEmpty ? room.images.first.imageUrl : null),
                Positioned(
                  top: 10,
                  right: 10,
                  child: StatusBadge(label: bookingLabel(b.status), tone: bookingTone(b.status)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property?.name ?? 'ຫ້ອງ ${b.roomId}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                ),
                Text(
                  '${lak.format(room?.price ?? 0)} ກີບ / ເດືອນ',
                  style: TextStyle(color: Palette.of(context).price, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (property != null) property.district,
                    if (room != null) 'ຫ້ອງ ${room.roomNumber} · ${room.roomType}',
                  ].join(' · '),
                  style: TextStyle(color: Palette.of(context).muted, fontSize: 14),
                ),
                Text(
                  'ວັນທີຂໍ: ${_dateFormat.format(b.createdAt.toLocal())}',
                  style: TextStyle(color: Palette.of(context).muted, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: compactOutlinedStyle,
                        onPressed: room == null ? null : () => _openRoom(b),
                        child: const Text('ເບິ່ງລາຍລະອຽດ'),
                      ),
                    ),
                    if (b.status == 'pending') ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        style: dangerButtonStyle,
                        onPressed: () => _run(() => context.read<AuthState>().api.cancelBooking(b.id)),
                        child: const Text('ຍົກເລີກ'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Palette.of(context).muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
