import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/links_table.dart';
import 'tables/tags_table.dart';
import 'tables/link_tags_table.dart';
import 'tables/collections_table.dart';
import 'tables/link_collections_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Links, Tags, LinkTags, Collections, LinkCollections])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(collections);
            await m.createTable(linkCollections);
          }
        },
      );

  // ── Links ─────────────────────────────────────────────────────────────────

  Future<List<Link>> getAllLinks() => select(links).get();

  Stream<List<Link>> watchAllLinks() =>
      (select(links)..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Future<List<Link>> getPriorityLinks() =>
      (select(links)..where((l) => l.priority.equals(1))).get();

  Stream<List<Link>> watchPriorityLinks() =>
      (select(links)..where((l) => l.priority.equals(1))
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Stream<List<Link>> watchFavoriteLinks() =>
      (select(links)..where((l) => l.isFavorite.equals(true))
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Future<Link?> getLinkByUrl(String url) =>
      (select(links)..where((l) => l.url.equals(url))).getSingleOrNull();

  Future<int> insertLink(LinksCompanion link) => into(links).insert(link);

  Future<bool> updateLink(LinksCompanion link) => update(links).replace(link);

  Future<int> deleteLink(int id) =>
      (delete(links)..where((l) => l.id.equals(id))).go();

  /// Re-inserta un link borrado (para deshacer eliminaciones).
  /// Preserva todos los campos originales, etiquetas y colecciones.
  Future<int> restoreLink(
    Link link, {
    List<Tag> tags = const [],
    List<Collection> collections = const [],
  }) async {
    final newId = await insertLink(LinksCompanion(
      url: Value(link.url),
      title: Value(link.title),
      description: Value(link.description),
      previewImageUrl: Value(link.previewImageUrl),
      previewImagePath: Value(link.previewImagePath),
      platform: Value(link.platform),
      faviconUrl: Value(link.faviconUrl),
      isFavorite: Value(link.isFavorite),
      priority: Value(link.priority),
      isRead: Value(link.isRead),
      remindAt: Value(link.remindAt),
      notes: Value(link.notes),
      createdAt: Value(link.createdAt),
    ));
    for (final tag in tags) {
      await addTagToLink(newId, tag.id);
    }
    for (final col in collections) {
      await addLinkToCollection(newId, col.id);
    }
    return newId;
  }

  Future<void> setLinkPriority(int linkId, int priority) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(priority: Value(priority)));

  Future<void> setLinkFavorite(int linkId, bool value) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(isFavorite: Value(value)));

  Future<void> setLinkReminder(int linkId, DateTime? remindAt) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(remindAt: Value(remindAt)));

  /// Guarda la ruta local de una imagen de preview ya descargada/cacheada
  /// (ej. tras un `cacheImage` exitoso), sin tocar el resto de campos.
  Future<void> setLinkPreviewImagePath(int linkId, String path) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(previewImagePath: Value(path)));

  /// Actualiza la URL remota de la imagen de preview (ej. tras re-scrapear
  /// el link porque la URL guardada ya venció), sin tocar el resto de campos.
  Future<void> setLinkPreviewImageUrl(int linkId, String url) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(previewImageUrl: Value(url)));

  Future<void> updateLinkTitle(int linkId, String? title) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(title: Value(title)));

  Future<void> updateLinkNotes(int linkId, String? notes) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(notes: Value(notes)));

  Future<List<Link>> searchLinks(String query) {
    final q = '%$query%';
    return (select(links)
      ..where((l) =>
          l.title.like(q) |
          l.description.like(q) |
          l.url.like(q) |
          l.platform.like(q))).get();
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  Future<List<Tag>> getAllTags() => select(tags).get();

  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  Future<int> insertTag(TagsCompanion tag) =>
      into(tags).insert(tag, onConflict: DoUpdate((old) => tag, target: [tags.name]));

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  Future<void> updateTag(int id, String name, String color) =>
      (update(tags)..where((t) => t.id.equals(id)))
          .write(TagsCompanion(name: Value(name), color: Value(color)));

  // ── Link + Tags ───────────────────────────────────────────────────────────

  Future<void> addTagToLink(int linkId, int tagId) =>
      into(linkTags).insertOnConflictUpdate(
        LinkTagsCompanion(
          linkId: Value(linkId),
          tagId: Value(tagId),
        ),
      );

  Future<void> removeTagFromLink(int linkId, int tagId) =>
      (delete(linkTags)
        ..where((lt) => lt.linkId.equals(linkId) & lt.tagId.equals(tagId)))
          .go();

  Stream<List<Link>> watchLinksByPlatform(String platform) =>
      (select(links)
        ..where((l) => l.platform.equals(platform))
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Stream<List<Link>> watchPendingLinks() =>
      (select(links)
        ..where((l) => l.isRead.equals(false))
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Future<void> setLinkReviewed(int linkId, bool reviewed) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(isRead: Value(reviewed)));

  Future<int> countLinksForTag(int tagId) async {
    final countExpr = linkTags.tagId.count();
    final query = selectOnly(linkTags)
      ..addColumns([countExpr])
      ..where(linkTags.tagId.equals(tagId));
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  Stream<List<Link>> watchLinksByTag(int tagId) {
    final query = select(links).join([
      innerJoin(linkTags, linkTags.linkId.equalsExp(links.id)),
    ])
      ..where(linkTags.tagId.equals(tagId))
      ..orderBy([OrderingTerm.desc(links.createdAt)]);
    return query.map((row) => row.readTable(links)).watch();
  }

  Future<List<Tag>> getTagsForLink(int linkId) {
    final query = select(tags).join([
      innerJoin(linkTags, linkTags.tagId.equalsExp(tags.id)),
    ])..where(linkTags.linkId.equals(linkId));
    return query.map((row) => row.readTable(tags)).get();
  }

  Stream<List<Tag>> watchTagsForLink(int linkId) {
    final query = select(tags).join([
      innerJoin(linkTags, linkTags.tagId.equalsExp(tags.id)),
    ])..where(linkTags.linkId.equals(linkId));
    return query.map((row) => row.readTable(tags)).watch();
  }

  // ── Collections ───────────────────────────────────────────────────────────

  Future<List<Collection>> getAllCollections() => select(collections).get();

  Stream<List<Collection>> watchAllCollections() =>
      (select(collections)
        ..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  Future<int> insertCollection(CollectionsCompanion collection) =>
      into(collections).insert(collection);

  Future<void> updateCollection(
      int id, String name, String? description, String color, String icon) =>
      (update(collections)..where((c) => c.id.equals(id))).write(
        CollectionsCompanion(
          name: Value(name),
          description: Value(description),
          color: Value(color),
          icon: Value(icon),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> deleteCollection(int id) =>
      (delete(collections)..where((c) => c.id.equals(id))).go();

  Future<bool> collectionNameExists(String name, {int? excludeId}) async {
    final all = await getAllCollections();
    return all.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        (excludeId == null || c.id != excludeId));
  }

  // ── Link + Collections ────────────────────────────────────────────────────

  Future<List<Collection>> getCollectionsForLink(int linkId) {
    final query = select(collections).join([
      innerJoin(linkCollections, linkCollections.collectionId.equalsExp(collections.id)),
    ])..where(linkCollections.linkId.equals(linkId));
    return query.map((row) => row.readTable(collections)).get();
  }

  Future<void> addLinkToCollection(int linkId, int collectionId) =>
      into(linkCollections).insertOnConflictUpdate(
        LinkCollectionsCompanion(
          linkId: Value(linkId),
          collectionId: Value(collectionId),
        ),
      );

  Future<void> removeLinkFromCollection(int linkId, int collectionId) =>
      (delete(linkCollections)
        ..where((lc) =>
            lc.linkId.equals(linkId) & lc.collectionId.equals(collectionId)))
          .go();

  Stream<List<Link>> watchLinksInCollection(int collectionId) {
    final query = select(links).join([
      innerJoin(linkCollections, linkCollections.linkId.equalsExp(links.id)),
    ])
      ..where(linkCollections.collectionId.equals(collectionId))
      ..orderBy([OrderingTerm.desc(links.createdAt)]);
    return query.map((row) => row.readTable(links)).watch();
  }

  Future<int> countLinksInCollection(int collectionId) async {
    final countExpr = linkCollections.linkId.count();
    final query = selectOnly(linkCollections)
      ..addColumns([countExpr])
      ..where(linkCollections.collectionId.equals(collectionId));
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  Future<Link?> getLastLinkAddedToCollection(int collectionId) async {
    final query = select(links).join([
      innerJoin(linkCollections, linkCollections.linkId.equalsExp(links.id)),
    ])
      ..where(linkCollections.collectionId.equals(collectionId))
      ..orderBy([OrderingTerm.desc(links.createdAt)])
      ..limit(1);
    final results = await query.map((row) => row.readTable(links)).get();
    return results.isEmpty ? null : results.first;
  }

  Stream<List<Collection>> watchCollectionsForLink(int linkId) {
    final query = select(collections).join([
      innerJoin(
          linkCollections, linkCollections.collectionId.equalsExp(collections.id)),
    ])..where(linkCollections.linkId.equals(linkId));
    return query.map((row) => row.readTable(collections)).watch();
  }

  Future<void> deleteAllData() async {
    await delete(linkCollections).go();
    await delete(linkTags).go();
    await delete(links).go();
    await delete(tags).go();
    await delete(collections).go();
  }

  // ── Resurface & Stats ─────────────────────────────────────────────────────

  Stream<List<Link>> watchForgottenLinks({int daysOld = 7, int limit = 8}) {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    return (select(links)
          ..where((l) =>
              l.isRead.equals(false) &
              l.createdAt.isSmallerThanValue(cutoff))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<LinkStats> getLinkStats() async {
    final all = await getAllLinks();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    final thisWeek = all.where((l) => l.createdAt.isAfter(weekAgo)).length;
    final thisMonth = all.where((l) => l.createdAt.isAfter(monthAgo)).length;
    final reviewed = all.where((l) => l.isRead).length;
    final pending = all.where((l) => !l.isRead).length;
    final favorites = all.where((l) => l.isFavorite).length;

    final platformCount = <String, int>{};
    for (final l in all) {
      platformCount[l.platform] = (platformCount[l.platform] ?? 0) + 1;
    }
    String? topPlatform;
    if (platformCount.isNotEmpty) {
      topPlatform = platformCount.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return LinkStats(
      total: all.length,
      thisWeek: thisWeek,
      thisMonth: thisMonth,
      reviewed: reviewed,
      pending: pending,
      favorites: favorites,
      topPlatform: topPlatform,
      uniquePlatforms: platformCount.length,
    );
  }

  Future<List<DayCount>> getLinksPerDay({int days = 7}) async {
    final all = await getAllLinks();
    final now = DateTime.now();
    final origin = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final counts = <String, int>{};
    for (final link in all) {
      final d = link.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(origin)) {
        final key = _dayKey(day);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return List.generate(days, (i) {
      final date = origin.add(Duration(days: i));
      return DayCount(date: date, count: counts[_dayKey(date)] ?? 0);
    });
  }

  Future<List<PlatformCount>> getPlatformBreakdown() async {
    final all = await getAllLinks();
    if (all.isEmpty) return [];

    final counts = <String, int>{};
    for (final link in all) {
      final p = link.platform;
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => PlatformCount(platform: e.key, count: e.value)).toList();
  }

  Future<List<DayCount>> getLinksForYear() async {
    const yearDays = 364;
    final all = await getAllLinks();
    final now = DateTime.now();
    final origin = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: yearDays - 1));

    final counts = <String, int>{};
    for (final link in all) {
      final d = link.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(origin)) {
        final key = _dayKey(day);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return List.generate(yearDays, (i) {
      final date = origin.add(Duration(days: i));
      return DayCount(date: date, count: counts[_dayKey(date)] ?? 0);
    });
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class LinkStats {
  final int total;
  final int thisWeek;
  final int thisMonth;
  final int reviewed;
  final int pending;
  final int favorites;
  final String? topPlatform;
  final int uniquePlatforms;

  const LinkStats({
    required this.total,
    required this.thisWeek,
    required this.thisMonth,
    required this.reviewed,
    required this.pending,
    required this.favorites,
    this.topPlatform,
    this.uniquePlatforms = 0,
  });
}

class DayCount {
  final DateTime date;
  final int count;
  const DayCount({required this.date, required this.count});
}

class PlatformCount {
  final String platform;
  final int count;
  const PlatformCount({required this.platform, required this.count});
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'velink.db'));
    return NativeDatabase(file);
  });
}
