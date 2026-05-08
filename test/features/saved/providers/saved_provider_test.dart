import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/saved/providers/saved_provider.dart';
import '../../../helpers/database_helper.dart';

void main() {
  group('savedLinksProvider', () {
    test('devuelve lista vacía cuando no hay links', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final links = await container.read(savedLinksProvider.future);
      expect(links, isEmpty);
    });

    test('devuelve todos los links guardados', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await db.insertLink(LinksCompanion(url: const Value('https://flutter.dev')));
      await db.insertLink(LinksCompanion(url: const Value('https://dart.dev')));
      await db.insertLink(LinksCompanion(url: const Value('https://pub.dev')));

      final links = await container.read(savedLinksProvider.future);
      expect(links.length, 3);
    });

    test('devuelve los links ordenados por fecha más reciente primero', () async {
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

      final links = await container.read(savedLinksProvider.future);
      expect(links.first.url, 'https://example.com/reciente');
      expect(links.last.url, 'https://example.com/antiguo');
    });
  });

  group('filteredSavedLinksProvider', () {
    test('sin tag seleccionado devuelve todos los links', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await db.insertLink(LinksCompanion(url: const Value('https://flutter.dev')));
      await db.insertLink(LinksCompanion(url: const Value('https://dart.dev')));

      final links = await container.read(filteredSavedLinksProvider.future);
      expect(links.length, 2);
    });

    test('con tag seleccionado devuelve solo los links con ese tag', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final tagId = await db.insertTag(TagsCompanion(name: const Value('flutter')));
      final id1 = await db.insertLink(LinksCompanion(url: const Value('https://flutter.dev')));
      await db.insertLink(LinksCompanion(url: const Value('https://dart.dev')));
      await db.addTagToLink(id1, tagId);

      container.read(selectedTagIdProvider.notifier).state = tagId;

      final links = await container.read(filteredSavedLinksProvider.future);
      expect(links.length, 1);
      expect(links.first.url, 'https://flutter.dev');
    });

    test('al cambiar el tag seleccionado actualiza los links mostrados', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final tagFlutter = await db.insertTag(TagsCompanion(name: const Value('flutter')));
      final tagDart = await db.insertTag(TagsCompanion(name: const Value('dart')));
      final id1 = await db.insertLink(LinksCompanion(url: const Value('https://flutter.dev')));
      final id2 = await db.insertLink(LinksCompanion(url: const Value('https://dart.dev')));
      await db.addTagToLink(id1, tagFlutter);
      await db.addTagToLink(id2, tagDart);

      container.read(selectedTagIdProvider.notifier).state = tagFlutter;
      final linksFlutter = await container.read(filteredSavedLinksProvider.future);
      expect(linksFlutter.length, 1);
      expect(linksFlutter.first.url, 'https://flutter.dev');

      container.read(selectedTagIdProvider.notifier).state = tagDart;
      final linksDart = await container.read(filteredSavedLinksProvider.future);
      expect(linksDart.length, 1);
      expect(linksDart.first.url, 'https://dart.dev');
    });
  });
}
