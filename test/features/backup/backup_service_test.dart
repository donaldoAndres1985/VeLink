import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/backup/services/backup_service.dart';
import '../../helpers/database_helper.dart';

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

BackupService makeService(AppDatabase db) =>
    BackupService(db, _FakePrefs());

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
}
