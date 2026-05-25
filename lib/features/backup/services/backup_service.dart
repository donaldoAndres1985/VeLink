import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/preferences/preferences_service.dart';

const _kBackupVersion = 1;

class ImportResult {
  final int imported;
  final int skipped;
  const ImportResult({required this.imported, required this.skipped});
}

class InvalidBackupException implements Exception {
  const InvalidBackupException();
}

class BackupService {
  final AppDatabase _db;
  final PreferencesService _prefs;

  BackupService(this._db, this._prefs);

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Construye el Map del backup. Separado para facilitar tests.
  Future<Map<String, dynamic>> buildBackupData() async {
    final allLinks = await _db.getAllLinks();
    final allTags = await _db.getAllTags();
    final allCollections = await _db.getAllCollections();

    final List<Map<String, dynamic>> linksJson = [];
    for (final link in allLinks) {
      final tags = await _db.getTagsForLink(link.id);
      final colls = await _db.getCollectionsForLink(link.id);
      linksJson.add({
        'id': link.id,
        'url': link.url,
        'displayUrl': _displayUrl(link.url),
        'title': link.title,
        'description': link.description,
        'previewImageUrl': link.previewImageUrl,
        'previewImagePath': link.previewImagePath,
        'faviconUrl': link.faviconUrl,
        'platform': link.platform,
        'isFavorite': link.isFavorite,
        'isRead': link.isRead,
        'priority': link.priority,
        'notes': link.notes,
        'remindAt': link.remindAt?.toIso8601String(),
        'createdAt': link.createdAt.toIso8601String(),
        'updatedAt': link.updatedAt.toIso8601String(),
        'tagIds': tags.map((t) => t.id).toList(),
        'collectionIds': colls.map((c) => c.id).toList(),
      });
    }

    return {
      'version': _kBackupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'language': _prefs.getLocale().languageCode,
        'notificationsEnabled': _prefs.getNotificationsEnabled(),
      },
      'links': linksJson,
      'tags': allTags.map((t) => {
        'id': t.id,
        'name': t.name,
        'color': t.color,
        'createdAt': t.createdAt.toIso8601String(),
      }).toList(),
      'collections': allCollections.map((c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'color': c.color,
        'icon': c.icon,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      }).toList(),
    };
  }

  Future<void> exportToJson() async {
    final backup = await buildBackupData();
    final date = DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/verlink_backup_$dateStr.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> readBackupPreview(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (!data.containsKey('version') || !data.containsKey('links')) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<ImportResult> importFromJson(String filePath, {bool replace = false}) async {
    final file = File(filePath);
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw const InvalidBackupException();
    }
    if (!data.containsKey('version') || !data.containsKey('links')) {
      throw const InvalidBackupException();
    }
    return importFromBackupData(data, replace: replace);
  }

  /// Importa desde un Map ya parseado. Expuesto para tests.
  Future<ImportResult> importFromBackupData(
    Map<String, dynamic> data, {
    bool replace = false,
  }) async {
    if (!data.containsKey('version') || !data.containsKey('links')) {
      throw const InvalidBackupException();
    }

    if (replace) await _db.deleteAllData();

    // ── Tags ──────────────────────────────────────────────────────────────────
    final tagsData = (data['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final Map<int, int> tagIdMap = {};
    final existingTags = await _db.getAllTags();
    for (final td in tagsData) {
      final name = td['name'] as String;
      final color = td['color'] as String? ?? '#6366F1';
      final oldId = td['id'] as int;
      final found = existingTags
          .where((t) => t.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (found != null) {
        tagIdMap[oldId] = found.id;
      } else {
        final newId = await _db.insertTag(
          TagsCompanion(name: Value(name), color: Value(color)),
        );
        tagIdMap[oldId] = newId;
      }
    }

    // ── Collections ───────────────────────────────────────────────────────────
    final collsData =
        (data['collections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final Map<int, int> collIdMap = {};
    final existingColls = await _db.getAllCollections();
    for (final cd in collsData) {
      final name = cd['name'] as String;
      final oldId = cd['id'] as int;
      final found = existingColls
          .where((c) => c.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (found != null) {
        collIdMap[oldId] = found.id;
      } else {
        final newId = await _db.insertCollection(CollectionsCompanion(
          name: Value(name),
          description: Value(cd['description'] as String?),
          color: Value(cd['color'] as String? ?? '#6366F1'),
          icon: Value(cd['icon'] as String? ?? 'folder'),
        ));
        collIdMap[oldId] = newId;
      }
    }

    // ── Links ─────────────────────────────────────────────────────────────────
    final linksData =
        (data['links'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    int imported = 0;
    int skipped = 0;
    for (final ld in linksData) {
      final url = ld['url'] as String;
      if (!replace && await _db.getLinkByUrl(url) != null) {
        skipped++;
        continue;
      }
      final remindAtStr = ld['remindAt'] as String?;
      final linkId = await _db.insertLink(LinksCompanion(
        url: Value(url),
        title: Value(ld['title'] as String?),
        description: Value(ld['description'] as String?),
        previewImageUrl: Value(ld['previewImageUrl'] as String?),
        previewImagePath: Value(ld['previewImagePath'] as String?),
        faviconUrl: Value(ld['faviconUrl'] as String?),
        platform: Value(ld['platform'] as String? ?? 'web'),
        isFavorite: Value(ld['isFavorite'] as bool? ?? false),
        isRead: Value(ld['isRead'] as bool? ?? false),
        priority: Value(ld['priority'] as int? ?? 0),
        notes: Value(ld['notes'] as String?),
        remindAt:
            Value(remindAtStr != null ? DateTime.tryParse(remindAtStr) : null),
      ));
      for (final oldTagId
          in (ld['tagIds'] as List?)?.cast<int>() ?? <int>[]) {
        final newId = tagIdMap[oldTagId];
        if (newId != null) await _db.addTagToLink(linkId, newId);
      }
      for (final oldCollId
          in (ld['collectionIds'] as List?)?.cast<int>() ?? <int>[]) {
        final newId = collIdMap[oldCollId];
        if (newId != null) await _db.addLinkToCollection(linkId, newId);
      }
      imported++;
    }

    return ImportResult(imported: imported, skipped: skipped);
  }

  // ── Utils ─────────────────────────────────────────────────────────────────

  static String _displayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      final path = (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
      final query = uri.query.isEmpty ? '' : '?${uri.query}';
      return '$host$path$query';
    } catch (_) {
      return url;
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    ref.read(preferencesServiceProvider),
  );
});
