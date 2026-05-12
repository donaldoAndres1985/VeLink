import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/detail/providers/detail_provider.dart';
import 'package:velink/features/detail/screens/detail_screen.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/notifications/services/notification_service.dart';
import 'package:velink/shared/widgets/link_card.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

class MockNotificationService extends Mock implements NotificationService {}

Widget buildLinkCardWidget(Link link, {AppDatabase? database}) {
  final db = database ?? createTestDatabase();
  if (database == null) addTearDown(db.close);
  final mock = MockNotificationService();
  when(() => mock.cancelReminder(any())).thenAnswer((_) async {});
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(mock),
      watchLinkTagsProvider(link.id).overrideWith((ref) => Stream.value(<Tag>[])),
      allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
    ],
    child: MaterialApp(home: Scaffold(body: LinkCard(link: link))),
  );
}

void main() {
  group('LinkCard — contenido', () {
    testWidgets('muestra la URL del link', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('muestra el título cuando está disponible', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', title: 'Mi Artículo'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Mi Artículo'), findsOneWidget);
    });

    testWidgets('muestra el badge de plataforma', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://youtube.com/watch?v=abc', platform: 'youtube'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('muestra placeholder cuando no hay imagen de preview', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('muestra botón Abrir', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Abrir'), findsOneWidget);
    });

    testWidgets('muestra ícono de tres puntos', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('muestra estrella en amber cuando priority == 1', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', priority: 1),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('no muestra estrella cuando priority == 0', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', priority: 0),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('LinkCard — menú de tres puntos', () {
    testWidgets('abre el menú y muestra Marcar prioritario cuando priority == 0', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', priority: 0),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Marcar prioritario'), findsOneWidget);
    });

    testWidgets('muestra Quitar prioridad cuando priority == 1', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', priority: 1),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Quitar prioridad'), findsOneWidget);
    });

    testWidgets('muestra Guardar cuando no es favorito', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('muestra Quitar guardado cuando es favorito', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Quitar guardado'), findsOneWidget);
    });

    testWidgets('muestra opción Eliminar', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar'), findsOneWidget);
    });
  });

  group('LinkCard — acciones del menú', () {
    testWidgets('Marcar prioritario establece priority=1 en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com', priority: 0),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar prioritario'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.priority, 1);
    });

    testWidgets('Quitar prioridad establece priority=0 en DB', (tester) async {
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

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar prioridad'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.priority, 0);
    });

    testWidgets('Guardar marca isFavorite=true en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com', isFavorite: false),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.isFavorite, true);
    });

    testWidgets('Quitar guardado marca isFavorite=false en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://example.com',
        isFavorite: const Value(true),
      ));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com', isFavorite: true),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar guardado'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.isFavorite, false);
    });

    testWidgets('Eliminar borra el link de DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com'),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links, isEmpty);
    });
  });

  group('LinkCard — navegación', () {
    testWidgets('tap en la card navega a DetailScreen', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final link = makeLink(url: 'https://flutter.dev');
      final mock = MockNotificationService();
      when(() => mock.cancelReminder(any())).thenAnswer((_) async {});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(mock),
          watchLinkTagsProvider(link.id).overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(home: Scaffold(body: LinkCard(link: link))),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('https://flutter.dev'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}
