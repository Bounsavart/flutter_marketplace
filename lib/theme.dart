import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color pageBg = Color(0xFF1A0B3B);
  static const Color cardBg = Color(0xFF2C1A5C);
  static const Color surface = Color(0xFFF3F0FF);
  static const Color primary = Color(0xFF6B4FBB);
  static const Color primaryDark = Color(0xFF4A2D9C);
  static const Color primaryLight = Color(0xFF9B8FD4);
  static const Color accentLight = Color(0xFFC5B8FF);
  static const Color textOnLight = Color(0xFF3D2278);
  static const Color textMuted = Color(0xFF9B8FD4);
  static const Color placeholder = Color(0xFFB4B0CC);
  static const Color divider = Color(0xFFDDD6FF);
  static const Color tabActive = Color(0xFFE8E4F8);
  static const Color navInactive = Color(0xFFB4B2A9);
  static const Color amenityText = Color(0xFF5A4A8A);

  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningFg = Color(0xFF92400E);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successFg = Color(0xFF166534);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerFg = Color(0xFF991B1B);
  static const Color purpleBadgeBg = Color(0x266B4FBB); // 15%
  static const Color amenityBg = Color(0x1F6B4FBB); // 12%
  static const Color infoBg = Color(0x1A6B4FBB); // 10%

  static const Color pending = warningFg;
  static const Color confirmed = successFg;
  static const Color rejected = dangerFg;

  static const heroGradient = LinearGradient(
    // ~145deg
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [primary, primaryDark],
  );

  static const heroGradientDark = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [primaryDark, Color(0xFF2C1A5C)],
  );

  static const imageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA68EE0), textOnLight],
  );

  static const imageGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C1A5C), Color(0xFF130830)],
  );

  // Built once; MaterialApp rebuilds whenever the theme toggle changes.
  static final ThemeData light = _build(Palette.light);
  static final ThemeData dark = _build(Palette.dark);

  static CardThemeData cardTheme(Color fill, Color border, double borderWidth) => CardThemeData(
    color: fill,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      side: BorderSide(color: border, width: borderWidth),
    ),
  );

  static ThemeData _build(Palette c) {
    final brightness = c.isDark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: c.isDark ? primaryLight : primary,
        onSurface: c.text,
        surface: c.card,
        surfaceContainer: c.tile,
        surfaceContainerHighest: c.tile,
        outlineVariant: c.tileBorder,
      ),
      scaffoldBackgroundColor: c.pageBg,
      useMaterial3: true,
    );
    OutlineInputBorder pill(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: color, width: width),
    );
    return base.copyWith(
      // Noto Sans Lao instead of the system font: not every platform ships
      // Lao glyphs.
      textTheme: GoogleFonts.notoSansLaoTextTheme(base.textTheme).apply(bodyColor: c.text, displayColor: c.text),
      iconTheme: IconThemeData(color: c.accent),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 0.5, space: 0.5),
      cardTheme: cardTheme(c.tile, c.tileBorder, c.tileBorderWidth),
      listTileTheme: ListTileThemeData(textColor: c.text, iconColor: c.accent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputBg,
        hintStyle: TextStyle(color: c.isDark ? c.muted : placeholder),
        labelStyle: TextStyle(color: c.muted),
        floatingLabelStyle: TextStyle(color: c.accent),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: pill(c.inputBorder),
        enabledBorder: pill(c.inputBorder),
        focusedBorder: pill(c.accent, 1.4),
        errorBorder: pill(dangerFg),
        focusedErrorBorder: pill(dangerFg, 1.4),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.card,
          foregroundColor: c.accent,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: c.isDark ? c.accent : primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: c.accent)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.isDark ? const Color(0xFF2C1A5C) : textOnLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }
}

/// Brightness-dependent colors. Use [Palette.of] inside widgets.
class Palette {
  const Palette._(this.isDark);

  static const light = Palette._(false);
  static const dark = Palette._(true);

  static Palette of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;

  final bool isDark;

  Color get pageBg => isDark ? const Color(0xFF130830) : AppTheme.surface;
  Color get card => isDark ? const Color(0xFF1E1040) : Colors.white;
  Color get border => isDark ? const Color(0xFF3D2876) : AppTheme.accentLight;

  /// Card fill: neutral gray in light mode so cards stand out on the white page.
  Color get tile => isDark ? card : const Color(0xFFF1F3F5);
  Color get tileBorder => isDark ? border : const Color(0xFFE1E5EA);
  double get tileBorderWidth => isDark ? 0.5 : 1;

  Color get divider => isDark ? const Color(0x26C5B8FF) : AppTheme.divider;
  Color get text => isDark ? const Color(0xFFEDE9FF) : AppTheme.textOnLight;
  Color get muted => isDark ? const Color(0xFF8B7FC4) : AppTheme.textMuted;
  Color get danger => isDark ? const Color(0xFFFCA5A5) : AppTheme.dangerFg;

