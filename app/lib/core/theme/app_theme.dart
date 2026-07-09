// Theme con más vida: gradientes, shadows, animaciones
import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primary = Color(0xFF00E676); // verde fitness
  static const Color primaryDark = Color(0xFF00BFA5);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFFFFD600); // dorado para PRs

  // Surfaces
  static const Color surfaceDark = Color(0xFF0E0E10);
  static const Color surfaceMid = Color(0xFF1A1A1E);
  static const Color surfaceLight = Color(0xFF2A2A30);
  static const Color surfaceHigher = Color(0xFF3A3A42);

  // Músculos
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

  // RPE scale
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

  // Gradientes reutilizables
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient warmupGradient = LinearGradient(
    colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient deloadGradient = LinearGradient(
    colors: [Color(0xFF54A0FF), Color(0xFF5F27CD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient progressGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData dark() {
    final base = ThemeData(
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
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: surfaceMid,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceMid,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceLight,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
        trackHeight: 6,
      ),
      dividerColor: surfaceLight,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white60),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

/// Shimmer effect para estados de carga
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            colors: const [Color(0xFF1A1A1E), Color(0xFF3A3A42), Color(0xFF1A1A1E)],
            stops: const [0.4, 0.5, 0.6],
            begin: Alignment(-1.0 + _c.value * 2, 0),
            end: Alignment(1.0 + _c.value * 2, 0),
          ).createShader(rect);
        },
        child: widget.child,
      ),
    );
  }
}
