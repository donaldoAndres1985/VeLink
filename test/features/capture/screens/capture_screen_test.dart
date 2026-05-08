import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/capture/screens/capture_screen.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/mock_capture_service.dart';

Widget buildCaptureWidget(String url) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(createTestDatabase()),
      captureServiceProvider.overrideWithValue(MockCaptureService()),
    ],
    child: MaterialApp(home: CaptureScreen(url: url)),
  );
}

void main() {
  group('CaptureScreen — contenido', () {
    testWidgets('muestra el URL capturado', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://youtube.com/watch?v=abc123'));
      expect(find.text('https://youtube.com/watch?v=abc123'), findsOneWidget);
    });

    testWidgets('muestra botón Guardar', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('muestra botón Cancelar', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });

  group('CaptureScreen — Guardar', () {
    testWidgets('guarda el link en la base de datos al tocar Guardar', (tester) async {
      final db = createTestDatabase();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            captureServiceProvider.overrideWithValue(MockCaptureService()),
          ],
          child: const MaterialApp(home: CaptureScreen(url: 'https://github.com/flutter')),
        ),
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.url, 'https://github.com/flutter');
    });

    testWidgets('cierra la pantalla después de guardar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(createTestDatabase()),
            captureServiceProvider.overrideWithValue(MockCaptureService()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaptureScreen(url: 'https://example.com'),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsOneWidget);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);
    });
  });

  group('CaptureScreen — Cancelar', () {
    testWidgets('cierra la pantalla sin guardar al tocar Cancelar', (tester) async {
      final db = createTestDatabase();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            captureServiceProvider.overrideWithValue(MockCaptureService()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaptureScreen(url: 'https://example.com'),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);

      final links = await db.getAllLinks();
      expect(links, isEmpty);
    });
  });
}
