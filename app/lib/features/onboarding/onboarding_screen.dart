// Onboarding rediseñado: animado, con gradientes, más vivo
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_settings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  UserLevel _level = UserLevel.intermediate;
  UserGoal _goal = UserGoal.hypertrophy;
  WeightUnits _units = WeightUnits.kg;
  String _locale = 'es';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF1A2A1E), AppTheme.surfaceDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _progressIndicator(),
                const SizedBox(height: 40),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.1, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
                  ),
                ),
                _bottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i <= _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: active ? 40 : 30,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _stepWelcome();
      case 1: return _stepLevel();
      case 2: return _stepGoal();
      case 3: return _stepUnits();
      default: return Container();
    }
  }

  Widget _stepWelcome() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary,
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.fitness_center, size: 70, color: Colors.black),
        ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).then().shimmer(duration: 1500.ms),
        const SizedBox(height: 32),
        ShaderMask(
          shaderCallback: (rect) => AppTheme.primaryGradient.createShader(rect),
          child: const Text(
            'SuperFit',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
        const SizedBox(height: 12),
        const Text(
          'La app que se adapta a ti.',
          style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
        const Text(
          '100% offline · sin cuentas · sin tracking\nbasado en evidencia científica',
          style: TextStyle(fontSize: 14, color: Colors.white54),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _stepLevel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('¿Cuál es tu nivel?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)).animate().fadeIn(),
        const SizedBox(height: 4),
        const Text('Para adaptar volumen y progresión', style: TextStyle(color: Colors.white60)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        _optionCard('Principiante', 'Entreno hace < 6 meses', Icons.school, UserLevel.beginner, _level),
        const SizedBox(height: 12),
        _optionCard('Intermedio', '6-24 meses entrenando', Icons.bolt, UserLevel.intermediate, _level),
        const SizedBox(height: 12),
        _optionCard('Avanzado', 'Más de 2 años, conozco mi cuerpo', Icons.local_fire_department, UserLevel.advanced, _level),
      ],
    );
  }

  Widget _stepGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('¿Cuál es tu objetivo?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)).animate().fadeIn(),
        const SizedBox(height: 4),
        const Text('Ajustamos rango de reps y RPE', style: TextStyle(color: Colors.white60)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        _optionCard('Hipertrofia (masa)', '8-12 reps, RPE 7-9', Icons.fitness_center, UserGoal.hypertrophy, _goal),
        const SizedBox(height: 12),
        _optionCard('Fuerza', '4-6 reps, RPE 8-9', Icons.flash_on, UserGoal.strength, _goal),
        const SizedBox(height: 12),
        _optionCard('Mantenimiento', '10-12 reps, RPE 7', Icons.balance, UserGoal.maintenance, _goal),
        const SizedBox(height: 12),
        _optionCard('Definición', '12-15 reps, RPE 8', Icons.local_fire_department, UserGoal.definition, _goal),
      ],
    );
  }

  Widget _stepUnits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Preferencias', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)).animate().fadeIn(),
        const SizedBox(height: 24),
        const Text('Unidades', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _pickCard('kg', 'Kilogramos', _units == WeightUnits.kg, () => setState(() => _units = WeightUnits.kg))),
            const SizedBox(width: 12),
            Expanded(child: _pickCard('lb', 'Libras', _units == WeightUnits.lb, () => setState(() => _units = WeightUnits.lb))),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Idioma', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _pickCard('🇪🇸', 'Español', _locale == 'es', () => setState(() => _locale = 'es'))),
            const SizedBox(width: 12),
            Expanded(child: _pickCard('🇬🇧', 'English', _locale == 'en', () => setState(() => _locale = 'en'))),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withOpacity(0.15),
                AppTheme.primaryDark.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield, color: AppTheme.primary, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tus datos viven SOLO en este dispositivo.\nNada de nube, nada de cuentas, nada de tracking.',
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _optionCard<T>(String title, String subtitle, IconData icon, T value, T current) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => setState(() {
        if (T == UserLevel) _level = value as UserLevel;
        if (T == UserGoal) _goal = value as UserGoal;
      }),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.25), AppTheme.primaryDark.withOpacity(0.1)],
                )
              : null,
          color: isSelected ? null : AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary)
                  .animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }

  Widget _pickCard(String emoji, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return Row(
      children: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('← Atrás', style: TextStyle(fontSize: 16)),
          ),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _step < 3 ? () => setState(() => _step++) : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            ),
            child: Text(_step < 3 ? 'Siguiente →' : 'Empezar 💪'),
          ),
        ),
      ],
    );
  }

  Future<void> _finish() async {
    final settings = UserSettings(
      level: _level,
      goal: _goal,
      units: _units,
      locale: _locale,
      planStartDate: DateTime.now(),
      currentWeek: 1,
      currentDeload: false,
    );
    await ref.read(userSettingsProvider.notifier).update(settings);
    await ref.read(userSettingsProvider.notifier).markOnboardingDone();
    if (mounted) context.go('/');
  }
}
