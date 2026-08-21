import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/models/og_metadata.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/capture/services/image_cache_service.dart';
import 'package:velink/features/capture/services/image_picker_service.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/mock_capture_service.dart';
import '../../../helpers/mock_image_cache_service.dart';
import '../../../helpers/mock_image_picker_service.dart';
import '../../../helpers/mock_metadata_service.dart';

ProviderContainer createCaptureContainer({
  MockCaptureService? service,
  MockMetadataService? metadataService,
  ImagePickerService? imagePicker,
  ImageCacheService? imageCache,
}) {
  final db = createTestDatabase();
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      captureServiceProvider.overrideWithValue(service ?? MockCaptureService()),
      metadataServiceProvider.overrideWithValue(metadataService ?? MockMetadataService()),
      imagePickerServiceProvider.overrideWithValue(imagePicker ?? MockImagePickerService()),
      imageCacheServiceProvider.overrideWithValue(imageCache ?? MockImageCacheService()),
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

  group('CaptureProvider — título del intent', () {
    test('recibe título del titleStream del servicio', () async {
      final mock = MockCaptureService();
      final container = createCaptureContainer(service: mock);
      container.read(captureProvider);

      mock.emitTitle('Título desde el intent de Facebook');
      await Future.microtask(() {});

      expect(container.read(captureProvider).manualTitle,
          'Título desde el intent de Facebook');
    });

    test('título vacío del stream no sobreescribe el estado', () async {
      final mock = MockCaptureService();
      final container = createCaptureContainer(service: mock);
      container.read(captureProvider.notifier).setTitle('Título manual');

      mock.emitTitle('');
      await Future.microtask(() {});

      expect(container.read(captureProvider).manualTitle, 'Título manual');
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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

  group('CaptureProvider — toggleFavorite', () {
    test('cambia isFavorite de false a true', () {
      final container = createCaptureContainer();
      expect(container.read(captureProvider).isFavorite, isFalse);
      container.read(captureProvider.notifier).toggleFavorite();
      expect(container.read(captureProvider).isFavorite, isTrue);
    });

    test('alterna isFavorite en cada llamada', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).toggleFavorite();
      container.read(captureProvider.notifier).toggleFavorite();
      expect(container.read(captureProvider).isFavorite, isFalse);
    });
  });

  group('CaptureProvider — setTitle', () {
    test('actualiza manualTitle con el texto proporcionado', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).setTitle('Mi título');
      expect(container.read(captureProvider).manualTitle, 'Mi título');
    });

    test('establece manualTitle en null cuando el texto está vacío', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).setTitle('algo');
      container.read(captureProvider.notifier).setTitle('');
      expect(container.read(captureProvider).manualTitle, isNull);
    });
  });

  group('CaptureProvider — saveLink con manualTitle', () {
    test('usa manualTitle cuando está disponible', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        ],
      );
      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).setTitle('Título manual');
      await container.read(captureProvider.notifier).saveLink();
      final links = await db.getAllLinks();
      expect(links.first.title, 'Título manual');
    });

    test('lanza DuplicateUrlException si la URL ya existe', () async {
      final db = createTestDatabase();
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        ],
      );
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await expectLater(
        container.read(captureProvider.notifier).saveLink(),
        throwsA(isA<DuplicateUrlException>()),
      );
      final links = await db.getAllLinks();
      expect(links.length, 1);
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        ],
      );

      await container.read(captureProvider.notifier).createTag('flutter');

      final tags = await db.watchAllTags().first;
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });
  });

  group('CaptureProvider — saveLink con tags y favorito', () {
    test('guarda el link como favorito cuando isFavorite es true', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).toggleFavorite();
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.isFavorite, isTrue);
    });

    test('guarda el link como no favorito por defecto', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.first.isFavorite, isFalse);
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
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
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

    test('resetea selectedTagIds e isFavorite después de guardar', () async {
      final db = createTestDatabase();
      final tagId = await db.insertTag(TagsCompanion(name: Value('test')));
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).toggleTag(tagId);
      container.read(captureProvider.notifier).toggleFavorite();
      await container.read(captureProvider.notifier).saveLink();

      final state = container.read(captureProvider);
      expect(state.selectedTagIds, isEmpty);
      expect(state.isFavorite, isFalse);
    });
  });

  group('CaptureProvider — imagen', () {
    test('pickedImagePath inicia en null', () {
      final container = createCaptureContainer();
      expect(container.read(captureProvider).pickedImagePath, isNull);
    });

    test('isPickingImage inicia en false', () {
      final container = createCaptureContainer();
      expect(container.read(captureProvider).isPickingImage, isFalse);
    });

    test('pickFromGallery establece pickedImagePath cuando tiene éxito', () async {
      final container = createCaptureContainer(
        imagePicker: MockImagePickerService(galleryPath: '/tmp/image.jpg'),
      );
      await container.read(captureProvider.notifier).pickFromGallery();
      expect(container.read(captureProvider).pickedImagePath, '/tmp/image.jpg');
      expect(container.read(captureProvider).isPickingImage, isFalse);
    });

    test('pickFromGallery no cambia pickedImagePath cuando devuelve null', () async {
      final container = createCaptureContainer(
        imagePicker: MockImagePickerService(galleryPath: null),
      );
      await container.read(captureProvider.notifier).pickFromGallery();
      expect(container.read(captureProvider).pickedImagePath, isNull);
      expect(container.read(captureProvider).isPickingImage, isFalse);
    });

    test('pickFromCamera establece pickedImagePath cuando tiene éxito', () async {
      final container = createCaptureContainer(
        imagePicker: MockImagePickerService(cameraPath: '/tmp/camera.jpg'),
      );
      await container.read(captureProvider.notifier).pickFromCamera();
      expect(container.read(captureProvider).pickedImagePath, '/tmp/camera.jpg');
    });

    test('pickFromGallery establece pickImageError cuando falla', () async {
      final container = createCaptureContainer(
        imagePicker: MockImagePickerService(shouldThrow: true),
      );
      await container.read(captureProvider.notifier).pickFromGallery();
      expect(container.read(captureProvider).pickImageError, isTrue);
      expect(container.read(captureProvider).pickedImagePath, isNull);
    });

    test('clearPickedImage elimina pickedImagePath', () async {
      final container = createCaptureContainer(
        imagePicker: MockImagePickerService(galleryPath: '/tmp/image.jpg'),
      );
      await container.read(captureProvider.notifier).pickFromGallery();
      container.read(captureProvider.notifier).clearPickedImage();
      expect(container.read(captureProvider).pickedImagePath, isNull);
    });

    test('saveLink guarda previewImagePath cuando hay imagen local', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        captureServiceProvider.overrideWithValue(MockCaptureService()),
        metadataServiceProvider.overrideWithValue(MockMetadataService()),
        imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        imagePickerServiceProvider.overrideWithValue(
          MockImagePickerService(galleryPath: '/tmp/image.jpg'),
        ),
      ]);
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).pickFromGallery();
      await container.read(captureProvider.notifier).saveLink();
      final links = await db.getAllLinks();
      expect(links.first.previewImagePath, '/tmp/image.jpg');
    });

    test('saveLink guarda previewImagePath null cuando no hay imagen', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        captureServiceProvider.overrideWithValue(MockCaptureService()),
        metadataServiceProvider.overrideWithValue(MockMetadataService()),
        imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        imagePickerServiceProvider.overrideWithValue(MockImagePickerService()),
      ]);
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();
      final links = await db.getAllLinks();
      expect(links.first.previewImagePath, isNull);
    });

    test('saveLink resetea pickedImagePath después de guardar', () async {
      final db = createTestDatabase();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        captureServiceProvider.overrideWithValue(MockCaptureService()),
        metadataServiceProvider.overrideWithValue(MockMetadataService()),
        imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        imagePickerServiceProvider.overrideWithValue(
          MockImagePickerService(galleryPath: '/tmp/image.jpg'),
        ),
      ]);
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).pickFromGallery();
      await container.read(captureProvider.notifier).saveLink();
      expect(container.read(captureProvider).pickedImagePath, isNull);
    });
  });

  group('CaptureProvider — cache local de la imagen OG (bug: preview se rompe al expirar la URL)', () {
    test('saveLink cachea la imagen OG y guarda la ruta local en previewImagePath', () async {
      final mockMeta = OgMetadata(imageUrl: 'https://cdn.com/og.jpg');
      final imageCache = MockImageCacheService(result: '/data/link_previews/1.jpg');
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: mockMeta),
        imageCache: imageCache,
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).fetchMetadata('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      expect(imageCache.requestedUrls, ['https://cdn.com/og.jpg']);
      final links = await container.read(databaseProvider).getAllLinks();
      expect(links.first.previewImagePath, '/data/link_previews/1.jpg');
      expect(links.first.previewImageUrl, 'https://cdn.com/og.jpg');
    });

    test('si el cache falla (URL vencida, sin red), previewImagePath queda null sin romper el guardado', () async {
      final mockMeta = OgMetadata(imageUrl: 'https://cdn.com/og-vencida.jpg');
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: mockMeta),
        imageCache: MockImageCacheService(result: null),
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).fetchMetadata('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      final links = await container.read(databaseProvider).getAllLinks();
      expect(links.first.previewImagePath, isNull);
      expect(links.first.previewImageUrl, 'https://cdn.com/og-vencida.jpg');
    });

    test('una imagen elegida manualmente tiene prioridad: no se cachea la OG', () async {
      final mockMeta = OgMetadata(imageUrl: 'https://cdn.com/og.jpg');
      final imageCache = MockImageCacheService(result: '/data/link_previews/1.jpg');
      final container = createCaptureContainer(
        metadataService: MockMetadataService(result: mockMeta),
        imagePicker: MockImagePickerService(galleryPath: '/tmp/manual.jpg'),
        imageCache: imageCache,
      );

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).fetchMetadata('https://example.com');
      await container.read(captureProvider.notifier).pickFromGallery();
      await container.read(captureProvider.notifier).saveLink();

      expect(imageCache.callCount, 0);
      final links = await container.read(databaseProvider).getAllLinks();
      expect(links.first.previewImagePath, '/tmp/manual.jpg');
    });

    test('sin imagen OG, no se llama al servicio de cache', () async {
      final imageCache = MockImageCacheService(result: '/data/link_previews/1.jpg');
      final container = createCaptureContainer(imageCache: imageCache);

      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      expect(imageCache.callCount, 0);
    });
  });
}
