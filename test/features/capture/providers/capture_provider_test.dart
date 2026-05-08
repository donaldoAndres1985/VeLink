import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/mock_capture_service.dart';

ProviderContainer createCaptureContainer({MockCaptureService? service}) {
  final db = createTestDatabase();
  final mock = service ?? MockCaptureService();
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      captureServiceProvider.overrideWithValue(mock),
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

  group('CaptureProvider — saveLink', () {
    test('inserta el link en la base de datos', () async {
      final db = createTestDatabase();
      final mock = MockCaptureService();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(mock),
        ],
      );

      container.read(captureProvider.notifier).setUrl('https://youtube.com/watch?v=test');
      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.url, 'https://youtube.com/watch?v=test');
    });

    test('resetea el estado después de guardar', () async {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).setUrl('https://example.com');
      await container.read(captureProvider.notifier).saveLink();

      final state = container.read(captureProvider);
      expect(state.pendingUrl, equals(null));
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
      final mock = MockCaptureService();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          captureServiceProvider.overrideWithValue(mock),
        ],
      );

      await container.read(captureProvider.notifier).saveLink();

      final links = await db.getAllLinks();
      expect(links, isEmpty);
    });
  });

  group('CaptureProvider — dismiss', () {
    test('limpia el pendingUrl', () {
      final container = createCaptureContainer();
      container.read(captureProvider.notifier).setUrl('https://example.com');
      container.read(captureProvider.notifier).dismiss();
      expect(container.read(captureProvider).pendingUrl, equals(null));
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
