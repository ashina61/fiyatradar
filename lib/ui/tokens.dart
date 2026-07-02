import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FiyatRadar premium grocery-tech tokens.
/// Two palettes — dark warm (espresso + gold) and light warm (cream + copper).
/// [FR] exposes live static getters bound to the active palette via
/// [FRThemeController]. Callsites stay mostly identical — do not wrap
/// decorations in `const` when they embed `FR.*`.

/// Premium dokunuş geri bildirimi — kısa, tutarlı, tek noktadan.
/// Hafif seçim tıklaması: favori, oy, doğrulama gibi mikro aksiyonlarda.
void frHaptic() {
  HapticFeedback.selectionClick();
}

/// Başarı vurgusu: fiyat gönderildi, satın alma tamamlandı gibi
/// "iş bitti" anlarında.
void frHapticSuccess() {
  HapticFeedback.mediumImpact();
}

enum FRThemeMode { dark, light }

class FRPalette {
  // Canvas stack
  final Color bg;
  final Color bgElev;
  final Color surface;
  final Color surfaceHi;
  final Color surfaceLo;
  // Borders / dividers
  final Color hairline;
  final Color hairlineSoft;
  // Warm gold accent
  final Color gold;
  final Color goldHi;
  final Color goldDeep;
  final Color copper;
  /// Foreground color for content placed on top of [gold]/[goldDeep] surfaces
  /// (filled CTAs, store badges, FAB). In dark mode this is the deep espresso
  /// background — high contrast on bright honey gold. In light mode the gold
  /// is a darker copper, so we flip to the darkest ink so text/icons stay
  /// legible (~6:1) instead of cream-on-copper (~3:1).
  final Color onGold;
  // Text
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  // Semantic
  final Color good;
  final Color goodSoft;
  final Color warn;
  final Color bad;
  final Color badSoft;
  // Shadow tone (stronger in dark, lighter in light)
  final Color shadowTone;
  final Brightness brightness;

  const FRPalette({
    required this.bg,
    required this.bgElev,
    required this.surface,
    required this.surfaceHi,
    required this.surfaceLo,
    required this.hairline,
    required this.hairlineSoft,
    required this.gold,
    required this.goldHi,
    required this.goldDeep,
    required this.copper,
    required this.onGold,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.good,
    required this.goodSoft,
    required this.warn,
    required this.bad,
    required this.badSoft,
    required this.shadowTone,
    required this.brightness,
  });

  static const FRPalette dark = FRPalette(
    bg: Color(0xFF120B07),
    bgElev: Color(0xFF1A120C),
    surface: Color(0xFF201611),
    surfaceHi: Color(0xFF2A1F18),
    surfaceLo: Color(0xFF16100B),
    hairline: Color(0xFF352820),
    hairlineSoft: Color(0xFF2A1F18),
    gold: Color(0xFFD7B27A),
    goldHi: Color(0xFFEACB96),
    goldDeep: Color(0xFFB48B52),
    copper: Color(0xFF8F5A34),
    onGold: Color(0xFF120B07),
    ink: Color(0xFFF3E9DC),
    ink2: Color(0xFFCBB8A2),
    ink3: Color(0xFF8E7E6E),
    ink4: Color(0xFF5C4F44),
    good: Color(0xFF78B388),
    goodSoft: Color(0xFF1E2A20),
    warn: Color(0xFFE1A24A),
    bad: Color(0xFFD9685E),
    badSoft: Color(0xFF2C1A17),
    shadowTone: Color(0xFF000000),
    brightness: Brightness.dark,
  );

  static const FRPalette light = FRPalette(
    bg: Color(0xFFFBF6EE),
    bgElev: Color(0xFFF5EDE0),
    surface: Color(0xFFFFFBF4),
    surfaceHi: Color(0xFFF3E8D4),
    surfaceLo: Color(0xFFEFE3CD),
    hairline: Color(0xFFD9C5A4),
    hairlineSoft: Color(0xFFEFE3CD),
    gold: Color(0xFFA67238),
    goldHi: Color(0xFFC79656),
    goldDeep: Color(0xFF6E4220),
    copper: Color(0xFF5A3416),
    onGold: Color(0xFFFFFBF4),
    ink: Color(0xFF1B0F06),
    ink2: Color(0xFF3D2C1C),
    ink3: Color(0xFF7A6852),
    ink4: Color(0xFFA9967D),
    good: Color(0xFF2F6841),
    goodSoft: Color(0xFFD9EAD9),
    warn: Color(0xFF9C5C12),
    bad: Color(0xFF9F2E22),
    badSoft: Color(0xFFF1D6CF),
    shadowTone: Color(0xFF6E4220),
    brightness: Brightness.light,
  );
}

/// App-wide theme state. Persisted via SharedPreferences.
/// Widgets reference `FR.*` getters that delegate to [palette].
class FRThemeController extends ChangeNotifier {
  FRThemeController._();
  static final FRThemeController instance = FRThemeController._();

  static const _prefsKey = 'fr_theme_mode_v2';
  FRThemeMode _mode = FRThemeMode.light;
  FRThemeMode get mode => _mode;
  bool get isDark => _mode == FRThemeMode.dark;
  FRPalette get palette =>
      _mode == FRThemeMode.dark ? FRPalette.dark : FRPalette.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_prefsKey);
    // Light is the default — only switch to dark when the user has
    // explicitly opted in.
    _mode = v == 'dark' ? FRThemeMode.dark : FRThemeMode.light;
    notifyListeners();
  }

  Future<void> setMode(FRThemeMode m) async {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, m == FRThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggle() => setMode(isDark ? FRThemeMode.light : FRThemeMode.dark);
}

