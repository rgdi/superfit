// Pantalla de onboarding inicial
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../data/models/user_settings.dart';
import '../../core/theme/app_theme.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  width: 30,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= _step ? AppTheme.primary : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
              const SizedBox(height: 40),
              Expanded(child: _buildStep()),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('← Atrás'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _step < 3 ? () => setState(() => _step++) : _finish,
                    child: Text(_step < 3 ? 'Siguiente' : 'Empezar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        const Icon(Icons.fitness_center, size: 96, color: AppTheme.primary),
        const SizedBox(height: 24),
        const Text(
          'SuperFit',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'La app que se adapta a ti.',
          style: TextStyle(fontSize: 18, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const Text(
          '100% offline · sin cuentas · sin tracking\nbasado en evidencia científica',
          style: TextStyle(fontSize: 14, color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _stepLevel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('¿Cuál es tu nivel?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Para adaptar volumen y progresión', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 24),
        _optionCard('Principiante', 'Entreno desde hace < 6 meses', UserLevel.beginner),
        const SizedBox(height: 12),
        _optionCard('Intermedio', 'Entreno hace 6-24 meses', UserLevel.intermediate),
        const SizedBox(height: 12),
        _optionCard('Avanzado', 'Entreno > 2 años, conozco mi cuerpo', UserLevel.advanced),
      ],
    );
  }

  Widget _stepGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('¿Cuál es tu objetivo?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Ajustamos rango de reps y RPE', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 24),
        _optionCard('Hipertrofia (masa muscular)', '8-12 reps, RPE 7-9', UserGoal.hypertrophy),
        const SizedBox(height: 12),
        _optionCard('Fuerza', '4-6 reps, RPE 8-9', UserGoal.strength),
        const SizedBox(height: 12),
        _optionCard('Mantenimiento', '10-12 reps, RPE 7', UserGoal.maintenance),
        const SizedBox(height: 12),
        _optionCard('Definición', '12-15 reps, RPE 8', UserGoal.definition),
      ],
    );
  }

  Widget _stepUnits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Preferencias', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        const Text('Unidades', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _pickCard('kg', _units == WeightUnits.kg, () => setState(() => _units = WeightUnits.kg))),
            const SizedBox(width: 12),
            Expanded(child: _pickCard('lb', _units == WeightUnits.lb, () => setState(() => _units = WeightUnits.lb))),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Idioma', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _pickCard('Español', _locale == 'es', () => setState(() => _locale = 'es'))),
            const SizedBox(width: 12),
            Expanded(child: _pickCard('English', _locale == 'en', () => setState(() => _locale = 'en'))),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMid,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tus datos viven SOLO en este dispositivo. Nada de nube, nada de cuentas.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _optionCard(String title, String subtitle, Object value) {
    final isSelected = _step == 1 ? _level == value : _goal == value;
    return InkWell(
      onTap: () => setState(() {
        if (_step == 1) _level = value as UserLevel;
        if (_step == 2) _goal = value as UserGoal;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : Colors.white60,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickCard(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.primary : Colors.white,
            ),
          ),
        ),
      ),
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
