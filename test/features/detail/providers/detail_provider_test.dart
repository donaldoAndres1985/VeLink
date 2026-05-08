import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/detail/providers/detail_provider.dart';
import '../../../helpers/database_helper.dart';

void main() {
  group('linkTagsProvider', () {
    test('devuelve lista vacía cuando el link no tiene tags', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      final tags = await container.read(linkTagsProvider(id).future);
      expect(tags, isEmpty);
    });

    test('devuelve los tags asociados al link', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.addTagToLink(linkId, tagId);

      final tags = await container.read(linkTagsProvider(linkId).future);
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });

    test('no devuelve tags de otros links', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final id1 = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final id2 = await db.insertLink(LinksCompanion.insert(url: 'https://dart.dev'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.addTagToLink(id2, tagId);

      final tags = await container.read(linkTagsProvider(id1).future);
      expect(tags, isEmpty);
    });
  });
}
