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

  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.stroke,
    required this.accent,
    required this.accentDim,
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
  });
}

const AppPalette darkPalette = AppPalette(
  brightness: Brightness.dark,
  bg: Color(0xFF0A0A0F),
  surface: Color(0xFF15151E),
  surfaceHigh: Color(0xFF1E1E29),
  stroke: Color(0xFF26262F),
  accent: Color(0xFFC8FF3D),
  accentDim: Color(0xFF6E8C22),
  calorieFrom: Color(0xFFFF8A3D),
  calorieTo: Color(0xFFFF4D8F),
  protein: Color(0xFF00E5A0),
  carbs: Color(0xFFFFB339),
  fat: Color(0xFFFF6B9D),
  water: Color(0xFF4ECBFF),
  fiber: Color(0xFFB48BFF),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFF8F8F9C),
  textTertiary: Color(0xFF55555F),
  streak: Color(0xFFFFA63D),
);

const AppPalette lightPalette = AppPalette(
  brightness: Brightness.light,
  bg: Color(0xFFF7F7F2),
  surface: Color(0xFFFFFFFF),
  surfaceHigh: Color(0xFFEFEFEA),
  stroke: Color(0xFFE2E2DA),
  accent: Color(0xFF8FBE0E),
  accentDim: Color(0xFFB8E22B),
  calorieFrom: Color(0xFFE6722D),
  calorieTo: Color(0xFFE63D7D),
  protein: Color(0xFF00B57F),
  carbs: Color(0xFFCC8200),
  fat: Color(0xFFD9527E),
  water: Color(0xFF1E9AE0),
  fiber: Color(0xFF8A5DD6),
  textPrimary: Color(0xFF0A0A0F),
  textSecondary: Color(0xFF55555F),
  textTertiary: Color(0xFF9B9BA8),
  streak: Color(0xFFE07A1A),
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
