import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/priority/providers/priority_provider.dart';
import '../../../helpers/database_helper.dart';

void main() {
  group('priorityLinksProvider', () {
    test('devuelve lista vacía cuando no hay links prioritarios', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await db.insertLink(LinksCompanion(url: const Value('https://example.com')));

      final links = await container.read(priorityLinksProvider.future);
      expect(links, isEmpty);
    });

    test('devuelve solo links con priority=1', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await db.insertLink(LinksCompanion(
        url: const Value('https://flutter.dev'),
        priority: const Value(1),
      ));
      await db.insertLink(LinksCompanion(
        url: const Value('https://dart.dev'),
        priority: const Value(0),
      ));

      final links = await container.read(priorityLinksProvider.future);
      expect(links.length, 1);
      expect(links.first.url, 'https://flutter.dev');
    });

    test('devuelve links prioritarios ordenados por fecha más reciente primero', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final now = DateTime.now();
      await db.insertLink(LinksCompanion(
        url: const Value('https://flutter.dev'),
        priority: const Value(1),
        createdAt: Value(now.subtract(const Duration(hours: 2))),
      ));
      await db.insertLink(LinksCompanion(
        url: const Value('https://pub.dev'),
        priority: const Value(1),
        createdAt: Value(now.subtract(const Duration(hours: 1))),
      ));

      final links = await container.read(priorityLinksProvider.future);
      expect(links.first.url, 'https://pub.dev');
      expect(links.last.url, 'https://flutter.dev');
    });
  });
}
