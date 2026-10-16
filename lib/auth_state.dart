import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';

class AuthState extends ChangeNotifier {
  AuthState(this.api);

  final ApiClient api;
  AppUser? user;
  bool ready = false;
  String? error;
  bool busy = false;

  /// Browsing without an account (the "SKIP" option on the login screen).
  bool guest = false;

  void browseAsGuest() {
    guest = true;
    error = null;
    notifyListeners();
  }

  void exitGuest() {
    guest = false;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    await api.loadToken();
    if (api.token != null) {
      try {
        user = await api.me();
      } catch (_) {
        await api.setToken(null);
        user = null;
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.login(email, password);
      await api.setToken(result.token);
      user = result.user;
      guest = false;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.register(name: name, email: email, password: password, role: role, phone: phone);
      await api.setToken(result.token);
      user = result.user;
      guest = false;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (api.token == null) return;
    user = await api.me();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.setToken(null);
    user = null;
    guest = false;
    notifyListeners();
  }
}
