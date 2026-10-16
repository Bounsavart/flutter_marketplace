import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../notification_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'admin_dashboard_screen.dart';
import 'bookings_screen.dart';
import 'owner_dashboard_screen.dart';

String notificationTitle(String type, Map<String, dynamic> data) {
  final party = (data['tenant_name'] ?? data['owner_name'] ?? '').toString();
  final property = (data['property_name'] ?? 'ທີ່ພັກ').toString();
  final room = (data['room_number'] ?? '').toString();
  final place = [property, if (room.isNotEmpty) 'ຫ້ອງ $room'].join(' · ');
  switch (type) {
    case 'booking_requested': return '$party ສົ່ງຄຳຂໍຈອງ $place';
    case 'booking_cancelled_by_tenant': return '$party ຍົກເລີກຄຳຂໍຈອງ $place';
    case 'booking_confirmed': return 'ຄຳຂໍຈອງ $place ໄດ້ຮັບການຢືນຢັນ';
    case 'booking_rejected': return 'ຄຳຂໍຈອງ $place ຖືກປະຕິເສດ';
    case 'booking_auto_cancelled': return 'ຄຳຂໍຈອງ $place ໝົດເວລາແລ້ວ';
    case 'booking_cancelled_by_system': return 'ການຈອງ $place ຖືກຍົກເລີກ';
    case 'property_approved': return 'ທີ່ພັກ $property ໄດ້ຮັບການອະນຸມັດ';
    case 'property_rejected': return 'ທີ່ພັກ $property ຖືກປະຕິເສດ';
    case 'property_pending_review': return 'ມີທີ່ພັກໃໝ່ລໍຖ້າກວດສອບ: $property';
    default: return 'ມີການແຈ້ງເຕືອນໃໝ່';
  }
}

String _relativeTime(DateTime time) {
  final delta = DateTime.now().difference(time);
  if (delta.inMinutes < 1) return 'ຫາກໍ່ຜ່ານມາ';
  if (delta.inHours < 1) return '${delta.inMinutes} ນາທີກ່ອນ';
  if (delta.inDays < 1) return '${delta.inHours} ຊົ່ວໂມງກ່ອນ';
  if (delta.inDays < 30) return '${delta.inDays} ມື້ກ່ອນ';
  return '${(delta.inDays / 30).floor()} ເດືອນກ່ອນ';
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 250) context.read<NotificationService>().loadMore();
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _open(Map<String, dynamic> item) async {
    final service = context.read<NotificationService>();
    final type = item['type'] as String? ?? '';
    await service.markRead((item['id'] as num).toInt());
    if (!mounted) return;
    final role = context.read<AuthState>().user?.role;
    final data = Map<String, dynamic>.from(item['data'] as Map? ?? {});
    final api = context.read<AuthState>().api;
    final roomId = data['room_id'] is num ? (data['room_id'] as num).toInt() : null;
    final propertyId = data['property_id'] is num ? (data['property_id'] as num).toInt() : null;
    final exists = roomId != null
        ? await api.notificationRoomExists(roomId)
        : propertyId != null
            ? await api.notificationPropertyExists(propertyId)
            : true;
    if (!exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ຫ້ອງ ຫຼື ທີ່ພັກຖືກລຶບແລ້ວ')));
    }
    if (!mounted) return;
    Widget? destination;
    if (['booking_requested', 'booking_cancelled_by_tenant'].contains(type) && role == 'owner') destination = const BookingsScreen();
    if (['booking_confirmed', 'booking_rejected', 'booking_auto_cancelled', 'booking_cancelled_by_system'].contains(type) && role == 'tenant') destination = const BookingsScreen();
    if (['property_approved', 'property_rejected'].contains(type) && role == 'owner') destination = const OwnerDashboardScreen();
    if (type == 'property_pending_review' && role == 'admin') destination = const AdminDashboardScreen();
    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ບໍ່ສາມາດເປີດລາຍການນີ້ໄດ້')));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final c = Palette.of(context);
    return HeroScaffold(
      title: 'ການແຈ້ງເຕືອນ',
      body: RefreshIndicator(
        onRefresh: service.refresh,
        child: service.notifications.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyState(icon: TablerIcons.bell, text: 'ຍັງບໍ່ມີການແຈ້ງເຕືອນ')])
            : ListView.separated(
                controller: _scroll,
                itemCount: service.notifications.length + (service.loadingMore ? 1 : 0),
                separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                itemBuilder: (context, index) {
                  if (index == service.notifications.length) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                  final item = service.notifications[index];
                  final data = Map<String, dynamic>.from(item['data'] as Map? ?? {});
                  final read = item['is_read'] == true;
                  final time = DateTime.tryParse(item['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now();
                  return Material(
                    color: read ? c.card : c.tint,
                    child: InkWell(
                      onTap: () => _open(item),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 72),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Row(children: [
                            Icon(read ? TablerIcons.bell : TablerIcons.bell_ringing, color: read ? c.muted : c.accent),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(notificationTitle(item['type'] as String? ?? '', data), style: TextStyle(color: c.text, fontWeight: read ? FontWeight.normal : FontWeight.w600)),
                              const SizedBox(height: 4), Text(_relativeTime(time), style: TextStyle(color: c.muted, fontSize: 12)),
                            ])),
                            if (!read) Container(width: 9, height: 9, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      headerBottom: service.unreadCount > 0 ? Align(alignment: Alignment.centerRight, child: TextButton(onPressed: service.markAllRead, child: const Text('ອ່ານທັງໝົດ', style: TextStyle(color: Colors.white)))) : null,
    );
  }
}
