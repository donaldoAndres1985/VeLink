import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/links_table.dart';
import 'tables/tags_table.dart';
import 'tables/link_tags_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Links, Tags, LinkTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // Links
  Future<List<Link>> getAllLinks() => select(links).get();

  Stream<List<Link>> watchAllLinks() =>
      (select(links)..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Stream<List<Link>> watchPriorityLinks() =>
      (select(links)..where((l) => l.priority.equals(1))
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

  Stream<List<Link>> watchFavoriteLinks() =>
      (select(links)..where((l) => l.isFavorite.equals(true))
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();

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

  // Tags
  Future<List<Tag>> getAllTags() => select(tags).get();

  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  Future<int> insertTag(TagsCompanion tag) =>
      into(tags).insert(tag, onConflict: DoUpdate((old) => tag, target: [tags.name]));

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  // Link + Tags
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
    return NativeDatabase.createInBackground(file);
  });
}
