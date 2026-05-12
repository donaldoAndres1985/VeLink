import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import '../../helpers/database_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Collections — CRUD ──────────────────────────────────────────────────────

  group('Collections — CRUD', () {
    test('insertar una colección y recuperarla', () async {
      final id = await db.insertCollection(
        CollectionsCompanion.insert(name: 'Flutter'),
      );
      final cols = await db.getAllCollections();
      expect(cols.length, 1);
      expect(cols.first.id, id);
      expect(cols.first.name, 'Flutter');
    });

    test('colección recién insertada tiene valores por defecto correctos', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'Trabajo'));
      final cols = await db.getAllCollections();
      expect(cols.first.color, '#6366F1');
      expect(cols.first.icon, 'folder');
      expect(cols.first.description, isNull);
    });

    test('insertar colección con todos los campos', () async {
      await db.insertCollection(CollectionsCompanion.insert(
        name: 'Dev',
        description: const Value('Links de desarrollo'),
        color: const Value('#FF5722'),
        icon: const Value('code'),
      ));
      final cols = await db.getAllCollections();
      expect(cols.first.name, 'Dev');
      expect(cols.first.description, 'Links de desarrollo');
      expect(cols.first.color, '#FF5722');
      expect(cols.first.icon, 'code');
    });

    test('actualizar colección', () async {
      final id = await db.insertCollection(
        CollectionsCompanion.insert(name: 'Original'),
      );
      await db.updateCollection(id, 'Actualizado', 'Nueva descripción', '#AABBCC', 'star');
      final cols = await db.getAllCollections();
      expect(cols.first.name, 'Actualizado');
      expect(cols.first.description, 'Nueva descripción');
      expect(cols.first.color, '#AABBCC');
      expect(cols.first.icon, 'star');
    });

    test('eliminar colección', () async {
      final id = await db.insertCollection(
        CollectionsCompanion.insert(name: 'Temporal'),
      );
      await db.deleteCollection(id);
      final cols = await db.getAllCollections();
      expect(cols, isEmpty);
    });

    test('eliminar colección no afecta otras colecciones', () async {
      final id1 = await db.insertCollection(CollectionsCompanion.insert(name: 'A'));
      final id2 = await db.insertCollection(CollectionsCompanion.insert(name: 'B'));
      await db.deleteCollection(id1);
      final cols = await db.getAllCollections();
      expect(cols.length, 1);
      expect(cols.first.id, id2);
    });
  });

  // ─── Collections — watchAllCollections ───────────────────────────────────────

  group('Collections — watchAllCollections', () {
    test('emite lista vacía inicialmente', () async {
      final stream = db.watchAllCollections();
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emite colecciones ordenadas por nombre', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'Zebra'));
      await db.insertCollection(CollectionsCompanion.insert(name: 'Alpha'));
      await db.insertCollection(CollectionsCompanion.insert(name: 'Medio'));
      final cols = await db.watchAllCollections().first;
      expect(cols.map((c) => c.name).toList(), ['Alpha', 'Medio', 'Zebra']);
    });

    test('emite actualización al insertar', () async {
      final stream = db.watchAllCollections();
      final first = await stream.first;
      expect(first, isEmpty);

      await db.insertCollection(CollectionsCompanion.insert(name: 'Nueva'));
      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.name, 'Nueva');
    });
  });

  // ─── Collections — collectionNameExists ──────────────────────────────────────

  group('Collections — collectionNameExists', () {
    test('retorna false cuando no existe ninguna colección', () async {
      final exists = await db.collectionNameExists('Trabajo');
      expect(exists, false);
    });

    test('retorna true cuando existe colección con mismo nombre', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'Trabajo'));
      final exists = await db.collectionNameExists('Trabajo');
      expect(exists, true);
    });

    test('comparación es case-insensitive', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'trabajo'));
      expect(await db.collectionNameExists('TRABAJO'), true);
      expect(await db.collectionNameExists('Trabajo'), true);
    });

    test('retorna false con excludeId del mismo registro', () async {
      final id = await db.insertCollection(
        CollectionsCompanion.insert(name: 'Trabajo'),
      );
      final exists = await db.collectionNameExists('Trabajo', excludeId: id);
      expect(exists, false);
    });

    test('retorna true cuando hay otro registro con el mismo nombre', () async {
      await db.insertCollection(CollectionsCompanion.insert(name: 'Trabajo'));
      final id2 = await db.insertCollection(
        CollectionsCompanion.insert(name: 'Personal'),
      );
      final exists = await db.collectionNameExists('Trabajo', excludeId: id2);
      expect(exists, true);
    });
  });

  // ─── LinkCollections — addLinkToCollection ────────────────────────────────────

  group('LinkCollections — addLinkToCollection', () {
    test('agregar link a colección', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      await db.addLinkToCollection(linkId, colId);
      final count = await db.countLinksInCollection(colId);
      expect(count, 1);
    });

    test('no duplica si se agrega el mismo link dos veces', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      await db.addLinkToCollection(linkId, colId);
      await db.addLinkToCollection(linkId, colId);
      final count = await db.countLinksInCollection(colId);
      expect(count, 1);
    });

    test('un link puede estar en múltiples colecciones', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final col1 = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final col2 = await db.insertCollection(CollectionsCompanion.insert(name: 'Flutter'));
      await db.addLinkToCollection(linkId, col1);
      await db.addLinkToCollection(linkId, col2);
      expect(await db.countLinksInCollection(col1), 1);
      expect(await db.countLinksInCollection(col2), 1);
    });
  });

  // ─── LinkCollections — removeLinkFromCollection ───────────────────────────────

  group('LinkCollections — removeLinkFromCollection', () {
    test('eliminar link de colección reduce el conteo', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      await db.addLinkToCollection(linkId, colId);
      await db.removeLinkFromCollection(linkId, colId);
      final count = await db.countLinksInCollection(colId);
      expect(count, 0);
    });

    test('eliminar link de colección no afecta el link en DB', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      await db.addLinkToCollection(linkId, colId);
      await db.removeLinkFromCollection(linkId, colId);
      final links = await db.getAllLinks();
      expect(links.length, 1);
    });

    test('eliminar link de una colección no afecta otras colecciones', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final col1 = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final col2 = await db.insertCollection(CollectionsCompanion.insert(name: 'Flutter'));
      await db.addLinkToCollection(linkId, col1);
      await db.addLinkToCollection(linkId, col2);
      await db.removeLinkFromCollection(linkId, col1);
      expect(await db.countLinksInCollection(col1), 0);
      expect(await db.countLinksInCollection(col2), 1);
    });
  });

  // ─── LinkCollections — watchLinksInCollection ─────────────────────────────────

  group('LinkCollections — watchLinksInCollection', () {
    test('emite lista vacía cuando colección no tiene links', () async {
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final links = await db.watchLinksInCollection(colId).first;
      expect(links, isEmpty);
    });

    test('emite links en la colección', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      await db.addLinkToCollection(linkId, colId);
      final links = await db.watchLinksInCollection(colId).first;
      expect(links.length, 1);
      expect(links.first.url, 'https://flutter.dev');
    });

    test('no retorna links de otras colecciones', () async {
      final link1 = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final link2 = await db.insertLink(LinksCompanion.insert(url: 'https://dart.dev'));
      final col1 = await db.insertCollection(CollectionsCompanion.insert(name: 'A'));
      final col2 = await db.insertCollection(CollectionsCompanion.insert(name: 'B'));
      await db.addLinkToCollection(link1, col1);
      await db.addLinkToCollection(link2, col2);
      final linksInCol1 = await db.watchLinksInCollection(col1).first;
      expect(linksInCol1.length, 1);
      expect(linksInCol1.first.url, 'https://flutter.dev');
    });

    test('emite actualización al agregar link', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final stream = db.watchLinksInCollection(colId);

      final before = await stream.first;
      expect(before, isEmpty);

      await db.addLinkToCollection(linkId, colId);
      final after = await stream.first;
      expect(after.length, 1);
    });
  });

  // ─── LinkCollections — countLinksInCollection ─────────────────────────────────

  group('LinkCollections — countLinksInCollection', () {
    test('retorna 0 cuando colección está vacía', () async {
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      expect(await db.countLinksInCollection(colId), 0);
    });

    test('retorna conteo correcto con múltiples links', () async {
      final col = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final l1 = await db.insertLink(LinksCompanion.insert(url: 'https://a.com'));
      final l2 = await db.insertLink(LinksCompanion.insert(url: 'https://b.com'));
      final l3 = await db.insertLink(LinksCompanion.insert(url: 'https://c.com'));
      await db.addLinkToCollection(l1, col);
      await db.addLinkToCollection(l2, col);
      await db.addLinkToCollection(l3, col);
      expect(await db.countLinksInCollection(col), 3);
    });
  });

  // ─── LinkCollections — getLastLinkAddedToCollection ──────────────────────────

  group('LinkCollections — getLastLinkAddedToCollection', () {
    test('retorna null cuando colección está vacía', () async {
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final last = await db.getLastLinkAddedToCollection(colId);
      expect(last, isNull);
    });

    test('retorna el último link agregado por fecha', () async {
      final col = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final l1 = await db.insertLink(LinksCompanion.insert(
        url: 'https://old.com',
        createdAt: Value(DateTime(2024, 1, 1)),
      ));
      final l2 = await db.insertLink(LinksCompanion.insert(
        url: 'https://new.com',
        createdAt: Value(DateTime(2025, 1, 1)),
      ));
      await db.addLinkToCollection(l1, col);
      await db.addLinkToCollection(l2, col);
      final last = await db.getLastLinkAddedToCollection(col);
      expect(last?.url, 'https://new.com');
    });
  });

  // ─── LinkCollections — watchCollectionsForLink ────────────────────────────────

  group('LinkCollections — watchCollectionsForLink', () {
    test('emite lista vacía cuando link no tiene colecciones', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final cols = await db.watchCollectionsForLink(linkId).first;
      expect(cols, isEmpty);
    });

    test('emite colecciones del link', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final col1 = await db.insertCollection(CollectionsCompanion.insert(name: 'Dev'));
      final col2 = await db.insertCollection(CollectionsCompanion.insert(name: 'Flutter'));
      await db.addLinkToCollection(linkId, col1);
      await db.addLinkToCollection(linkId, col2);
      final cols = await db.watchCollectionsForLink(linkId).first;
      expect(cols.length, 2);
      expect(cols.map((c) => c.name).toSet(), {'Dev', 'Flutter'});
    });

    test('no retorna colecciones de otros links', () async {
      final link1 = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final link2 = await db.insertLink(LinksCompanion.insert(url: 'https://dart.dev'));
      final col = await db.insertCollection(CollectionsCompanion.insert(name: 'Solo para link2'));
      await db.addLinkToCollection(link2, col);
      final cols = await db.watchCollectionsForLink(link1).first;
      expect(cols, isEmpty);
    });
  });
}
