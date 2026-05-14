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

  Future<void> setLinkPriority(int linkId, int priority) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(priority: Value(priority)));

  Future<void> setLinkFavorite(int linkId, bool value) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(isFavorite: Value(value)));

  Future<void> setLinkReminder(int linkId, DateTime? remindAt) =>
      (update(links)..where((l) => l.id.equals(linkId)))
          .write(LinksCompanion(remindAt: Value(remindAt)));

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
