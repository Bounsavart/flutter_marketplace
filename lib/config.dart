import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://127.0.0.1:3000';
    return 'http://127.0.0.1:3000';
  }

  static String fileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$apiBaseUrl$path';
  }
}
