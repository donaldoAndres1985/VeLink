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

  // ─── LINKS — getLinkByUrl ────────────────────────────────────────────────────

  group('Links — getLinkByUrl', () {
    test('retorna null si la URL no existe', () async {
      final link = await db.getLinkByUrl('https://example.com');
      expect(link, isNull);
    });

    test('retorna el link si la URL existe', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final link = await db.getLinkByUrl('https://flutter.dev');
      expect(link, isNotNull);
      expect(link!.url, 'https://flutter.dev');
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

    test('watchPendingLinks retorna links con isRead=false', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://pendiente.com'));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://revisado.com',
        isRead: const Value(true),
      ));
      final pending = await db.watchPendingLinks().first;
      expect(pending.length, 1);
      expect(pending.first.url, 'https://pendiente.com');
    });

    test('setLinkReviewed marca el link como revisado', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.setLinkReviewed(id, true);
      final link = await db.getLinkByUrl('https://example.com');
      expect(link?.isRead, true);
    });

    test('setLinkReviewed puede desmarcar un link revisado', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        isRead: const Value(true),
      ));
      await db.setLinkReviewed(id, false);
      final link = await db.getLinkByUrl('https://example.com');
      expect(link?.isRead, false);
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

  // ─── LINKS — FILTRADO POR TAG ─────────────────────────────────────────────────

  group('Links — filtrado por tag', () {
    test('watchLinksByTag retorna solo los links con ese tag', () async {
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      await db.insertLink(LinksCompanion.insert(url: 'https://dart.dev'));
      await db.addTagToLink(id1, tagId);

      final links = await db.watchLinksByTag(tagId).first;
      expect(links.length, 1);
      expect(links.first.url, 'https://flutter.dev');
    });

    test('watchLinksByTag retorna lista vacía si ningún link tiene ese tag', () async {
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      final links = await db.watchLinksByTag(tagId).first;
      expect(links, isEmpty);
    });

    test('watchLinksByTag retorna links del tag en orden descendente por fecha', () async {
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final now = DateTime.now();
      final id1 = await db.insertLink(LinksCompanion(
        url: const Value('https://flutter.dev'),
        createdAt: Value(now.subtract(const Duration(hours: 2))),
      ));
      final id2 = await db.insertLink(LinksCompanion(
        url: const Value('https://pub.dev'),
        createdAt: Value(now.subtract(const Duration(hours: 1))),
      ));
      await db.addTagToLink(id1, tagId);
      await db.addTagToLink(id2, tagId);

      final links = await db.watchLinksByTag(tagId).first;
      expect(links.first.url, 'https://pub.dev');
      expect(links.last.url, 'https://flutter.dev');
    });
  });

  // ─── LINKS — PRIORIDAD ────────────────────────────────────────────────────────

  group('Links — setLinkPriority', () {
    test('setLinkPriority establece priority=1 en el link', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.setLinkPriority(id, 1);
      final links = await db.getAllLinks();
      expect(links.first.priority, 1);
    });

    test('setLinkPriority establece priority=0 para quitar prioridad', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        priority: const Value(1),
      ));
      await db.setLinkPriority(id, 0);
      final links = await db.getAllLinks();
      expect(links.first.priority, 0);
    });

    test('setLinkPriority no afecta otros links', () async {
      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://uno.com'));
      await db.insertLink(LinksCompanion.insert(url: 'https://dos.com'));
      await db.setLinkPriority(id1, 1);
      final links = await db.getAllLinks();
      final uno = links.firstWhere((l) => l.url == 'https://uno.com');
      final dos = links.firstWhere((l) => l.url == 'https://dos.com');
      expect(uno.priority, 1);
      expect(dos.priority, 0);
    });
  });

  // ─── LINKS — NOTAS ────────────────────────────────────────────────────────────

  group('Links — updateLinkNotes', () {
    test('updateLinkNotes guarda texto en el campo notes', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.updateLinkNotes(id, 'Mi nota personal');
      final links = await db.getAllLinks();
      expect(links.first.notes, 'Mi nota personal');
    });

    test('updateLinkNotes acepta null para borrar la nota', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.updateLinkNotes(id, 'Nota previa');
      await db.updateLinkNotes(id, null);
      final links = await db.getAllLinks();
      expect(links.first.notes, null);
    });

  // ─── LINKS — updateLinkTitle ──────────────────────────────────────────────────

  group('Links — updateLinkTitle', () {
    test('actualiza el título del link', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        title: const Value('Título viejo'),
      ));
      await db.updateLinkTitle(id, 'Título nuevo');
      final links = await db.getAllLinks();
      expect(links.first.title, 'Título nuevo');
    });

    test('acepta null para borrar el título', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        title: const Value('Título'),
      ));
      await db.updateLinkTitle(id, null);
      final links = await db.getAllLinks();
      expect(links.first.title, null);
    });

    test('no afecta otros campos del link', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        notes: const Value('Nota existente'),
      ));
      await db.updateLinkTitle(id, 'Nuevo título');
      final links = await db.getAllLinks();
      expect(links.first.notes, 'Nota existente');
    });
  });

    test('updateLinkNotes no afecta otros campos del link', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        title: const Value('Mi título'),
      ));
      await db.updateLinkNotes(id, 'Nota');
      final links = await db.getAllLinks();
      expect(links.first.title, 'Mi título');
      expect(links.first.notes, 'Nota');
    });
  });

  // ─── TAGS DEL LINK — STREAM ──────────────────────────────────────────────────

  group('Links — watchTagsForLink', () {
    test('retorna stream con tags del link', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.addTagToLink(linkId, tagId);

      final tags = await db.watchTagsForLink(linkId).first;
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });

    test('retorna stream vacío cuando el link no tiene tags', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final tags = await db.watchTagsForLink(linkId).first;
      expect(tags, isEmpty);
    });

    test('se actualiza al agregar un tag al link', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'dart'));

      final stream = db.watchTagsForLink(linkId);
      await db.addTagToLink(linkId, tagId);

      final tags = await stream.first;
      expect(tags.length, 1);
    });
  });

  // ─── LINKS — RECORDATORIO ────────────────────────────────────────────────────

  group('Links — setLinkReminder', () {
    test('setLinkReminder guarda la fecha en remindAt', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final when = DateTime(2026, 6, 1, 10, 0);
      await db.setLinkReminder(id, when);
      final links = await db.getAllLinks();
      expect(links.first.remindAt, when);
    });

    test('setLinkReminder acepta null para borrar el recordatorio', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final when = DateTime(2026, 6, 1, 10, 0);
      await db.setLinkReminder(id, when);
      await db.setLinkReminder(id, null);
      final links = await db.getAllLinks();
      expect(links.first.remindAt, null);
    });

    test('setLinkReminder no afecta otros links', () async {
      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://uno.com'));
      await db.insertLink(LinksCompanion.insert(url: 'https://dos.com'));
      final when = DateTime(2026, 6, 1, 10, 0);
      await db.setLinkReminder(id1, when);
      final links = await db.getAllLinks();
      final uno = links.firstWhere((l) => l.url == 'https://uno.com');
      final dos = links.firstWhere((l) => l.url == 'https://dos.com');
      expect(uno.remindAt, when);
      expect(dos.remindAt, null);
    });
  });

  // ─── TAGS — GET ALL ──────────────────────────────────────────────────────────

  group('Tags — getAllTags', () {
    test('retorna lista vacía cuando no hay tags', () async {
      final tags = await db.getAllTags();
      expect(tags, isEmpty);
    });

    test('retorna todos los tags insertados', () async {
      await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.insertTag(TagsCompanion.insert(name: 'dart'));
      final tags = await db.getAllTags();
      expect(tags.length, 2);
    });
  });

  // ─── LINKS — FAVORITO ────────────────────────────────────────────────────────

  group('Links — setLinkFavorite', () {
    test('setLinkFavorite marca el link como favorito', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.setLinkFavorite(id, true);
      final links = await db.getAllLinks();
      expect(links.first.isFavorite, true);
    });

    test('setLinkFavorite desmarca el link como favorito', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        isFavorite: const Value(true),
      ));
      await db.setLinkFavorite(id, false);
      final links = await db.getAllLinks();
      expect(links.first.isFavorite, false);
    });

    test('setLinkFavorite no afecta otros links', () async {
      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://uno.com'));
      await db.insertLink(LinksCompanion.insert(url: 'https://dos.com'));
      await db.setLinkFavorite(id1, true);
      final links = await db.getAllLinks();
      final uno = links.firstWhere((l) => l.url == 'https://uno.com');
      final dos = links.firstWhere((l) => l.url == 'https://dos.com');
      expect(uno.isFavorite, true);
      expect(dos.isFavorite, false);
    });
  });

  // ─── TAGS — ELIMINAR ─────────────────────────────────────────────────────────

  group('Tags — deleteTag', () {
    test('deleteTag elimina el tag de la base de datos', () async {
      final id = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.deleteTag(id);
      final tags = await db.watchAllTags().first;
      expect(tags, isEmpty);
    });

    test('deleteTag no afecta otros tags', () async {
      final id1 = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.insertTag(TagsCompanion.insert(name: 'dart'));
      await db.deleteTag(id1);
      final tags = await db.watchAllTags().first;
      expect(tags.length, 1);
      expect(tags.first.name, 'dart');
    });
  });

  // ─── LINKS — watchLinksByPlatform ───────────────────────────────────────────

  group('Links — watchLinksByPlatform', () {
    test('retorna links de la plataforma especificada', () async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://facebook.com/post',
        platform: const Value('facebook'),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://youtube.com/watch?v=abc',
        platform: const Value('youtube'),
      ));
      final fbLinks = await db.watchLinksByPlatform('facebook').first;
      expect(fbLinks.length, 1);
      expect(fbLinks.first.platform, 'facebook');
    });

    test('retorna lista vacía si no hay links de esa plataforma', () async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://youtube.com/watch?v=abc',
        platform: const Value('youtube'),
      ));
      final fbLinks = await db.watchLinksByPlatform('facebook').first;
      expect(fbLinks, isEmpty);
    });
  });

  // ─── TAGS — countLinksForTag ─────────────────────────────────────────────────

  group('Tags — countLinksForTag', () {
    test('retorna 0 cuando el tag no tiene links', () async {
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final count = await db.countLinksForTag(tagId);
      expect(count, 0);
    });

    test('retorna el número correcto de links por tag', () async {
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final id2 = await db.insertLink(LinksCompanion.insert(url: 'https://pub.dev'));
      await db.addTagToLink(id1, tagId);
      await db.addTagToLink(id2, tagId);
      final count = await db.countLinksForTag(tagId);
      expect(count, 2);
    });
  });
}
