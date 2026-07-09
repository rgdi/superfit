// Splash screen con animación
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class SplashWidget extends StatelessWidget {
  const SplashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF1A2A1E), AppTheme.surfaceDark],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary,
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.fitness_center, size: 60, color: Colors.black),
            ).animate()
              .scale(duration: 800.ms, curve: Curves.easeOutBack)
              .then(delay: 200.ms)
              .shimmer(duration: 1500.ms, color: Colors.white),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (rect) => AppTheme.primaryGradient.createShader(rect),
              child: const Text(
                'SuperFit',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            const Text(
              'se adapta a ti',
              style: TextStyle(fontSize: 14, color: Colors.white60, fontWeight: FontWeight.w500),
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 60),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                minHeight: 3,
              ),
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
