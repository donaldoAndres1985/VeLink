import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/search/providers/search_provider.dart';
import '../../../helpers/database_helper.dart';

void main() {
  group('searchResultsProvider', () {
    test('retorna lista vacía cuando la query está vacía', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://flutter.dev',
        title: const Value('Flutter'),
      ));
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final results = await container.read(searchResultsProvider.future);
      expect(results, isEmpty);
    });

    test('retorna resultados cuando hay coincidencia por título', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://flutter.dev',
        title: const Value('Flutter Docs'),
      ));
      await db.insertLink(LinksCompanion.insert(
        url: 'https://dart.dev',
        title: const Value('Dart Language'),
      ));
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'flutter';
      final results = await container.read(searchResultsProvider.future);
      expect(results.length, 1);
      expect(results.first.url, 'https://flutter.dev');
    });

    test('retorna lista vacía cuando no hay coincidencia', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'kotlin';
      final results = await container.read(searchResultsProvider.future);
      expect(results, isEmpty);
    });

    test('se actualiza al cambiar la query', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(
        url: 'https://flutter.dev',
        title: const Value('Flutter'),
      ));
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'flutter';
      final results1 = await container.read(searchResultsProvider.future);
      expect(results1.length, 1);

      container.read(searchQueryProvider.notifier).state = 'kotlin';
      final results2 = await container.read(searchResultsProvider.future);
      expect(results2, isEmpty);
    });
  });
}
