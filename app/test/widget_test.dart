import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superfit/main.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SuperFitApp()),
    );
    // Deja terminar las animaciones de entrada (usan temporizadores con retardo).
    await tester.pump(const Duration(seconds: 3));
    // No assertion: we only verify it doesn't crash.
  });
}
