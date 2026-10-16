import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../theme.dart';
import 'ui.dart';

final lak = NumberFormat.decimalPattern();

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final location = room.property == null
        ? ''
        : '${room.property!.district}, ${room.property!.province}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RoomPhoto(
                    path: room.images.isNotEmpty
                        ? room.images.first.imageUrl
                        : null,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: StatusBadge(
                      label: roomStatusLabel(room.status),
                      tone: roomTone(room.status),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    right: 10,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          room.property?.name ?? 'ຫ້ອງ ${room.roomNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lak.format(room.price)} ກີບ / ເດືອນ',
                    style: TextStyle(
                      color: c.price,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ຫ້ອງ ${room.roomNumber} · ${room.roomType}',
                    style: TextStyle(color: c.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(TablerIcons.map_pin, size: 15, color: c.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: 14),
                        ),
                      ),
                      if (room.distanceKm != null)
                        Text(
                          '${room.distanceKm} ກມ.',
                          style: TextStyle(color: c.muted, fontSize: 14),
                        ),
                    ],
                  ),
                  if (room.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: room.amenities
                          .take(4)
                          .map((a) => AmenityTag(a.name))
                          .toList(),
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
