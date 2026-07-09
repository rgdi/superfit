import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00E676); // lime/green fitness vibe
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceMid = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2C2C2C);

  static const Color muscleChest = Color(0xFFFF6B6B);
  static const Color muscleShoulder = Color(0xFFFF9F43);
  static const Color muscleArm = Color(0xFFFFA8A8);
  static const Color muscleTriceps = Color(0xFFC77DFF);
  static const Color muscleBack = Color(0xFF4ECDC4);
  static const Color muscleTrapezius = Color(0xFF54A0FF);
  static const Color muscleCore = Color(0xFFFECA57);
  static const Color muscleErector = Color(0xFF48DBFB);
  static const Color muscleQuads = Color(0xFFFF6B6B);
  static const Color muscleHamstring = Color(0xFF1DD1A1);
  static const Color muscleGlute = Color(0xFF5F27CD);
  static const Color muscleCalf = Color(0xFFFF9FF3);

  static const Color rpeLow = Color(0xFF54A0FF);
  static const Color rpeOptimal = Color(0xFF1DD1A1);
  static const Color rpeMid = Color(0xFFFECA57);
  static const Color rpeHigh = Color(0xFFFF9F43);
  static const Color rpeMax = Color(0xFFFF6B6B);

  static Color rpeColor(int rpe) {
    if (rpe <= 6) return rpeLow;
    if (rpe == 7) return rpeOptimal;
    if (rpe == 8) return rpeOptimal;
    if (rpe == 9) return rpeMid;
    if (rpe == 10) return rpeMax;
    return rpeHigh;
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        surface: surfaceDark,
        onSurface: Colors.white,
        surfaceContainerHighest: surfaceMid,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceMid,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceMid,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white60,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceLight,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
      ),
      dividerColor: surfaceLight,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white60),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
