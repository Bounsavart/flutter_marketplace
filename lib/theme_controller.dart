import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light/dark choice from the Profile screen, persisted across restarts.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._prefs) : _dark = _prefs.getBool(_key) ?? false;

  static const _key = 'dark_mode';

  final SharedPreferences _prefs;
  bool _dark;

  /// Reads the saved choice; await before runApp so the first frame is right.
  static Future<ThemeController> load() async => ThemeController._(await SharedPreferences.getInstance());

  bool get isDark => _dark;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDark(bool value) async {
    if (value == _dark) return;
    _dark = value;
    notifyListeners();
    await _prefs.setBool(_key, value);
  }
}
