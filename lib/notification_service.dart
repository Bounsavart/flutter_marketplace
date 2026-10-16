import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';
import 'auth_state.dart';
import 'config.dart';

class NotificationService extends ChangeNotifier {
  NotificationService(this.api, this.auth) {
    auth.addListener(_authChanged);
    _authChanged();
  }

  final ApiClient api;
  final AuthState auth;
  final StreamController<Map<String, dynamic>> _pushes = StreamController.broadcast();
  Stream<Map<String, dynamic>> get pushes => _pushes.stream;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  int _retrySeconds = 1;
  bool _disposed = false;
  int unreadCount = 0;
  List<Map<String, dynamic>> notifications = [];
  bool loadingMore = false;
  int? _before;
  String? _activeToken;

  void _authChanged() {
    final token = auth.user == null ? null : api.token;
    if (token == _activeToken) return;
    _activeToken = token;
    _disconnect();
    notifications = [];
    unreadCount = 0;
    _before = null;
    notifyListeners();
    if (token != null) {
      _connect(token);
      _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => refreshUnreadCount());
    }
  }

  String get _socketUrl {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws', path: '/ws', query: null).toString();
  }

  void _connect(String token) {
    if (_disposed || token != _activeToken) return;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(_socketUrl));
      _channel = channel;
      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      _subscription = channel.stream.listen((event) {
        try {
          final message = jsonDecode(event as String) as Map<String, dynamic>;
          if (message['type'] == 'authenticated') _retrySeconds = 1;
          if (message['type'] == 'notification' && message['notification'] is Map) {
            final item = Map<String, dynamic>.from(message['notification'] as Map);
            notifications = [item, ...notifications.where((e) => e['id'] != item['id'])];
            if (item['is_read'] != true) unreadCount++;
            notifyListeners();
            _pushes.add(item);
          }
        } catch (_) {}
      }, onError: (_) => _scheduleReconnect(token), onDone: () => _scheduleReconnect(token));
      unawaited(_refreshFirstPage());
      unawaited(refreshUnreadCount());
    } catch (_) { _scheduleReconnect(token); }
  }

  void _scheduleReconnect(String token) {
    if (_disposed || token != _activeToken || _reconnectTimer?.isActive == true) return;
    _reconnectTimer = Timer(Duration(seconds: _retrySeconds), () => _connect(token));
    _retrySeconds = (_retrySeconds * 2).clamp(1, 30);
  }

  void _disconnect() {
    _reconnectTimer?.cancel(); _reconnectTimer = null;
    _pollTimer?.cancel(); _pollTimer = null;
    _subscription?.cancel(); _subscription = null;
    _channel?.sink.close(); _channel = null;
  }

  Future<void> refreshUnreadCount() async {
    if (_activeToken == null) return;
    try { unreadCount = await api.notificationUnreadCount(); notifyListeners(); } catch (_) {}
  }

  Future<void> _refreshFirstPage() async {
    if (_activeToken == null) return;
    try {
      notifications = await api.notifications();
      _before = notifications.isEmpty ? null : (notifications.last['id'] as num).toInt();
      await refreshUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() async => _refreshFirstPage();

  Future<void> loadMore() async {
    if (loadingMore || _before == null || _activeToken == null) return;
    loadingMore = true; notifyListeners();
    try {
      final rows = await api.notifications(before: _before);
      notifications = [...notifications, ...rows];
      if (rows.isEmpty) {
        _before = null;
      } else {
        _before = (rows.last['id'] as num).toInt();
      }
    } catch (_) {} finally { loadingMore = false; notifyListeners(); }
  }

  Future<void> markRead(int id) async {
    try {
      await api.markNotificationRead(id);
      notifications = notifications.map((n) => n['id'] == id ? {...n, 'is_read': true} : n).toList();
      if (unreadCount > 0) unreadCount--;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await api.markAllNotificationsRead();
      notifications = notifications.map((n) => {...n, 'is_read': true}).toList();
      unreadCount = 0; notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true; auth.removeListener(_authChanged); _disconnect(); _pushes.close(); super.dispose();
  }
}
