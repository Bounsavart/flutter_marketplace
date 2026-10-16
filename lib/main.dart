import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'api.dart';
import 'auth_state.dart';
import 'notification_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/owner_shell.dart';
import 'screens/tenant_shell.dart';
import 'theme.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded before the first frame so the saved theme doesn't flash.
  final themeController = await ThemeController.load();
  runApp(RoomRentalApp(themeController: themeController));
}

class RoomRentalApp extends StatefulWidget {
  const RoomRentalApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<RoomRentalApp> createState() => _RoomRentalAppState();
}

class _RoomRentalAppState extends State<RoomRentalApp> {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final navigatorKey = GlobalKey<NavigatorState>();
  final api = ApiClient();
  late final AuthState auth = AuthState(api);
  late final NotificationService notifications = NotificationService(api, auth);
  StreamSubscription? _pushSubscription;

  @override
  void initState() {
    super.initState();
    auth.bootstrap();
    _pushSubscription = notifications.pushes.listen((item) {
      final context = messengerKey.currentContext;
      if (context == null) return;
      final message = notificationTitle(item['type'] as String? ?? '', Map<String, dynamic>.from(item['data'] as Map? ?? {}));
      messengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'ເບິ່ງ', onPressed: () => navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: notifications),
        ChangeNotifierProvider.value(value: widget.themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          scaffoldMessengerKey: messengerKey,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Room Rental Marketplace',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          onGenerateRoute: (settings) => settings.name == '/notifications'
              ? MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())
              : null,
          home: const AuthGate(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    notifications.dispose();
    auth.dispose();
    super.dispose();
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = auth.user?.role;
    switch (role) {
      case 'tenant':
        return const TenantShell();
      case 'owner':
        return const OwnerShell();
      case 'admin':
        return const AdminShell();
      default:
        return auth.guest ? const TenantShell() : const LoginScreen();
    }
  }
}
