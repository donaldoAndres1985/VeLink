import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database.dart';

const _kBackupFileName = 'velink_backup.json';
const _kBackupVersion = 1;

class ImportResult {
  final int imported;
  final int skipped;
  const ImportResult({required this.imported, required this.skipped});
}

class InvalidBackupException implements Exception {
  const InvalidBackupException();
}

class BackupFileNotFoundException implements Exception {
  const BackupFileNotFoundException();
}

class BackupService {
  final AppDatabase _db;
  BackupService(this._db);

  Future<String> _backupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<String> exportToJson() async {
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
        'title': link.title,
        'description': link.description,
        'previewImageUrl': link.previewImageUrl,
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

    final backup = {
      'version': _kBackupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'links': linksJson,
      'tags': allTags
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'createdAt': t.createdAt.toIso8601String(),
              })
          .toList(),
      'collections': allCollections
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'description': c.description,
                'color': c.color,
                'icon': c.icon,
                'createdAt': c.createdAt.toIso8601String(),
                'updatedAt': c.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    final dir = await _backupDir();
    final file = File('$dir/$_kBackupFileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
    return file.path;
  }

  Future<Map<String, dynamic>?> readBackupPreview() async {
    final dir = await _backupDir();
    final file = File('$dir/$_kBackupFileName');
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (!data.containsKey('version') || !data.containsKey('links')) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<ImportResult> importFromJson() async {
    final dir = await _backupDir();
    final file = File('$dir/$_kBackupFileName');
    if (!await file.exists()) throw const BackupFileNotFoundException();

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw const InvalidBackupException();
    }
    if (!data.containsKey('version') || !data.containsKey('links')) {
      throw const InvalidBackupException();
    }

    // ── Tags ──────────────────────────────────────────────────────────────────
    final tagsData = (data['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final Map<int, int> tagIdMap = {};
    final existingTags = await _db.getAllTags();
    for (final td in tagsData) {
      final name = td['name'] as String;
      final oldId = td['id'] as int;
      final found = existingTags.where((t) => t.name.toLowerCase() == name.toLowerCase()).firstOrNull;
      if (found != null) {
        tagIdMap[oldId] = found.id;
      } else {
        final newId = await _db.insertTag(TagsCompanion(name: Value(name)));
        tagIdMap[oldId] = newId;
      }
    }

    // ── Collections ───────────────────────────────────────────────────────────
    final collsData = (data['collections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final Map<int, int> collIdMap = {};
    final existingColls = await _db.getAllCollections();
    for (final cd in collsData) {
      final name = cd['name'] as String;
      final oldId = cd['id'] as int;
      final found = existingColls.where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;
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
    final linksData = (data['links'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    int imported = 0;
    int skipped = 0;
    for (final ld in linksData) {
      final url = ld['url'] as String;
      if (await _db.getLinkByUrl(url) != null) {
        skipped++;
        continue;
      }
      final remindAtStr = ld['remindAt'] as String?;
      final linkId = await _db.insertLink(LinksCompanion(
        url: Value(url),
        title: Value(ld['title'] as String?),
        description: Value(ld['description'] as String?),
        previewImageUrl: Value(ld['previewImageUrl'] as String?),
        platform: Value(ld['platform'] as String? ?? 'web'),
        isFavorite: Value(ld['isFavorite'] as bool? ?? false),
        isRead: Value(ld['isRead'] as bool? ?? false),
        priority: Value(ld['priority'] as int? ?? 0),
        notes: Value(ld['notes'] as String?),
        remindAt: Value(remindAtStr != null ? DateTime.tryParse(remindAtStr) : null),
      ));
      for (final oldTagId in (ld['tagIds'] as List?)?.cast<int>() ?? <int>[]) {
        final newId = tagIdMap[oldTagId];
        if (newId != null) await _db.addTagToLink(linkId, newId);
      }
      for (final oldCollId in (ld['collectionIds'] as List?)?.cast<int>() ?? <int>[]) {
        final newId = collIdMap[oldCollId];
        if (newId != null) await _db.addLinkToCollection(linkId, newId);
      }
      imported++;
    }

    return ImportResult(imported: imported, skipped: skipped);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
