import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/models/og_metadata.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/capture/screens/capture_screen.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/mock_capture_service.dart';
import '../../../helpers/mock_metadata_service.dart';

Widget buildCaptureWidget(String url, {MockMetadataService? metadataService}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(createTestDatabase()),
      captureServiceProvider.overrideWithValue(MockCaptureService()),
      metadataServiceProvider.overrideWithValue(
        metadataService ?? MockMetadataService(),
      ),
    ],
    child: MaterialApp(home: CaptureScreen(url: url)),
  );
}

void main() {
  group('CaptureScreen — contenido básico', () {
    testWidgets('muestra el URL capturado', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://youtube.com/watch?v=abc123'));
      await tester.pumpAndSettle();
      expect(find.text('https://youtube.com/watch?v=abc123'), findsOneWidget);
    });

    testWidgets('muestra botón Guardar', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      await tester.pumpAndSettle();
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('muestra botón Cancelar', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });

  group('CaptureScreen — metadata OG', () {
    testWidgets('muestra el titulo cuando la metadata está disponible', (tester) async {
      final mockMeta = OgMetadata(title: 'Flutter — Beautiful UI toolkit');
      await tester.pumpWidget(
        buildCaptureWidget(
          'https://flutter.dev',
          metadataService: MockMetadataService(result: mockMeta),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Flutter — Beautiful UI toolkit'), findsOneWidget);
    });

    testWidgets('muestra la descripcion cuando la metadata está disponible', (tester) async {
      final mockMeta = OgMetadata(
        title: 'Flutter',
        description: 'Build apps for any screen',
      );
      await tester.pumpWidget(
        buildCaptureWidget(
          'https://flutter.dev',
          metadataService: MockMetadataService(result: mockMeta),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Build apps for any screen'), findsOneWidget);
    });

    testWidgets('muestra placeholder cuando no hay metadata', (tester) async {
      await tester.pumpWidget(
        buildCaptureWidget(
          'https://example.com',
          metadataService: MockMetadataService(result: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsOneWidget);
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
            metadataServiceProvider.overrideWithValue(MockMetadataService()),
          ],
          child: const MaterialApp(home: CaptureScreen(url: 'https://github.com/flutter')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.url, 'https://github.com/flutter');
    });

    testWidgets('guarda con metadata cuando el scraping tuvo éxito', (tester) async {
      final db = createTestDatabase();
      final mockMeta = OgMetadata(
        title: 'GitHub Flutter',
        description: 'Flutter framework repo',
        imageUrl: 'https://github.com/img.png',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            captureServiceProvider.overrideWithValue(MockCaptureService()),
            metadataServiceProvider.overrideWithValue(MockMetadataService(result: mockMeta)),
          ],
          child: const MaterialApp(home: CaptureScreen(url: 'https://github.com/flutter')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.title, 'GitHub Flutter');
      expect(links.first.description, 'Flutter framework repo');
      expect(links.first.previewImageUrl, 'https://github.com/img.png');
    });

    testWidgets('cierra la pantalla después de guardar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(createTestDatabase()),
            captureServiceProvider.overrideWithValue(MockCaptureService()),
            metadataServiceProvider.overrideWithValue(MockMetadataService()),
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

  group('CaptureScreen — plataforma', () {
    testWidgets('muestra el nombre de la plataforma detectada', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://youtube.com/watch?v=abc'));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('muestra "Web" para links no reconocidos', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com/page'));
      await tester.pumpAndSettle();
      expect(find.text('Web'), findsOneWidget);
    });

    testWidgets('detecta GitHub correctamente', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://github.com/flutter/flutter'));
      await tester.pumpAndSettle();
      expect(find.text('GitHub'), findsOneWidget);
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
            metadataServiceProvider.overrideWithValue(MockMetadataService()),
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

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);

      final links = await db.getAllLinks();
      expect(links, isEmpty);
    });
  });
}
