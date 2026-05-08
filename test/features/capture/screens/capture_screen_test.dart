import 'package:drift/drift.dart' hide isNull;
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
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      captureServiceProvider.overrideWithValue(MockCaptureService()),
      metadataServiceProvider.overrideWithValue(metadataService ?? MockMetadataService()),
      // Avoid opening a Drift watch stream — its zero-duration cleanup timer
      // fires after ProviderScope disposal, triggering a pending-timer assertion.
      allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
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
      await tester.pumpWidget(buildCaptureWidget(
        'https://flutter.dev',
        metadataService: MockMetadataService(result: mockMeta),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter — Beautiful UI toolkit'), findsOneWidget);
    });

    testWidgets('muestra la descripcion cuando la metadata está disponible', (tester) async {
      final mockMeta = OgMetadata(title: 'Flutter', description: 'Build apps for any screen');
      await tester.pumpWidget(buildCaptureWidget(
        'https://flutter.dev',
        metadataService: MockMetadataService(result: mockMeta),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Build apps for any screen'), findsOneWidget);
    });

    testWidgets('muestra placeholder cuando no hay metadata', (tester) async {
      await tester.pumpWidget(buildCaptureWidget(
        'https://example.com',
        metadataService: MockMetadataService(result: null),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsOneWidget);
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

  group('CaptureScreen — tags', () {
    testWidgets('muestra chips de los tags disponibles en la base de datos', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertTag(TagsCompanion(name: Value('flutter')));
      await db.insertTag(TagsCompanion(name: Value('dart')));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
        child: const MaterialApp(home: CaptureScreen(url: 'https://example.com')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('tap en chip de tag lo marca como seleccionado', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertTag(TagsCompanion(name: Value('flutter')));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
        child: const MaterialApp(home: CaptureScreen(url: 'https://example.com')),
      ));
      await tester.pumpAndSettle();

      final chipBefore = tester.widget<FilterChip>(find.byType(FilterChip).first);
      expect(chipBefore.selected, isFalse);

      await tester.tap(find.text('flutter'));
      await tester.pump();

      final chipAfter = tester.widget<FilterChip>(find.byType(FilterChip).first);
      expect(chipAfter.selected, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('tap en + abre dialogo para crear nuevo tag', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo tag'), findsOneWidget);
    });

    testWidgets('crear nuevo tag desde el dialogo lo añade a la pantalla', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
        child: const MaterialApp(home: CaptureScreen(url: 'https://example.com')),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nuevo-tag');
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('nuevo-tag'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });

  group('CaptureScreen — prioridad', () {
    testWidgets('muestra switch de prioridad', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch de prioridad inicia en false', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      await tester.pumpAndSettle();
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse);
    });

    testWidgets('tap en switch activa la prioridad', (tester) async {
      await tester.pumpWidget(buildCaptureWidget('https://example.com'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
    });
  });

  group('CaptureScreen — Guardar', () {
    testWidgets('guarda el link en la base de datos al tocar Guardar', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: const MaterialApp(home: CaptureScreen(url: 'https://github.com/flutter')),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.url, 'https://github.com/flutter');
    });

    testWidgets('guarda con metadata cuando el scraping tuvo éxito', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final mockMeta = OgMetadata(
        title: 'GitHub Flutter',
        description: 'Flutter framework repo',
        imageUrl: 'https://github.com/img.png',
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService(result: mockMeta)),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: const MaterialApp(home: CaptureScreen(url: 'https://github.com/flutter')),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.title, 'GitHub Flutter');
      expect(links.first.description, 'Flutter framework repo');
      expect(links.first.previewImageUrl, 'https://github.com/img.png');
    });

    testWidgets('cierra la pantalla después de guardar', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
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
      ));
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
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
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
      ));
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
