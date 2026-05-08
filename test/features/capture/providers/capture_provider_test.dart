import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/models/og_metadata.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/mock_capture_service.dart';
import '../../../helpers/mock_metadata_service.dart';

ProviderContainer createCaptureContainer({
  MockCaptureService? service,
  MockMetadataService? metadataService,
}) {
  final db = createTestDatabase();
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      captureServiceProvider.overrideWithValue(service ?? MockCaptureService()),
      metadataServiceProvider.overrideWithValue(metadataService ?? MockMetadataService()),
    ],
  );
}

void main() {
  group('CaptureProvider — estado inicial', () {
    test('pendingUrl es null y isSaving es false', () {
      final container = createCaptureContainer();
      final state = container.read(captureProvider);
      expect(state.pendingUrl, equals(null));
      expect(state.isSaving, isFalse);
      expect(state.isFetchingMetadata, isFalse);
      expect(state.metadata, equals(null));
    });
  });

  group('CaptureProvider — setUrl', () {
    test('actualiza pendingUrl con el URL recibido', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).setUrl('https://youtube.com/watch?v=abc');
      expect(container.read(captureProvider).pendingUrl, 'https://youtube.com/watch?v=abc');
    });

    test('recibe URL del stream del servicio', () async {
      final mock = MockCaptureService();
      final container = createCaptureContainer(service: mock);
      container.read(captureProvider); // inicializa el notifier

      mock.emit('https://instagram.com/p/xyz');
      await Future.microtask(() {});

      expect(container.read(captureProvider).pendingUrl, 'https://instagram.com/p/xyz');
    });
  });

  group('CaptureProvider — fetchMetadata', () {
    test('actualiza metadata y desactiva isFetchingMetadata al terminar', () async {
      final mockMeta = OgMetadata(
        title: 'Flutter Docs',
        description: 'Documentacion oficial',
        imageUrl: 'https://flutter.dev/img.png',
      );
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: mockMeta),
      );
      container.read(captureProvider.notifier).setUrl('https://flutter.dev');

      await container.read(captureProvider.notifier).fetchMetadata('https://flutter.dev');

      final state = container.read(captureProvider);
      expect(state.metadata?.title, 'Flutter Docs');
      expect(state.metadata?.description, 'Documentacion oficial');
      expect(state.isFetchingMetadata, isFalse);
    });

    test('metadata queda null si el servicio falla, sin bloquear', () async {
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: null),
      );
      container.read(captureProvider.notifier).setUrl('https://example.com');

      await container.read(captureProvider.notifier).fetchMetadata('https://example.com');

      final state = container.read(captureProvider);
      expect(state.metadata, equals(null));
      expect(state.isFetchingMetadata, isFalse);
    });
  });

  group('CaptureProvider — saveLink con plataforma', () {
    test('detecta y guarda la plataforma de un link de YouTube', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://youtube.com/watch?v=abc');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.platform, 'youtube');
    });

    test('guarda plataforma "web" para URLs no reconocidas', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com/page');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.platform, 'web');
    });
  });

  group('CaptureProvider — saveLink', () {
    test('inserta el link en la base de datos', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://youtube.com/watch?v=test');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.url, 'https://youtube.com/watch?v=test');
    });

    test('guarda titulo, descripcion e imagen de la metadata', () async {
      final db = createTestDatabase();
      final mockMeta = OgMetadata(
        title: 'YouTube',
        description: 'Un video de YouTube',
        imageUrl: 'https://i.ytimg.com/vi/abc.jpg',
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService(result: mockMeta)),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://youtube.com/watch?v=abc');
      await container.read(captureProvider.notifier).fetchMetadata('https://youtube.com/watch?v=abc');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.title, 'YouTube');
      expect(links.first.description, 'Un video de YouTube');
      expect(links.first.previewImageUrl, 'https://i.ytimg.com/vi/abc.jpg');
    });

    test('guarda sin metadata si el scraping fallo', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService(result: null)),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.url, 'https://example.com');
      expect(links.first.title, equals(null));
    });

    test('resetea el estado completo después de guardar', () async {
      final mockMeta = OgMetadata(title: 'Test');
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: mockMeta),
      );
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).fetchMetadata('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      final state = container.read(captureProvider);
      expect(state.pendingUrl, equals(null));
      expect(state.metadata, equals(null));
      expect(state.isSaving, isFalse);
    });

    test('llama reset() en el servicio al guardar', () async {
      final mock = MockCaptureService();
      final container = createCaptureContainer(service: mock);
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();
      expect(mock.resetCalled, isTrue);
    });

    test('no inserta si pendingUrl es null', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );
      await container.read(captureProvider.notifier).saveLink();
      expect(await db.getAllLinks(), isEmpty);
    });
  });

  group('CaptureProvider — dismiss', () {
    test('limpia pendingUrl y metadata', () async {
      final mockMeta = OgMetadata(title: 'Test');
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: mockMeta),
      );
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).fetchMetadata('https://example.com');
      container.read(captureProvider.notifier).dismiss();

      final state = container.read(captureProvider);
      expect(state.pendingUrl, equals(null));
      expect(state.metadata, equals(null));
    });

    test('llama reset() en el servicio al descartar', () {
      final mock = MockCaptureService();
      final container = createCaptureContainer(service: mock);
      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).dismiss();
      expect(mock.resetCalled, isTrue);
    });
  });

  group('CaptureProvider — toggleTag', () {
    test('agrega un tagId a selectedTagIds', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).toggleTag(1);
      expect(container.read(captureProvider).selectedTagIds, contains(1));
    });

    test('remueve un tagId si ya estaba seleccionado', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).toggleTag(1);
      container.read(captureProvider.notifier).toggleTag(1);
      expect(container.read(captureProvider).selectedTagIds, isEmpty);
    });

    test('puede seleccionar multiples tags a la vez', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).toggleTag(1);
      container.read(captureProvider.notifier).toggleTag(2);
      container.read(captureProvider.notifier).toggleTag(3);
      expect(container.read(captureProvider).selectedTagIds, containsAll([1, 2, 3]));
    });
  });

  group('CaptureProvider — togglePriority', () {
    test('cambia isPriority de false a true', () {
      final container = createCaptureContainer();
      expect(container.read(captureProvider).isPriority, isFalse);
      container.read(captureProvider.notifier).togglePriority();
      expect(container.read(captureProvider).isPriority, isTrue);
    });

    test('alterna isPriority en cada llamada', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).togglePriority();
      container.read(captureProvider.notifier).togglePriority();
      expect(container.read(captureProvider).isPriority, isFalse);
    });
  });

  group('CaptureProvider — createTag', () {
    test('inserta un nuevo tag en la base de datos', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      await container.read(captureProvider.notifier).createTag('flutter');

      final tags = await db.watchAllTags().first;
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });
  });

  group('CaptureProvider — saveLink con tags y prioridad', () {
    test('guarda el link como prioritario cuando isPriority es true', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).togglePriority();
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.priority, 1);
    });

    test('guarda el link como no prioritario por defecto', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.priority, 0);
    });

    test('asocia los tags seleccionados al link guardado', () async {
      final db = createTestDatabase();
      final tagId1 = await db.insertTag(TagsCompanion(name: Value('flutter')));
      final tagId2 = await db.insertTag(TagsCompanion(name: Value('dart')));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).toggleTag(tagId1);
      container.read(captureProvider.notifier).toggleTag(tagId2);
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      final tags = await db.getTagsForLink(links.first.id);
      expect(tags.length, 2);
      expect(tags.map((t) => t.name), containsAll(['flutter', 'dart']));
    });

    test('resetea selectedTagIds e isPriority después de guardar', () async {
      final db = createTestDatabase();
      final tagId = await db.insertTag(TagsCompanion(name: Value('test')));
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).toggleTag(tagId);
      container.read(captureProvider.notifier).togglePriority();
      await container.read(captureProvider.notifier).saveLink();

      final state = container.read(captureProvider);
      expect(state.selectedTagIds, isEmpty);
      expect(state.isPriority, isFalse);
    });
  });
}
