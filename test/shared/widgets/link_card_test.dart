import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/detail/screens/detail_screen.dart';
import 'package:velink/shared/widgets/link_card.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildLinkCardWidget(Link link, {AppDatabase? database}) {
  final db = database ?? createTestDatabase();
  if (database == null) addTearDown(db.close);
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: Scaffold(body: LinkCard(link: link))),
  );
}

void main() {
  group('LinkCard — icono de prioridad (visual)', () {
    testWidgets('muestra star_outline cuando priority == 0', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(makeLink(url: 'https://example.com', priority: 0)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('muestra star (rellena) cuando priority == 1', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(makeLink(url: 'https://example.com', priority: 1)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('LinkCard — toggle de prioridad (DB)', () {
    testWidgets('tap en star_outline establece priority=1 en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com', priority: 0),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.priority, 1);
    });

    testWidgets('tap en star establece priority=0 en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        priority: const Value(1),
      ));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com', priority: 1),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.priority, 0);
    });
  });

  group('LinkCard — navegación', () {
    testWidgets('tap en la card navega a DetailScreen', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final link = makeLink(url: 'https://flutter.dev');
      await tester.pumpWidget(ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: Scaffold(body: LinkCard(link: link))),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('https://flutter.dev'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}
