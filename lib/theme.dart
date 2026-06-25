import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color stroke;
  final Color accent;
  final Color accentDim;
  final Color accentSoft; // tinted background for chips/cards
  final Color calorieFrom;
  final Color calorieTo;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color water;
  final Color fiber;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color streak;
  // Semantic
  final Color success;
  final Color warning;
  final Color danger;

  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.stroke,
    required this.accent,
    required this.accentDim,
    required this.accentSoft,
    required this.calorieFrom,
    required this.calorieTo,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.water,
    required this.fiber,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.streak,
    required this.success,
    required this.warning,
    required this.danger,
  });
}

// ============================================================================
// SAFFRON + CREAM brand
//   - Saffron #C8501B  primary CTA on light; lifts to #E8702C on dark
//   - Cream #FAF5EC    warm paper background on light
//   - Warm dark surfaces (not pure black) — candle-lit, not OLED
//   - Gold reserved for premium / earned moments (use sparingly)
//   - Danger pushed away from Saffron so destructive ≠ primary
//   - Indigo brightened on dark so it doesn't disappear
// ============================================================================

const AppPalette darkPalette = AppPalette(
  brightness: Brightness.dark,
  bg: Color(0xFF12100E),
  surface: Color(0xFF1B1916),
  surfaceHigh: Color(0xFF25221E),
  stroke: Color(0xFF2F2B25),
  accent: Color(0xFFE8702C), // Saffron lifted for dark contrast
  accentDim: Color(0xFF8A4318),
  accentSoft: Color(0xFF2A1F18), // tinted chip bg
  calorieFrom: Color(0xFFE8702C), // saffron
  calorieTo: Color(0xFFC9A64A), // gold
  protein: Color(0xFF6BA66B), // leaf, brightened for dark
  carbs: Color(0xFFC9A64A), // gold
  fat: Color(0xFFB5697A), // berry-soft
  water: Color(0xFF6B86C9), // indigo brightened so it shows on dark
  fiber: Color(0xFFB48BCF), // muted plum
  textPrimary: Color(0xFFF4ECDD), // warm paper
  textSecondary: Color(0xFFC7BFB0), // warm soft
  textTertiary: Color(0xFF7A7367), // warm muted
  streak: Color(0xFFE8B65A), // gold-orange
  success: Color(0xFF6BA66B), // leaf
  warning: Color(0xFFC9A64A), // gold
  danger: Color(0xFFE45656), // distinct from saffron (cooler red)
);

const AppPalette lightPalette = AppPalette(
  brightness: Brightness.light,
  bg: Color(0xFFFAF5EC), // cream
  surface: Color(0xFFFFFFFF), // paper
  surfaceHigh: Color(0xFFF2EADA), // cream deep
  stroke: Color(0xFFE8DFCC), // line
  accent: Color(0xFFC8501B), // saffron
  accentDim: Color(0xFFA33A0D), // saffron deep (pressed)
  accentSoft: Color(0xFFFCE9D9), // saffron soft (chip bg)
  calorieFrom: Color(0xFFC8501B), // saffron
  calorieTo: Color(0xFFC9A64A), // gold
  protein: Color(0xFF4A7A4A), // leaf
  carbs: Color(0xFFB47A1A), // gold-deep for legibility on cream
  fat: Color(0xFF8B2E3F), // berry
  water: Color(0xFF1F2E5A), // indigo
  fiber: Color(0xFF6B4798), // plum-deep
  textPrimary: Color(0xFF1C1915), // ink
  textSecondary: Color(0xFF3A332A), // ink soft
  textTertiary: Color(0xFF8A8276), // muted
  streak: Color(0xFFA33A0D), // saffron deep
  success: Color(0xFF3F7A4A),
  warning: Color(0xFFB47A1A),
  danger: Color(0xFFC73030), // distinctly redder than saffron
);

class AppColors {
  static AppPalette _palette = darkPalette;
  static AppPalette get current => _palette;
  static set palette(AppPalette p) => _palette = p;

  static Color get bg => _palette.bg;
  static Color get surface => _palette.surface;
  static Color get surfaceHigh => _palette.surfaceHigh;
  static Color get stroke => _palette.stroke;
  static Color get accent => _palette.accent;
  static Color get accentDim => _palette.accentDim;
  static Color get accentSoft => _palette.accentSoft;
  static Color get calorieFrom => _palette.calorieFrom;
  static Color get calorieTo => _palette.calorieTo;
  static Color get protein => _palette.protein;
  static Color get carbs => _palette.carbs;
  static Color get fat => _palette.fat;
  static Color get water => _palette.water;
  static Color get fiber => _palette.fiber;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textTertiary => _palette.textTertiary;
  static Color get streak => _palette.streak;
  static Color get success => _palette.success;
  static Color get warning => _palette.warning;
  static Color get danger => _palette.danger;
}

ThemeData buildAppTheme(AppPalette palette) {
  final base = palette.brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: palette.textPrimary,
    displayColor: palette.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: palette.bg,
    colorScheme: palette.brightness == Brightness.dark
        ? ColorScheme.dark(
            surface: palette.bg,
            primary: palette.accent,
            onPrimary: Colors.black,
            secondary: palette.accent,
            onSecondary: Colors.black,
          )
        : ColorScheme.light(
            surface: palette.bg,
            primary: palette.accent,
            onPrimary: Colors.black,
            secondary: palette.accent,
            onSecondary: Colors.black,
          ),
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeUpTransitionsBuilder(),
        TargetPlatform.iOS: _FadeUpTransitionsBuilder(),
      },
    ),
  );
}

class _FadeUpTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AppText {
  // Display: huge hero numbers (calorie remaining, etc.)
  static TextStyle get giantNumber => GoogleFonts.plusJakartaSans(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        height: 0.95,
        letterSpacing: -2.4,
        color: AppColors.textPrimary,
      );

  // Strong secondary numbers (macros, stat cards)
  static TextStyle get bigNumber => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textTertiary,
        letterSpacing: 1.4,
      );

  static TextStyle get greeting => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
        height: 1.1,
      );

  static TextStyle get meta => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
      );
}
