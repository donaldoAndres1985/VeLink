import 'package:drift/drift.dart';
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

  // ─── LINKS — CRUD ────────────────────────────────────────────────────────────

  group('Links — CRUD', () {
    test('insertar un link y recuperarlo', () async {
      final id = await db.insertLink(
        LinksCompanion.insert(url: 'https://youtube.com/watch?v=abc'),
      );
      final links = await db.getAllLinks();
      expect(links.length, 1);
      expect(links.first.id, id);
      expect(links.first.url, 'https://youtube.com/watch?v=abc');
    });

    test('link recien insertado tiene valores por defecto correctos', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final links = await db.getAllLinks();
      expect(links.first.isFavorite, false);
      expect(links.first.priority, 0);
      expect(links.first.isRead, false);
      expect(links.first.platform, 'web');
    });

    test('insertar link con metadata completa', () async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://youtube.com/watch?v=xyz',
        title: const Value('Flutter Tutorial'),
        description: const Value('Aprende Flutter desde cero'),
        platform: const Value('youtube'),
        priority: const Value(1),
        isFavorite: const Value(true),
      ));
      final links = await db.getAllLinks();
      expect(links.first.title, 'Flutter Tutorial');
      expect(links.first.platform, 'youtube');
      expect(links.first.priority, 1);
      expect(links.first.isFavorite, true);
    });

    test('eliminar un link', () async {
      final id = await db.insertLink(
        LinksCompanion.insert(url: 'https://example.com'),
      );
      await db.deleteLink(id);
      final links = await db.getAllLinks();
      expect(links, isEmpty);
    });

    test('actualizar un link', () async {
      final id = await db.insertLink(
        LinksCompanion.insert(url: 'https://example.com'),
      );
      final links = await db.getAllLinks();
      final link = links.first;
      await db.updateLink(link.toCompanion(true).copyWith(
        isFavorite: const Value(true),
      ));
      final updated = await db.getAllLinks();
      expect(updated.first.isFavorite, true);
    });
  });

  // ─── LINKS — BUSQUEDA ────────────────────────────────────────────────────────

  group('Links — Busqueda', () {
    setUp(() async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://flutter.dev',
        title: const Value('Flutter Documentation'),
        platform: const Value('web'),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://dart.dev',
        title: const Value('Dart Language'),
        description: const Value('Lenguaje de programacion de Google'),
        platform: const Value('web'),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://youtube.com/watch?v=abc',
        title: const Value('Tutorial Flutter Avanzado'),
        platform: const Value('youtube'),
      ));
    });

    test('buscar por titulo retorna resultados correctos', () async {
      final results = await db.searchLinks('flutter');
      expect(results.length, 2);
    });

    test('buscar por plataforma retorna resultados correctos', () async {
      final results = await db.searchLinks('youtube');
      expect(results.length, 1);
      expect(results.first.platform, 'youtube');
    });

    test('buscar por descripcion retorna resultados correctos', () async {
      final results = await db.searchLinks('Google');
      expect(results.length, 1);
    });

    test('busqueda sin resultados retorna lista vacia', () async {
      final results = await db.searchLinks('kotlin');
      expect(results, isEmpty);
    });

    test('busqueda es case-insensitive', () async {
      final results = await db.searchLinks('FLUTTER');
      expect(results.length, 2);
    });
  });

  // ─── LINKS — FILTROS ─────────────────────────────────────────────────────────

  group('Links — Filtros', () {
    test('watchPriorityLinks solo retorna links con priority=1', () async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://importante.com',
        priority: const Value(1),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://normal.com',
        priority: const Value(0),
      ));
      final priorityLinks = await db.watchPriorityLinks().first;
      expect(priorityLinks.length, 1);
      expect(priorityLinks.first.url, 'https://importante.com');
    });

    test('watchFavoriteLinks solo retorna favoritos', () async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://favorito.com',
        isFavorite: const Value(true),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://normal.com',
      ));
      final favorites = await db.watchFavoriteLinks().first;
      expect(favorites.length, 1);
      expect(favorites.first.url, 'https://favorito.com');
    });

    test('watchAllLinks retorna todos ordenados por fecha descendente', () async {
      final now = DateTime.now();
      await db.insertLink(LinksCompanion(
        url: const Value('https://primero.com'),
        createdAt: Value(now.subtract(const Duration(seconds: 1))),
      ));
      await db.insertLink(LinksCompanion(
        url: const Value('https://segundo.com'),
        createdAt: Value(now),
      ));
      final all = await db.watchAllLinks().first;
      expect(all.length, 2);
      expect(all.first.url, 'https://segundo.com');
    });
  });

  // ─── TAGS ────────────────────────────────────────────────────────────────────

  group('Tags', () {
    test('insertar y recuperar un tag', () async {
      await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final tags = await db.watchAllTags().first;
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });

    test('tag tiene color por defecto', () async {
      await db.insertTag(TagsCompanion.insert(name: 'dart'));
      final tags = await db.watchAllTags().first;
      expect(tags.first.color, '#6366F1');
    });

    test('no crea tags duplicados (upsert)', () async {
      await db.insertTag(TagsCompanion.insert(name: 'dart'));
      await db.insertTag(TagsCompanion.insert(name: 'dart'));
      final tags = await db.watchAllTags().first;
      expect(tags.length, 1);
    });

    test('insertar tag con color personalizado', () async {
      await db.insertTag(TagsCompanion.insert(
        name: 'urgente',
        color: const Value('#FF0000'),
      ));
      final tags = await db.watchAllTags().first;
      expect(tags.first.color, '#FF0000');
    });
  });

  // ─── LINK TAGS — RELACION N:N ─────────────────────────────────────────────────

  group('LinkTags — Relacion N:N', () {
    late int linkId;
    late int tagFlutter;
    late int tagDart;

    setUp(() async {
      linkId = await db.insertLink(
        LinksCompanion.insert(url: 'https://example.com'),
      );
      tagFlutter = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      tagDart = await db.insertTag(TagsCompanion.insert(name: 'dart'));
    });

    test('agregar tag a un link', () async {
      await db.addTagToLink(linkId, tagFlutter);
      final tags = await db.getTagsForLink(linkId);
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });

    test('un link puede tener multiples tags', () async {
      await db.addTagToLink(linkId, tagFlutter);
      await db.addTagToLink(linkId, tagDart);
      final tags = await db.getTagsForLink(linkId);
      expect(tags.length, 2);
    });

    test('remover tag de un link', () async {
      await db.addTagToLink(linkId, tagFlutter);
      await db.removeTagFromLink(linkId, tagFlutter);
      final tags = await db.getTagsForLink(linkId);
      expect(tags, isEmpty);
    });

    test('no duplica relacion link-tag (upsert)', () async {
      await db.addTagToLink(linkId, tagFlutter);
      await db.addTagToLink(linkId, tagFlutter);
      final tags = await db.getTagsForLink(linkId);
      expect(tags.length, 1);
    });

    test('link sin tags retorna lista vacia', () async {
      final tags = await db.getTagsForLink(linkId);
      expect(tags, isEmpty);
    });
  });
}
