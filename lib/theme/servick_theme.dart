import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ServickColors {
  const ServickColors._();

  static const navy = Color(0xFF1E3A8A);
  static const amber = Color(0xFFF59E0B);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE6EAF2);
  static const canvas = Color(0xFFF4F6FB);
  static const emergency = Color(0xFFDC2626);
  static const emergencySoft = Color(0xFFEF4444);
  static const success = Color(0xFF047857);
  static const waiting = Color(0xFFB45309);
}

class ServickScrollBehavior extends MaterialScrollBehavior {
  const ServickScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

final _fieldRadius = BorderRadius.circular(12);

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: _fieldRadius,
    borderSide: BorderSide(color: color, width: width),
  );
}

ThemeData servickTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: ServickColors.navy,
      primary: ServickColors.navy,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: ServickColors.canvas,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Cairo',
      bodyColor: ServickColors.ink,
      displayColor: ServickColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ServickColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Colors.white,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ServickColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ServickColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ServickColors.navy,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: ServickColors.navy),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _fieldBorder(ServickColors.line),
      enabledBorder: _fieldBorder(ServickColors.line),
      focusedBorder: _fieldBorder(ServickColors.navy, width: 1.6),
      errorBorder: _fieldBorder(ServickColors.emergency),
      focusedErrorBorder: _fieldBorder(ServickColors.emergency, width: 1.6),
    ),
  );
}
