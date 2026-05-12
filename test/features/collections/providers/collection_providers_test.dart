import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/collections/providers/collection_providers.dart';
import '../../../helpers/database_helper.dart';

ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    container = _makeContainer(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('allCollectionsProvider', () {
    test('emite lista vacía inicialmente', () async {
      final result = await container.read(allCollectionsProvider.future);
      expect(result, isEmpty);
    });

    test('emite colecciones después de insertar', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'Flutter'));
      final result = await container.read(allCollectionsProvider.future);
      expect(result.length, 1);
      expect(result.first.name, 'Flutter');
    });

    test('emite colecciones ordenadas por nombre', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'Z'));
      await db.insertCollection(CollectionsCompanion.insert(name: 'A'));
      final result = await container.read(allCollectionsProvider.future);
      expect(result.map((c) => c.name).toList(), ['A', 'Z']);
    });
  });

  group('collectionLinkCountProvider', () {
    test('retorna 0 para colección vacía', () async {
      final id = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final count = await container.read(collectionLinkCountProvider(id).future);
      expect(count, 0);
    });

    test('retorna conteo correcto', () async {
      final id = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final l1 = await db.insertLink(LinksCompanion.insert(url: 'https://a.com'));
      final l2 = await db.insertLink(LinksCompanion.insert(url: 'https://b.com'));
      await db.addLinkToCollection(l1, id);
      await db.addLinkToCollection(l2, id);
      final count = await container.read(collectionLinkCountProvider(id).future);
      expect(count, 2);
    });
  });

  group('collectionLastLinkProvider', () {
    test('retorna null para colección vacía', () async {
      final id = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final last = await container.read(collectionLastLinkProvider(id).future);
      expect(last, isNull);
    });

    test('retorna link más reciente', () async {
      final id = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final lId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      await db.addLinkToCollection(lId, id);
      final last = await container.read(collectionLastLinkProvider(id).future);
      expect(last?.url, 'https://flutter.dev');
    });
  });

  group('collectionsForLinkProvider', () {
    test('emite lista vacía cuando link no tiene colecciones', () async {
      final lId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final result = await container.read(collectionsForLinkProvider(lId).future);
      expect(result, isEmpty);
    });

    test('emite colecciones del link', () async {
      final lId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final c1 = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final c2 = await db.insertCollection(CollectionsCompanion.insert(name: 'Flutter'));
      await db.addLinkToCollection(lId, c1);
      await db.addLinkToCollection(lId, c2);
      final result = await container.read(collectionsForLinkProvider(lId).future);
      expect(result.length, 2);
    });
  });

  group('linksInCollectionProvider', () {
    test('emite lista vacía cuando colección no tiene links', () async {
      final id = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final result = await container.read(linksInCollectionProvider(id).future);
      expect(result, isEmpty);
    });

    test('emite links de la colección', () async {
      final id = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final lId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      await db.addLinkToCollection(lId, id);
      final result = await container.read(linksInCollectionProvider(id).future);
      expect(result.length, 1);
      expect(result.first.url, 'https://flutter.dev');
    });
  });
}
