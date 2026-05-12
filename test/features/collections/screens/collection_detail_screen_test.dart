import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/features/collections/providers/collection_providers.dart';
import 'package:velink/features/collections/screens/collection_detail_screen.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/link_factory.dart';

Collection makeCollection({
  int id = 1,
  String name = 'Test',
  String color = '#6366F1',
  String icon = 'folder',
}) =>
    Collection(
      id: id,
      name: name,
      color: color,
      icon: icon,
      description: null,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

Widget buildDetailWidget({
  Collection? collection,
  List<Link> links = const [],
}) {
  final col = collection ?? makeCollection();
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      linksInCollectionProvider(col.id)
          .overrideWith((ref) => Stream.value(links)),
    ],
    child: MaterialApp(home: CollectionDetailScreen(collection: col)),
  );
}

void main() {
  group('CollectionDetailScreen — app bar', () {
    testWidgets('muestra nombre de la colección en app bar', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        collection: makeCollection(name: 'Flutter Dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Dev'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay links', (tester) async {
      await tester.pumpWidget(buildDetailWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay links en esta colección'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen — búsqueda', () {
    testWidgets('muestra campo de búsqueda', (tester) async {
      await tester.pumpWidget(buildDetailWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filtra links al escribir en búsqueda', (tester) async {
      await tester.pumpWidget(buildDetailWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1),
        makeLink(url: 'https://dart.dev', id: 2),
      ]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pumpAndSettle();

      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsNothing);
    });
  });

  group('CollectionDetailScreen — lista', () {
    testWidgets('muestra links en la colección', (tester) async {
      await tester.pumpWidget(buildDetailWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsWidgets);
    });

    testWidgets('muestra múltiples links', (tester) async {
      await tester.pumpWidget(buildDetailWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1),
        makeLink(url: 'https://dart.dev', id: 2),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsWidgets);
    });
  });

  group('CollectionDetailScreen — quitar link por swipe', () {
    testWidgets('deslizar card quita link de colección en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final colId = await db.insertCollection(
          CollectionsCompanion.insert(name: 'Dev'));
      final linkId =
          await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      await db.addLinkToCollection(linkId, colId);
      final col = makeCollection(id: colId, name: 'Dev');

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          linksInCollectionProvider(colId)
              .overrideWith((ref) => db.watchLinksInCollection(colId)),
        ],
        child: MaterialApp(home: CollectionDetailScreen(collection: col)),
      ));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      final count = await db.countLinksInCollection(colId);
      expect(count, 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('deslizar no elimina el link de la DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final colId = await db.insertCollection(
          CollectionsCompanion.insert(name: 'Dev'));
      final linkId =
          await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      await db.addLinkToCollection(linkId, colId);
      final col = makeCollection(id: colId, name: 'Dev');

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          linksInCollectionProvider(colId)
              .overrideWith((ref) => db.watchLinksInCollection(colId)),
        ],
        child: MaterialApp(home: CollectionDetailScreen(collection: col)),
      ));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.length, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
