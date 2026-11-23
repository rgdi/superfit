// Theme con más vida: gradientes, shadows, animaciones
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

class AppTheme {
  // ---- Paleta minimalista ---------------------------------------------------
  // Monocromo. El color solo aparece para comunicar datos (signal).
  static const Color primary = Color(0xFFF4F4F5); // casi blanco: botones, selección
  static const Color primaryDark = Color(0xFFD4D4D8);
  static const Color signal = Color(0xFFB8F34A); // único color: progreso / datos
  static const Color secondary = Color(0xFFF26D5B); // alertas (uso mínimo)
  static const Color accent = Color(0xFFE8C25A); // récords (uso mínimo)
  static const Color info = Color(0xFFA1A1AA);
  static const Color ai = Color(0xFFA1A1AA);

  // Superficies
  static const Color surfaceDark = Color(0xFF0B0B0C); // fondo
  static const Color surfaceMid = Color(0xFF151516); // superficies
  static const Color surfaceLight = Color(0xFF1F1F22);
  static const Color surfaceHigher = Color(0xFF2A2A2E);
  static const Color border = Color(0xFF1F1F22);
  static const Color textMuted = Color(0xFF8E8E96);
  static const Color textFaint = Color(0xFF55555C);

  // Radios y espaciado
  static const double radius = 18;
  static const double radiusSm = 12;
  static const double gutter = 20;

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

  // Escala RPE
  static const Color rpeLow = Color(0xFF8E8E96);
  static const Color rpeOptimal = Color(0xFFB8F34A);
  static const Color rpeMid = Color(0xFFE8C25A);
  static const Color rpeHigh = Color(0xFFF0A05A);
  static const Color rpeMax = Color(0xFFF26D5B);

  static Color rpeColor(int rpe) {
    if (rpe <= 6) return rpeLow;
    if (rpe <= 8) return rpeOptimal;
    if (rpe == 9) return rpeMid;
    if (rpe >= 10) return rpeMax;
    return rpeHigh;
  }

  // Gradientes
  static const Gradient primaryGradient = LinearGradient(colors: [primary, primary]);
  static const Gradient warmupGradient = LinearGradient(
    colors: [Color(0xFFFF9F43), Color(0xFFFF6A55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient deloadGradient = LinearGradient(
    colors: [Color(0xFF5B9DFF), Color(0xFF7C5CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient progressGradient = primaryGradient;
  static const Gradient aiGradient = LinearGradient(colors: [surfaceMid, surfaceMid]);

  /// Números grandes con cifras tabulares (no "bailan" al animarse).
  static const TextStyle number = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.black,
      secondary: secondary,
      onSecondary: Colors.black,
      tertiary: ai,
      surface: surfaceDark,
      onSurface: Colors.white,
      onSurfaceVariant: textMuted,
      surfaceContainerLowest: surfaceDark,
      surfaceContainerLow: surfaceMid,
      surfaceContainer: surfaceMid,
      surfaceContainerHigh: surfaceLight,
      surfaceContainerHighest: surfaceLight,
      outline: border,
      outlineVariant: border,
    );
    const t = TextStyle(fontFamily: 'Inter', color: Colors.white);
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceDark,
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: gutter,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: surfaceMid,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: surfaceLight,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: t.copyWith(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm + 2)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: t.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm + 2)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: t.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMid,
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? Colors.white : textFaint,
              size: 24,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => t.copyWith(
              fontSize: 11,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? Colors.white : textFaint,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceMid,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primary.withOpacity(0.18),
        side: const BorderSide(color: border),
        labelStyle: t.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        secondaryLabelStyle: t.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
        checkmarkColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primary : surfaceMid),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? Colors.black : Colors.white),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          textStyle: WidgetStatePropertyAll(t.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: primary,
        labelColor: Colors.white,
        unselectedLabelColor: textMuted,
        dividerColor: border,
        labelStyle: t.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: t.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textMuted,
        titleTextStyle: t.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        subtitleTextStyle: t.copyWith(fontSize: 13, color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: gutter),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceMid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: const BorderSide(color: border)),
        titleTextStyle: t.copyWith(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        contentTextStyle: t.copyWith(fontSize: 14, color: const Color(0xFFC9CDD6), height: 1.45),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceMid,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: surfaceHigher,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigher,
        contentTextStyle: t.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm), side: const BorderSide(color: border)),
        textStyle: t.copyWith(fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary, linearTrackColor: surfaceLight),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.black : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : surfaceLight),
        trackOutlineColor: const WidgetStatePropertyAll(border),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceLight,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.15),
        trackHeight: 5,
        valueIndicatorTextStyle: t.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        extendedTextStyle: t.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      dividerColor: border,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.6, height: 1.05),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.1),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
        headlineMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFC9CDD6), height: 1.45),
        bodySmall: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 0.8),
      ).apply(fontFamily: 'Inter'),
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
