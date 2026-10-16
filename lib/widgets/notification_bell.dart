import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../notification_service.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthState>().user == null) return const SizedBox.shrink();
    final count = context.watch<NotificationService>().unreadCount;
    return IconButton(
      tooltip: 'ການແຈ້ງເຕືອນ',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => Navigator.of(context).pushNamed('/notifications'),
      icon: Stack(clipBehavior: Clip.none, children: [
        const Icon(Icons.notifications_outlined, color: Colors.white, size: 25),
        if (count > 0) Positioned(right: -9, top: -7, child: Container(
          constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xffe5484d), shape: BoxShape.circle),
          child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}
