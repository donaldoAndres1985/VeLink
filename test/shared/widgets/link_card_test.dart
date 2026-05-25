import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
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
      appStringsProvider.overrideWithValue(AppStrings('es')),
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
        makeLink(url: 'https://example.com', title: 'Example'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('example.com'), findsOneWidget);
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

    testWidgets('muestra estrella cuando isFavorite == true', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: true),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('no muestra estrella cuando isFavorite == false', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: false),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('LinkCard — URL limpia', () {
    testWidgets('muestra URL sin scheme https://', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://instagram.com/reel/abc123/', title: 'Mi reel'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('instagram.com/reel/abc123/'), findsOneWidget);
      expect(find.text('https://instagram.com/reel/abc123/'), findsNothing);
    });

    testWidgets('muestra URL sin www.', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://www.youtube.com/watch?v=abc', title: 'Video'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('youtube.com/watch?v=abc'), findsOneWidget);
    });

    testWidgets('URL completa se mantiene en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(
        LinksCompanion.insert(url: 'https://instagram.com/reel/abc123/'),
      );
      final links = await db.getAllLinks();
      expect(links.first.url, 'https://instagram.com/reel/abc123/');
    });
  });

  group('LinkCard — semantics', () {
    testWidgets('badge de plataforma tiene label de semantics correcto', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://instagram.com/p/abc', platform: 'instagram'),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Plataforma: Instagram',
        ),
        findsOneWidget,
      );
    });

    testWidgets('ícono favorito tiene label semantics actualizado', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: true),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Link favorito',
        ),
        findsOneWidget,
      );
    });

    testWidgets('botón Abrir tiene label semantics correcto', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Abrir enlace',
        ),
        findsOneWidget,
      );
    });

    testWidgets('menú tiene label semantics actualizado', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Más opciones para este link',
        ),
        findsOneWidget,
      );
    });
  });

  group('LinkCard — menú de tres puntos', () {
    testWidgets('muestra Marcar favorito cuando isFavorite == false', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Marcar favorito'), findsOneWidget);
    });

    testWidgets('muestra Quitar favorito cuando isFavorite == true', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isFavorite: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Quitar favorito'), findsOneWidget);
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

    testWidgets('muestra Marcar revisado cuando isRead=false', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isRead: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Marcar revisado'), findsOneWidget);
    });

    testWidgets('muestra Marcar pendiente cuando isRead=true', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', isRead: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Marcar pendiente'), findsOneWidget);
    });
  });

  group('LinkCard — menú compartir', () {
    testWidgets('muestra opción Compartir en el menú', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com', title: 'Ejemplo'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Compartir'), findsOneWidget);
    });

    testWidgets('el ícono de compartir es share_rounded', (tester) async {
      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(url: 'https://example.com'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });
  });

  group('LinkCard — acciones del menú', () {
    testWidgets('Marcar favorito establece isFavorite=true en DB', (tester) async {
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
      await tester.tap(find.text('Marcar favorito'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.isFavorite, true);
    });

    testWidgets('Quitar favorito establece isFavorite=false en DB', (tester) async {
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
      await tester.tap(find.text('Quitar favorito'));
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

    testWidgets('Marcar revisado actualiza isRead=true en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));

      await tester.pumpWidget(buildLinkCardWidget(
        makeLink(id: id, url: 'https://example.com', isRead: false),
        database: db,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar revisado'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.isRead, true);
    });
  });

  group('LinkCard — navegación', () {
    testWidgets('tap en la card navega a DetailScreen', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final link = makeLink(url: 'https://flutter.dev', title: 'Flutter');
      final mock = MockNotificationService();
      when(() => mock.cancelReminder(any())).thenAnswer((_) async {});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(mock),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          watchLinkTagsProvider(link.id).overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(home: Scaffold(body: LinkCard(link: link))),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('flutter.dev'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}
