import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/settings/screens/settings_screen.dart';

void main() {
  group('AjustesScreen — app bar', () {
    testWidgets('muestra título Ajustes en el app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AjustesScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);
    });
  });

  group('AjustesScreen — contenido', () {
    testWidgets('muestra sección de configuración', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AjustesScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Próximamente'), findsOneWidget);
    });
  });
}
