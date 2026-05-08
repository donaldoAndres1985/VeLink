import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/home/providers/home_provider.dart';
import '../../../helpers/database_helper.dart';

void main() {
  group('recentLinksProvider', () {
    test('devuelve lista vacía cuando no hay links', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final links = await container.read(recentLinksProvider.future);
      expect(links, isEmpty);
    });

    test('devuelve los links más recientes primero', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final now = DateTime.now();
      await db.insertLink(LinksCompanion(
        url: const Value('https://example.com/antiguo'),
        createdAt: Value(now.subtract(const Duration(hours: 2))),
      ));
      await db.insertLink(LinksCompanion(
        url: const Value('https://example.com/reciente'),
        createdAt: Value(now.subtract(const Duration(hours: 1))),
      ));

      final links = await container.read(recentLinksProvider.future);
      expect(links.length, 2);
      expect(links.first.url, 'https://example.com/reciente');
      expect(links.last.url, 'https://example.com/antiguo');
    });

    test('refleja cambios al insertar un nuevo link', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await db.insertLink(LinksCompanion(url: const Value('https://flutter.dev')));

      final links = await container.read(recentLinksProvider.future);
      expect(links.length, 1);
      expect(links.first.url, 'https://flutter.dev');
    });
  });
}
