import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/backup/services/backup_service.dart';
import 'package:velink/features/capture/models/og_metadata.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/mock_image_cache_service.dart';
import '../../helpers/mock_metadata_service.dart';

// ── Fake prefs ────────────────────────────────────────────────────────────────
class _FakePrefs implements PreferencesService {
  @override Locale getLocale() => const Locale('es');
  @override Future<void> setLocale(Locale l) async {}
  @override bool getNotificationsEnabled() => true;
  @override Future<void> setNotificationsEnabled(bool v) async {}
  @override ThemeMode getThemeMode() => ThemeMode.light;
  @override Future<void> setThemeMode(ThemeMode m) async {}
  @override int getStreak() => 0;
  @override Future<void> setStreak(int c) async {}
  @override String? getStreakLastDate() => null;
  @override Future<void> setStreakLastDate(String d) async {}
  @override bool isPremium() => false;
  @override Future<void> setPremium(bool v) async {}
}

BackupService makeService(
  AppDatabase db, {
  MockImageCacheService? imageCache,
  MockMetadataService? metadataService,
}) =>
    BackupService(db, _FakePrefs(), imageCache, metadataService);

void main() {
  group('BackupService — exportación (buildBackupData)', () {
    test('incluye version y exportedAt', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final data = await makeService(db).buildBackupData();
      expect(data['version'], isNotNull);
      expect(data['exportedAt'], isNotNull);
    });

    test('incluye settings con language y notificationsEnabled', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final data = await makeService(db).buildBackupData();
      final settings = data['settings'] as Map<String, dynamic>;
      expect(settings['language'], 'es');
      expect(settings['notificationsEnabled'], true);
    });

    test('link exportado incluye previewImagePath', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        previewImagePath: const Value('/storage/img.jpg'),
      ));
      final data = await makeService(db).buildBackupData();
      final link = (data['links'] as List).first as Map<String, dynamic>;
      expect(link['previewImagePath'], '/storage/img.jpg');
    });

    test('link exportado incluye faviconUrl', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        faviconUrl: const Value('https://example.com/favicon.ico'),
      ));
      final data = await makeService(db).buildBackupData();
      final link = (data['links'] as List).first as Map<String, dynamic>;
      expect(link['faviconUrl'], 'https://example.com/favicon.ico');
    });

    test('link exportado incluye displayUrl sin scheme ni www', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://www.example.com/path'));
      final data = await makeService(db).buildBackupData();
      final link = (data['links'] as List).first as Map<String, dynamic>;
      expect(link['displayUrl'], 'example.com/path');
    });

    test('tag exportado incluye color', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertTag(TagsCompanion(
        name: const Value('Flutter'),
        color: const Value('#FF5722'),
      ));
      final data = await makeService(db).buildBackupData();
      final tag = (data['tags'] as List).first as Map<String, dynamic>;
      expect(tag['color'], '#FF5722');
    });
  });

  group('BackupService — importación merge', () {
    test('restaura color de tag al importar', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': <Map<String, dynamic>>[],
        'tags': [
          {'id': 1, 'name': 'Dart', 'color': '#03A9F4', 'createdAt': DateTime.now().toIso8601String()},
        ],
        'collections': <Map<String, dynamic>>[],
      };
      await makeService(db).importFromBackupData(backup);
      final tags = await db.getAllTags();
      expect(tags.first.color, '#03A9F4');
    });

    test('salta links duplicados por URL', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://existing.com'));
      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': [
          {'id': 1, 'url': 'https://existing.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
          {'id': 2, 'url': 'https://new.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
        ],
        'tags': <Map<String, dynamic>>[],
        'collections': <Map<String, dynamic>>[],
      };
      final result = await makeService(db).importFromBackupData(backup);
      expect(result.imported, 1);
      expect(result.skipped, 1);
    });
  });

  group('BackupService — importación replace', () {
    test('en modo replace borra todos los datos antes de importar', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://old.com'));
      await db.insertTag(TagsCompanion(name: const Value('OldTag')));

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': [
          {'id': 1, 'url': 'https://new.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
        ],
        'tags': <Map<String, dynamic>>[],
        'collections': <Map<String, dynamic>>[],
      };
      await makeService(db).importFromBackupData(backup, replace: true);

      final links = await db.getAllLinks();
      final tags = await db.getAllTags();
      expect(links.length, 1);
      expect(links.first.url, 'https://new.com');
      expect(tags, isEmpty);
    });

    test('en modo replace importa todos los links sin contar duplicados eliminados', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://existing.com'));

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': [
          {'id': 1, 'url': 'https://existing.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
          {'id': 2, 'url': 'https://another.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
        ],
        'tags': <Map<String, dynamic>>[],
        'collections': <Map<String, dynamic>>[],
      };
      final result = await makeService(db).importFromBackupData(backup, replace: true);
      expect(result.imported, 2);
      expect(result.skipped, 0);
    });
  });

  group('BackupService — importación atómica (bug: importación parcial)', () {
    test('si un registro falla a mitad de camino, no deja links huérfanos importados', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': [
          {'id': 1, 'url': 'https://ok-1.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
          {'id': 2, 'url': 'https://ok-2.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
          // Registro corrupto: 'url' ausente/null hace explotar el cast a mitad del loop.
          {'id': 3, 'url': null, 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
        ],
        'tags': <Map<String, dynamic>>[],
        'collections': <Map<String, dynamic>>[],
      };

      await expectLater(
        makeService(db).importFromBackupData(backup),
        throwsA(anything),
      );

      // Antes del fix: ok-1 y ok-2 quedaban insertados aunque el import
      // completo falló, dejando datos parciales sin avisar al usuario.
      final links = await db.getAllLinks();
      expect(links, isEmpty);
    });

    test('en modo replace, si falla a mitad de camino no deja la base vacía', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://old.com'));

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': [
          {'id': 1, 'url': 'https://new.com', 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
          {'id': 2, 'url': null, 'platform': 'web', 'isFavorite': false, 'isRead': false, 'priority': 0},
        ],
        'tags': <Map<String, dynamic>>[],
        'collections': <Map<String, dynamic>>[],
      };

      await expectLater(
        makeService(db).importFromBackupData(backup, replace: true),
        throwsA(anything),
      );

      // Antes del fix: deleteAllData() ya se había ejecutado y el fallo
      // posterior dejaba al usuario con la base de datos completamente vacía.
      final links = await db.getAllLinks();
      expect(links.map((l) => l.url), contains('https://old.com'));
    });
  });

  group('BackupService — importación preserva fechas originales', () {
    test('createdAt y updatedAt del backup se preservan, no se resetean a "ahora"', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final originalCreatedAt = DateTime.utc(2026, 5, 13, 21, 59, 42);
      final originalUpdatedAt = DateTime.utc(2026, 5, 14, 8, 0, 0);

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'links': [
          {
            'id': 1,
            'url': 'https://old-link.com',
            'platform': 'web',
            'isFavorite': false,
            'isRead': false,
            'priority': 0,
            'createdAt': originalCreatedAt.toIso8601String(),
            'updatedAt': originalUpdatedAt.toIso8601String(),
          },
        ],
        'tags': <Map<String, dynamic>>[],
        'collections': <Map<String, dynamic>>[],
      };

      await makeService(db).importFromBackupData(backup);
      final link = (await db.getAllLinks()).first;
      expect(link.createdAt.toUtc(), originalCreatedAt);
      expect(link.updatedAt.toUtc(), originalUpdatedAt);
    });
  });

  group('BackupService — cacheMissingPreviewImages (bug: previews rotas tras importar)', () {
    test('descarga y guarda localmente la imagen de links con URL pero sin ruta local', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://a.com',
        previewImageUrl: const Value('https://cdn.com/a.jpg'),
      ));
      final imageCache = MockImageCacheService(
        resultsByUrl: {'https://cdn.com/a.jpg': '/data/link_previews/a.jpg'},
      );

      await makeService(
        db,
        imageCache: imageCache,
        metadataService: MockMetadataService(),
      ).cacheMissingPreviewImages();

      final link = (await db.getAllLinks()).first;
      expect(link.previewImagePath, '/data/link_previews/a.jpg');
    });

    test('no toca links que ya tienen previewImagePath', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://a.com',
        previewImageUrl: const Value('https://cdn.com/a.jpg'),
        previewImagePath: const Value('/ya/existe.jpg'),
      ));
      final imageCache = MockImageCacheService(result: '/otra/ruta.jpg');

      await makeService(
        db,
        imageCache: imageCache,
        metadataService: MockMetadataService(),
      ).cacheMissingPreviewImages();

      expect(imageCache.callCount, 0);
      final link = (await db.getAllLinks()).first;
      expect(link.previewImagePath, '/ya/existe.jpg');
    });

    test('un fallo en un link (URL vencida) no interrumpe el resto', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://vencida.com',
        previewImageUrl: const Value('https://cdn.com/vencida.jpg'),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://ok.com',
        previewImageUrl: const Value('https://cdn.com/ok.jpg'),
      ));
      final imageCache = MockImageCacheService(resultsByUrl: {
        'https://cdn.com/vencida.jpg': null,
        'https://cdn.com/ok.jpg': '/data/link_previews/ok.jpg',
      });

      await makeService(
        db,
        imageCache: imageCache,
        // Sin resultado: simula que la página del link vencido tampoco
        // devuelve una imagen fresca al re-scrapear.
        metadataService: MockMetadataService(),
      ).cacheMissingPreviewImages();

      final links = await db.getAllLinks();
      final vencida = links.firstWhere((l) => l.url == 'https://vencida.com');
      final ok = links.firstWhere((l) => l.url == 'https://ok.com');
      expect(vencida.previewImagePath, isNull);
      expect(ok.previewImagePath, '/data/link_previews/ok.jpg');
    });

    test('si la URL guardada vence, re-scrapea la URL del link para recuperar una imagen fresca', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://facebook.com/share/v/abc',
        previewImageUrl: const Value('https://scontent.fbcdn.net/vencida.jpg'),
      ));
      final imageCache = MockImageCacheService(resultsByUrl: {
        // La URL vieja del backup ya no sirve.
        'https://scontent.fbcdn.net/vencida.jpg': null,
        // Pero la imagen fresca obtenida al re-scrapear la página sí.
        'https://scontent.fbcdn.net/nueva.jpg': '/data/link_previews/nueva.jpg',
      });
      final metadataService = MockMetadataService(
        result: OgMetadata(imageUrl: 'https://scontent.fbcdn.net/nueva.jpg'),
      );

      await makeService(
        db,
        imageCache: imageCache,
        metadataService: metadataService,
      ).cacheMissingPreviewImages();

      expect(metadataService.callCount, 1);
      final link = (await db.getAllLinks()).first;
      expect(link.previewImagePath, '/data/link_previews/nueva.jpg');
      expect(link.previewImageUrl, 'https://scontent.fbcdn.net/nueva.jpg');
    });

    test('ignora links sin previewImageUrl y sin og:image al re-scrapear', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://sin-imagen.com'));
      final imageCache = MockImageCacheService(result: '/otra/ruta.jpg');

      await makeService(
        db,
        imageCache: imageCache,
        metadataService: MockMetadataService(),
      ).cacheMissingPreviewImages();

      expect(imageCache.callCount, 0);
      final link = (await db.getAllLinks()).first;
      expect(link.previewImagePath, isNull);
    });

    test('recupera imagen re-scrapeando un link que nunca tuvo previewImageUrl', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://sitio.com/articulo'));
      final imageCache = MockImageCacheService(
        resultsByUrl: {'https://sitio.com/og.png': '/data/link_previews/og.png'},
      );
      final metadataService = MockMetadataService(
        result: OgMetadata(imageUrl: 'https://sitio.com/og.png'),
      );

      await makeService(
        db,
        imageCache: imageCache,
        metadataService: metadataService,
      ).cacheMissingPreviewImages();

      final link = (await db.getAllLinks()).first;
      expect(link.previewImagePath, '/data/link_previews/og.png');
      expect(link.previewImageUrl, 'https://sitio.com/og.png');
    });
  });
}
