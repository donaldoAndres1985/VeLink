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
}
