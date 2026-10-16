import 'package:flutter/material.dart';

import '../theme.dart';

/// Color ramp for one stat card. Each card gets its own accent instead of
/// everything being purple.
class StatColor {
  const StatColor({
    required this.bgLight,
    required this.bgDark,
    required this.iconColor,
    required this.iconDark,
    required this.numLight,
    required this.numDark,
    required this.labelLight,
    required this.labelDark,
  });

  final Color bgLight;
  final Color bgDark;
  final Color iconColor;
  final Color iconDark;
  final Color numLight;
  final Color numDark;
  final Color labelLight;
  final Color labelDark;

  Color bg(Palette c) => c.isDark ? bgDark : bgLight;
  Color icon(Palette c) => c.isDark ? iconDark : iconColor;
  Color number(Palette c) => c.isDark ? numDark : numLight;
  Color label(Palette c) => c.isDark ? labelDark : labelLight;

  /// Users / tenants.
  static const blue = StatColor(
    bgLight: Color(0xFFE6F1FB),
    bgDark: Color(0xFF1A3A5C),
    iconColor: Color(0xFF185FA5),
    iconDark: Color(0xFF85B7EB),
    numLight: Color(0xFF0C447C),
    numDark: Color(0xFFB5D4F4),
    labelLight: Color(0xFF185FA5),
    labelDark: Color(0xFF85B7EB),
  );

  /// Owners / buildings.
  static const purple = StatColor(
    bgLight: Color(0xFFEDE9FF),
    bgDark: Color(0xFF2C1A5C),
    iconColor: Color(0xFF6B4FBB),
    iconDark: Color(0xFFC5B8FF),
    numLight: Color(0xFF3D2278),
    numDark: Color(0xFFC5B8FF),
    labelLight: Color(0xFF6B4FBB),
    labelDark: Color(0xFF9B8FD4),
  );

  /// Available rooms.
  static const green = StatColor(
    bgLight: Color(0xFFDCFCE7),
    bgDark: Color(0xFF0F3320),
    iconColor: Color(0xFF166534),
    iconDark: Color(0xFF5DCAA5),
    numLight: Color(0xFF166534),
    numDark: Color(0xFF9FE1CB),
    labelLight: Color(0xFF166534),
    labelDark: Color(0xFF5DCAA5),
  );

  /// Pending / warning.
  static const amber = StatColor(
    bgLight: Color(0xFFFEF3C7),
    bgDark: Color(0xFF3D2A00),
    iconColor: Color(0xFFB45309),
    iconDark: Color(0xFFEF9F27),
    numLight: Color(0xFF92400E),
    numDark: Color(0xFFFAC775),
    labelLight: Color(0xFFB45309),
    labelDark: Color(0xFFEF9F27),
  );

  /// Total rooms.
  static const teal = StatColor(
    bgLight: Color(0xFFE1F5EE),
    bgDark: Color(0xFF0A2E24),
    iconColor: Color(0xFF0F6E56),
    iconDark: Color(0xFF5DCAA5),
    numLight: Color(0xFF085041),
    numDark: Color(0xFF9FE1CB),
    labelLight: Color(0xFF0F6E56),
    labelDark: Color(0xFF5DCAA5),
  );

  /// Properties.
  static const coral = StatColor(
    bgLight: Color(0xFFFAECE7),
    bgDark: Color(0xFF3A1408),
    iconColor: Color(0xFF993C1D),
    iconDark: Color(0xFFF0997B),
    numLight: Color(0xFF712B13),
    numDark: Color(0xFFF5C4B3),
    labelLight: Color(0xFF993C1D),
    labelDark: Color(0xFFF0997B),
  );
}
