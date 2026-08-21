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

  group('Links — setLinkPreviewImagePath', () {
    test('guarda la ruta local de la imagen cacheada', () async {
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.setLinkPreviewImagePath(id, '/data/link_previews/123.jpg');
      final links = await db.getAllLinks();
      expect(links.first.previewImagePath, '/data/link_previews/123.jpg');
    });

    test('no afecta otros campos del link', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        title: const Value('Mi título'),
        previewImageUrl: const Value('https://cdn.com/img.jpg'),
      ));
      await db.setLinkPreviewImagePath(id, '/data/link_previews/123.jpg');
      final link = (await db.getAllLinks()).first;
      expect(link.title, 'Mi título');
      expect(link.previewImageUrl, 'https://cdn.com/img.jpg');
    });

    test('no afecta otros links', () async {
      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://uno.com'));
      await db.insertLink(LinksCompanion.insert(url: 'https://dos.com'));
      await db.setLinkPreviewImagePath(id1, '/data/link_previews/uno.jpg');
      final links = await db.getAllLinks();
      final uno = links.firstWhere((l) => l.url == 'https://uno.com');
      final dos = links.firstWhere((l) => l.url == 'https://dos.com');
      expect(uno.previewImagePath, '/data/link_previews/uno.jpg');
      expect(dos.previewImagePath, null);
    });
  });

  group('Links — setLinkPreviewImageUrl', () {
    test('actualiza la URL remota de la imagen de preview', () async {
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        previewImageUrl: const Value('https://cdn.com/vencida.jpg'),
      ));
      await db.setLinkPreviewImageUrl(id, 'https://cdn.com/nueva.jpg');
      final links = await db.getAllLinks();
      expect(links.first.previewImageUrl, 'https://cdn.com/nueva.jpg');
    });

    test('no afecta otros campos ni otros links', () async {
      final id1 = await db.insertLink(LinksCompanion.insert(
        url: 'https://uno.com',
        title: const Value('Mi título'),
      ));
      await db.insertLink(LinksCompanion.insert(url: 'https://dos.com'));
      await db.setLinkPreviewImageUrl(id1, 'https://cdn.com/nueva.jpg');
      final links = await db.getAllLinks();
      final uno = links.firstWhere((l) => l.url == 'https://uno.com');
      final dos = links.firstWhere((l) => l.url == 'https://dos.com');
      expect(uno.title, 'Mi título');
      expect(uno.previewImageUrl, 'https://cdn.com/nueva.jpg');
      expect(dos.previewImageUrl, null);
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

  // ─── TAGS — ACTUALIZAR ───────────────────────────────────────────────────────

  group('Tags — updateTag', () {
    test('updateTag actualiza el nombre del tag', () async {
      final id = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.updateTag(id, 'flutter-nuevo', '#6366F1');
      final tags = await db.watchAllTags().first;
      expect(tags.first.name, 'flutter-nuevo');
    });

    test('updateTag actualiza el color del tag', () async {
      final id = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.updateTag(id, 'flutter', '#EF4444');
      final tags = await db.watchAllTags().first;
      expect(tags.first.color, '#EF4444');
    });

    test('updateTag no afecta otros tags', () async {
      final id1 = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.insertTag(TagsCompanion.insert(name: 'dart'));
      await db.updateTag(id1, 'flutter-nuevo', '#6366F1');
      final tags = await db.watchAllTags().first;
      expect(tags.where((t) => t.name == 'dart').length, 1);
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

  // ─── DELETE ALL DATA ─────────────────────────────────────────────────────────

  group('deleteAllData', () {
    test('elimina links, tags y colecciones', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      await db.insertTag(TagsCompanion.insert(name: 'mi tag'));
      await db.insertCollection(CollectionsCompanion(
        name: const Value('mi colección'),
        color: const Value('#6366F1'),
        icon: const Value('folder'),
      ));

      await db.deleteAllData();

      expect(await db.getAllLinks(), isEmpty);
      expect(await db.watchAllTags().first, isEmpty);
      expect(await db.getAllCollections(), isEmpty);
    });

    test('deleteAllData en DB vacía no lanza error', () async {
      await db.deleteAllData();
      expect(await db.getAllLinks(), isEmpty);
    });
  });

  // ─── LINKS — watchForgottenLinks ─────────────────────────────────────────────

  group('Links — watchForgottenLinks', () {
    test('retorna links no revisados guardados hace más de 7 días', () async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      await db.insertLink(LinksCompanion(
        url: const Value('https://old.com'),
        isRead: const Value(false),
        createdAt: Value(old),
      ));
      final forgotten = await db.watchForgottenLinks().first;
      expect(forgotten.length, 1);
      expect(forgotten.first.url, 'https://old.com');
    });

    test('no retorna links revisados aunque sean antiguos', () async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      await db.insertLink(LinksCompanion(
        url: const Value('https://reviewed.com'),
        isRead: const Value(true),
        createdAt: Value(old),
      ));
      final forgotten = await db.watchForgottenLinks().first;
      expect(forgotten, isEmpty);
    });

    test('no retorna links guardados recientemente', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://recent.com'));
      final forgotten = await db.watchForgottenLinks().first;
      expect(forgotten, isEmpty);
    });

    test('respeta el límite de resultados', () async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      for (var i = 0; i < 10; i++) {
        await db.insertLink(LinksCompanion(
          url: Value('https://old-$i.com'),
          isRead: const Value(false),
          createdAt: Value(old.subtract(Duration(seconds: i))),
        ));
      }
      final forgotten = await db.watchForgottenLinks(limit: 5).first;
      expect(forgotten.length, 5);
    });
  });

  // ─── LINKS — getLinkStats ─────────────────────────────────────────────────────

  group('Links — getLinkStats', () {
    test('retorna total correcto', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://a.com'));
      await db.insertLink(LinksCompanion.insert(url: 'https://b.com'));
      final stats = await db.getLinkStats();
      expect(stats.total, 2);
    });

    test('retorna pendientes y revisados correctos', () async {
      await db.insertLink(LinksCompanion.insert(url: 'https://pending.com'));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://reviewed.com',
        isRead: const Value(true),
      ));
      final stats = await db.getLinkStats();
      expect(stats.pending, 1);
      expect(stats.reviewed, 1);
    });

    test('retorna favoritos correctos', () async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://fav.com',
        isFavorite: const Value(true),
      ));
      await db.insertLink(LinksCompanion.insert(url: 'https://normal.com'));
      final stats = await db.getLinkStats();
      expect(stats.favorites, 1);
    });

    test('retorna 0 cuando no hay links', () async {
      final stats = await db.getLinkStats();
      expect(stats.total, 0);
      expect(stats.pending, 0);
      expect(stats.reviewed, 0);
      expect(stats.favorites, 0);
      expect(stats.topPlatform, isNull);
    });

    test('retorna la plataforma más frecuente', () async {
      await db.insertLink(LinksCompanion(
        url: const Value('https://y1.com'),
        platform: const Value('youtube'),
      ));
      await db.insertLink(LinksCompanion(
        url: const Value('https://y2.com'),
        platform: const Value('youtube'),
      ));
      await db.insertLink(LinksCompanion(
        url: const Value('https://w1.com'),
        platform: const Value('web'),
      ));
      final stats = await db.getLinkStats();
      expect(stats.topPlatform, 'youtube');
    });
  });

  group('Links — getLinksPerDay', () {
    test('devuelve N entradas para los últimos N días', () async {
      final result = await db.getLinksPerDay(days: 7);
      expect(result.length, 7);
    });

    test('cuenta correctamente los links del día actual', () async {
      await db.insertLink(const LinksCompanion(url: Value('https://a.com')));
      await db.insertLink(const LinksCompanion(url: Value('https://b.com')));
      final result = await db.getLinksPerDay(days: 7);
      expect(result.last.count, 2);
    });

    test('excluye links fuera del período', () async {
      final old = DateTime.now().subtract(const Duration(days: 30));
      await db.insertLink(LinksCompanion(url: const Value('https://old.com'), createdAt: Value(old)));
      final result = await db.getLinksPerDay(days: 7);
      expect(result.every((d) => d.count == 0), isTrue);
    });

    test('devuelve 30 entradas cuando se pide mes', () async {
      final result = await db.getLinksPerDay(days: 30);
      expect(result.length, 30);
    });
  });

  group('Links — getPlatformBreakdown', () {
    test('devuelve lista vacía cuando no hay links', () async {
      final result = await db.getPlatformBreakdown();
      expect(result, isEmpty);
    });

    test('cuenta links por plataforma correctamente', () async {
      await db.insertLink(const LinksCompanion(url: Value('https://a.com'), platform: Value('youtube')));
      await db.insertLink(const LinksCompanion(url: Value('https://b.com'), platform: Value('youtube')));
      await db.insertLink(const LinksCompanion(url: Value('https://c.com'), platform: Value('twitter')));
      final result = await db.getPlatformBreakdown();
      final youtube = result.firstWhere((p) => p.platform == 'youtube');
      expect(youtube.count, 2);
    });

    test('ordena por frecuencia descendente', () async {
      await db.insertLink(const LinksCompanion(url: Value('https://a.com'), platform: Value('twitter')));
      await db.insertLink(const LinksCompanion(url: Value('https://b.com'), platform: Value('youtube')));
      await db.insertLink(const LinksCompanion(url: Value('https://c.com'), platform: Value('youtube')));
      final result = await db.getPlatformBreakdown();
      expect(result.first.platform, 'youtube');
    });
  });

  group('Links — getLinksForYear', () {
    test('devuelve 364 entradas', () async {
      final result = await db.getLinksForYear();
      expect(result.length, 364);
    });

    test('el último día refleja links guardados hoy', () async {
      await db.insertLink(const LinksCompanion(url: Value('https://today.com')));
      final result = await db.getLinksForYear();
      expect(result.last.count, 1);
    });
  });

  group('Links — getLinkStats — uniquePlatforms', () {
    test('retorna 0 cuando no hay links', () async {
      final stats = await db.getLinkStats();
      expect(stats.uniquePlatforms, 0);
    });

    test('cuenta plataformas únicas correctamente', () async {
      await db.insertLink(const LinksCompanion(
        url: Value('https://a.com'), platform: Value('youtube'),
      ));
      await db.insertLink(const LinksCompanion(
        url: Value('https://b.com'), platform: Value('youtube'),
      ));
      await db.insertLink(const LinksCompanion(
        url: Value('https://c.com'), platform: Value('twitter'),
      ));
      final stats = await db.getLinkStats();
      expect(stats.uniquePlatforms, 2);
    });

    test('una sola plataforma cuenta como 1', () async {
      await db.insertLink(const LinksCompanion(
        url: Value('https://a.com'), platform: Value('web'),
      ));
      final stats = await db.getLinkStats();
      expect(stats.uniquePlatforms, 1);
    });
  });

  // ─── restoreLink ─────────────────────────────────────────────────────────────

  group('Links — restoreLink', () {
    test('restaura un link borrado con sus datos originales', () async {
      await db.insertLink(const LinksCompanion(
        url: Value('https://example.com'),
        title: Value('Mi Link'),
        platform: Value('web'),
        isFavorite: Value(true),
      ));
      final link = (await db.getAllLinks()).first;

      await db.deleteLink(link.id);
      expect(await db.getAllLinks(), isEmpty);

      await db.restoreLink(link);

      final all = await db.getAllLinks();
      expect(all.length, 1);
      expect(all.first.url, 'https://example.com');
      expect(all.first.title, 'Mi Link');
      expect(all.first.isFavorite, isTrue);
    });

    test('restaura el link con las etiquetas originales', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://a.com'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.addTagToLink(linkId, tagId);

      final link = (await db.getAllLinks()).first;
      final tags = await db.getTagsForLink(link.id);

      await db.deleteLink(link.id);

      final newId = await db.restoreLink(link, tags: tags);
      final restoredTags = await db.getTagsForLink(newId);

      expect(restoredTags.map((t) => t.name), contains('flutter'));
    });

    test('restaura el link con sus colecciones originales', () async {
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://b.com'));
      final colId = await db.insertCollection(CollectionsCompanion.insert(name: 'Favoritos'));
      await db.addLinkToCollection(linkId, colId);

      final link = (await db.getAllLinks()).first;
      final cols = await db.getCollectionsForLink(link.id);

      await db.deleteLink(link.id);

      final newId = await db.restoreLink(link, collections: cols);
      final restoredCols = await db.getCollectionsForLink(newId);

      expect(restoredCols.map((c) => c.name), contains('Favoritos'));
    });
  });
}