/// Proxy for the active palette. All fields are non-const static getters.
/// Do not use `const` on widget constructors that embed these colors.
class FR {
  static FRPalette get _p => FRThemeController.instance.palette;

  static Color get bg => _p.bg;
  static Color get bgElev => _p.bgElev;
  static Color get surface => _p.surface;
  static Color get surfaceHi => _p.surfaceHi;
  static Color get surfaceLo => _p.surfaceLo;
  static Color get hairline => _p.hairline;
  static Color get hairlineSoft => _p.hairlineSoft;
  static Color get gold => _p.gold;
  static Color get goldHi => _p.goldHi;
  static Color get goldDeep => _p.goldDeep;
  static Color get copper => _p.copper;
  static Color get onGold => _p.onGold;
  static Color get ink => _p.ink;
  static Color get ink2 => _p.ink2;
  static Color get ink3 => _p.ink3;
  static Color get ink4 => _p.ink4;
  static Color get good => _p.good;
  static Color get goodSoft => _p.goodSoft;
  static Color get warn => _p.warn;
  static Color get bad => _p.bad;
  static Color get badSoft => _p.badSoft;
  static Color get shadowTone => _p.shadowTone;
  static Brightness get brightness => _p.brightness;
  static bool get isDark => _p.brightness == Brightness.dark;
}

class FRRad {
  static const s = 10.0;
  static const m = 14.0;
  static const l = 18.0;
  static const xl = 22.0;
  static const xxl = 28.0;
  static const pill = 999.0;

  static BorderRadius all(double r) => BorderRadius.all(Radius.circular(r));
}

class FRSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
}

/// Height of the floating dock + bottom margin. Screens use this to reserve
/// space so that their sticky bottom CTA is never clipped by the dock.
const double kFRDockHeight = 72;
const double kFRDockMargin = 14;
const double kFRDockInset = kFRDockHeight + kFRDockMargin;

/// Safe-area aware bottom inset that reserves room for the dock plus the
/// system gesture area. Use for scroll content bottom padding.
double frBottomScrollPadding(BuildContext context, {double extra = 16}) {
  final safe = MediaQuery.of(context).viewPadding.bottom;
  return kFRDockInset + safe + extra;
}

/// Bottom padding for a sticky footer (e.g. Add Price CTA, Cart footer) so
/// that it sits just above the dock regardless of safe area. When the soft
/// keyboard is visible it overrides the dock reservation — the footer should
/// then sit just above the keyboard, not above a hidden dock.
double frStickyFooterBottomPadding(BuildContext context, {double extra = 8}) {
  final mq = MediaQuery.of(context);
  final safe = mq.viewPadding.bottom;
  final kb = mq.viewInsets.bottom;
  if (kb > 0) return extra; // scaffold already lifts body above keyboard
  return kFRDockInset + safe + extra;
}

/// Reserved height a scrollable should add to its bottom padding when it sits
/// above a sticky footer — so the last content row isn't hidden behind the
/// footer or the dock.
double frScrollPaddingWithFooter(
  BuildContext context, {
  double footerHeight = 82,
  double extra = 12,
}) {
  final mq = MediaQuery.of(context);
  final safe = mq.viewPadding.bottom;
  final kb = mq.viewInsets.bottom;
  if (kb > 0) return footerHeight + extra + kb;
  return footerHeight + kFRDockInset + safe + extra;
}

List<BoxShadow> frShadow({double blur = 20, double y = 10, double opacity = .35}) =>
    [BoxShadow(color: FR.shadowTone.withOpacity(opacity), blurRadius: blur, offset: Offset(0, y))];

List<BoxShadow> frGoldGlow({double opacity = .22}) =>
    [BoxShadow(color: FR.gold.withOpacity(opacity), blurRadius: 24, offset: const Offset(0, 10))];

TextStyle frDisplay(double size, FontWeight w,
        {Color? color, double? height, double letter = -0.6}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color ?? FR.ink,
      letterSpacing: letter,
      height: height,
    );

TextStyle frSerifItalic(double size, FontWeight w, {Color? color}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color ?? FR.ink2,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.4,
    );

TextStyle frText(double size, FontWeight w,
        {Color? color, double? letter, double? height}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: w,
      color: color ?? FR.ink,
      letterSpacing: letter,
      height: height,
    );

TextStyle frOverline({Color? color, double size = 10}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color ?? FR.goldDeep,
      letterSpacing: 2.1,
    );

TextStyle frPrice(double size, {Color? color, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color ?? FR.ink,
      letterSpacing: -0.8,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

BoxDecoration frSurface({
  double radius = FRRad.xl,
  Color? color,
  Color? border,
}) =>
    BoxDecoration(
      color: color ?? FR.surface,
      borderRadius: FRRad.all(radius),
      border: Border.all(color: border ?? FR.hairline),
    );

BoxDecoration frElevated({double radius = FRRad.xl, Color? color}) => BoxDecoration(
      color: color ?? FR.surface,
      borderRadius: FRRad.all(radius),
      border: Border.all(color: FR.hairline),
      boxShadow: frShadow(),
    );