  /// Purple for icons, links and outlines; lighter in dark mode for contrast.
  Color get accent => isDark ? AppTheme.accentLight : AppTheme.primary;
  Color get price => isDark ? AppTheme.accentLight : AppTheme.textOnLight;
  Color get tint => isDark ? const Color(0x33C5B8FF) : const Color(0xFFEDE9FF);
  Color get amenityBg => isDark ? const Color(0x26C5B8FF) : AppTheme.amenityBg;
  Color get amenityText => isDark ? AppTheme.accentLight : AppTheme.amenityText;
  Color get inputBg => isDark ? const Color(0x14FFFFFF) : Colors.white;
  Color get inputBorder => isDark ? const Color(0x4DC5B8FF) : AppTheme.accentLight;

  Color get navBg => isDark ? const Color(0xFF1A0B3B) : Colors.white;
  Color get navBorder => isDark ? const Color(0xFF3D2876) : AppTheme.divider;
  Color get navInactive => isDark ? const Color(0xFF6E6596) : AppTheme.navInactive;
  Color get navActive => isDark ? AppTheme.accentLight : AppTheme.primary;

  LinearGradient get heroGradient => isDark ? AppTheme.heroGradientDark : AppTheme.heroGradient;
  LinearGradient get imageGradient => isDark ? AppTheme.imageGradientDark : AppTheme.imageGradient;

  /// Bottom color of [heroGradient]; fills the corners behind the overlap card.
  Color get heroEnd => heroGradient.colors.last;
}

enum Tone { success, warning, danger, purple, neutral }

extension ToneColors on Tone {
  Color get bg => switch (this) {
    Tone.success => AppTheme.successBg,
    Tone.warning => AppTheme.warningBg,
    Tone.danger => AppTheme.dangerBg,
    Tone.purple => const Color(0xFFEDE9FF),
    Tone.neutral => const Color(0xFFEDEBF5),
  };

  Color get fg => switch (this) {
    Tone.success => AppTheme.successFg,
    Tone.warning => AppTheme.warningFg,
    Tone.danger => AppTheme.dangerFg,
    Tone.purple => AppTheme.textOnLight,
    Tone.neutral => const Color(0xFF5A5670),
  };

  Color bgOn(Palette c) => !c.isDark
      ? bg
      : switch (this) {
          Tone.success => const Color(0xFF0F3320),
          Tone.warning => const Color(0xFF3D2A00),
          Tone.danger => const Color(0xFF3F1414),
          Tone.purple => const Color(0x33C5B8FF),
          Tone.neutral => const Color(0x1FFFFFFF),
        };

  Color fgOn(Palette c) => !c.isDark
      ? fg
      : switch (this) {
          Tone.success => const Color(0xFF9FE1CB),
          Tone.warning => const Color(0xFFFAC775),
          Tone.danger => const Color(0xFFFCA5A5),
          Tone.purple => const Color(0xFFEDE9FF),
          Tone.neutral => const Color(0xFFB8B3CC),
        };
}

Tone bookingTone(String status) {
  switch (status) {
    case 'confirmed':
      return Tone.success;
    case 'rejected':
    case 'cancelled':
      return Tone.danger;
    default:
      return Tone.warning;
  }
}

Color bookingColor(String status) => bookingTone(status).fg;

Tone roomTone(String status) {
  switch (status) {
    case 'available':
      return Tone.success;
    case 'pending':
      return Tone.warning;
    default:
      return Tone.neutral;
  }
}

Tone approvalTone(String status) {
  switch (status) {
    case 'approved':
      return Tone.success;
    case 'rejected':
      return Tone.danger;
    default:
      return Tone.warning;
  }
}

String bookingLabel(String status) {
  switch (status) {
    case 'confirmed':
      return 'ຢືນຢັນແລ້ວ';
    case 'rejected':
      return 'ຖືກປະຕິເສດ';
    case 'cancelled':
      return 'ຍົກເລີກແລ້ວ';
    default:
      return 'ລໍຖ້າຢືນຢັນ';
  }
}

String roomStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'ມີຄຳຂໍຈອງ';
    case 'rented':
      return 'ປ່ອຍເຊົ່າແລ້ວ';
    default:
      return 'ຫວ່າງ';
  }
}

String approvalLabel(String status) {
  switch (status) {
    case 'approved':
      return 'ອະນຸມັດແລ້ວ';
    case 'rejected':
      return 'ຖືກປະຕິເສດ';
    default:
      return 'ລໍຖ້າກວດສອບ';
  }
}

String roleLabel(String role) {
  switch (role) {
    case 'owner':
      return 'ເຈົ້າຂອງຫ້ອງ';
    case 'admin':
      return 'ຜູ້ດູແລລະບົບ';
    default:
      return 'ຜູ້ເຊົ່າ';
  }
}
