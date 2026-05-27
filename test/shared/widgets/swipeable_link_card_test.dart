import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/theme/app_theme.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/detail/providers/detail_provider.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/notifications/services/notification_service.dart';
import 'package:velink/shared/widgets/swipeable_link_card.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

class MockNotificationService extends Mock implements NotificationService {}

Widget buildSwipeableWidget(Link link, {required AppDatabase database}) {
  final mock = MockNotificationService();
  when(() => mock.cancelReminder(any())).thenAnswer((_) async {});
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      notificationServiceProvider.overrideWithValue(mock),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      watchLinkTagsProvider(link.id).overrideWith((ref) => Stream.value(<Tag>[])),
      allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SwipeableLinkCard(link: link)),
    ),
  );
}

/// Simula la estructura real de la app:
/// MainShell.Scaffold (exterior) → ScaffoldMessenger aislado → HomeScreen.Scaffold (interior)
/// Sin el ScaffoldMessenger aislado los 5 Scaffolds comparten el mismo messenger
/// y el timer de auto-dismiss del snackbar no funciona.
Widget buildSwipeableWidgetRealAppStructure(
  Link link, {
  required AppDatabase database,
}) {
  final mock = MockNotificationService();
  when(() => mock.cancelReminder(any())).thenAnswer((_) async {});
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      notificationServiceProvider.overrideWithValue(mock),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      watchLinkTagsProvider(link.id).overrideWith((ref) => Stream.value(<Tag>[])),
      allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold( // Scaffold exterior — como MainShell
        body: ScaffoldMessenger( // ScaffoldMessenger aislado por pantalla
          child: Scaffold( // Scaffold interior — como HomeScreen
            body: SwipeableLinkCard(link: link),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SwipeableLinkCard — contenido', () {
    testWidgets('muestra el contenido del LinkCard', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final link = makeLink(url: 'https://example.com', title: 'Mi Link Test');
      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();
      expect(find.text('Mi Link Test'), findsOneWidget);
    });

    testWidgets('muestra el icono de eliminar al hacer swipe derecha', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final link = makeLink(url: 'https://example.com', title: 'Link');
      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(60, 0));
      await tester.pump();

      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
    });

    testWidgets('muestra el icono de revisado al hacer swipe izquierda', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final link = makeLink(url: 'https://example.com', title: 'Link');
      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-60, 0));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('SwipeableLinkCard — acciones', () {
    testWidgets('swipe izquierda > umbral marca el link como revisado', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      final updated = await db.getLinkByUrl('https://example.com');
      expect(updated?.isRead, isTrue);
    });

    testWidgets('swipe derecha > umbral elimina el link', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      final remaining = await db.getAllLinks();
      expect(remaining, isEmpty);
    });

    testWidgets('swipe corto no dispara acción (spring-back)', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-50, 0));
      await tester.pumpAndSettle();

      final updated = await db.getLinkByUrl('https://example.com');
      expect(updated?.isRead, isFalse);
    });

    testWidgets('swipe corto: la card vuelve al centro (offset=0) con animación', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-60, 0));
      await tester.pumpAndSettle();

      // El Transform.translate debe tener offset X en 0 tras la animación
      final t = tester.firstWidget<Transform>(find.byType(Transform));
      expect(t.transform.getTranslation().x, closeTo(0.0, 1.0),
          reason: 'La card debería volver al centro tras un swipe corto');
    });

    testWidgets('tras swipe derecha > umbral aparece snackbar de link eliminado', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Link eliminado'), findsOneWidget);
    });

    testWidgets('tras swipe izquierda > umbral aparece snackbar con opción Deshacer', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Link marcado como revisado'), findsOneWidget);
      expect(find.text('Deshacer'), findsOneWidget);
    });

    testWidgets('Deshacer en snackbar de revisado revierte el cambio en BD', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      // Pulsar Deshacer
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      final reverted = await db.getLinkByUrl('https://example.com');
      expect(reverted?.isRead, isFalse,
          reason: 'Deshacer debe revertir isRead a false');
    });

    testWidgets('tras marcar revisado la card vuelve al offset 0 (no queda pegada)', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      // La card debería haber vuelto a offset 0 tras la acción (no quedarse en -220)
      final t = tester.firstWidget<Transform>(find.byType(Transform));
      expect(t.transform.getTranslation().x, closeTo(0.0, 5.0),
          reason: 'La card no debe quedar pegada tras marcar revisado');
    });

    testWidgets('múltiples swipes no apilan snackbars (clearSnackBars)', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://a.com'));
      await db.insertLink(LinksCompanion.insert(url: 'https://b.com'));
      final links = await db.getAllLinks();

      // Montamos la card del primer link y la marcamos como revisada
      await tester.pumpWidget(buildSwipeableWidget(links[0], database: db));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      // Solo debe haber un snackbar visible
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('snackbar de eliminar tiene opción Deshacer', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Deshacer'), findsOneWidget,
          reason: 'El snackbar de eliminar debe tener opción Deshacer');
    });

    testWidgets('Deshacer en snackbar de eliminar restaura el link en la BD', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      // Pulsar Deshacer
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      final restored = await db.getLinkByUrl('https://to-delete.com');
      expect(restored, isNotNull,
          reason: 'Deshacer debe restaurar el link eliminado');
    });

    testWidgets('snackbar de revisado tiene duration explícita (≤4s) para auto-descartarse', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      // Verificar que el SnackBar tiene una duration ≤ 4 segundos para que se descarte sólo
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration.inMilliseconds, lessThanOrEqualTo(4000),
          reason: 'El snackbar debe tener duration explícita para no quedarse indefinidamente');
    });

    testWidgets('snackbar de eliminar tiene duration explícita para auto-descartarse', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration.inMilliseconds, lessThanOrEqualTo(4000),
          reason: 'El snackbar de eliminar debe desaparecer en ≤4s igual que el de revisado');
    });

    testWidgets('tras swipe derecha > umbral la card se oculta (sin fondo rojo residual)', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      // Tras el dismiss el fondo rojo (icono borrar) NO debe seguir visible
      expect(
        find.byIcon(Icons.delete_rounded),
        findsNothing,
        reason: 'No debe quedar fondo rojo (icono de borrar) visible tras eliminar el link',
      );
    });

    testWidgets('snackbar de eliminar aparece incluso si el widget ya no está montado', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(buildSwipeableWidget(link, database: db));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      // El snackbar con "Link eliminado" debe aparecer siempre
      expect(find.text('Link eliminado'), findsOneWidget,
          reason: 'El snackbar debe mostrarse aunque el widget se haya ocultado');
    });
  });

  // ── Estructura real de la app (Scaffolds anidados) ────────────────────────
  // En la app real MainShell y cada pantalla tienen su propio Scaffold.
  // Con _KeepAlivePage hay 5 Scaffolds registrados en el mismo ScaffoldMessenger,
  // lo que rompe el timer de auto-dismiss. Cada pantalla necesita su propio
  // ScaffoldMessenger aislado.
  group('SwipeableLinkCard — con Scaffolds anidados (estructura real)', () {
    testWidgets('snackbar de eliminar aparece con Scaffold exterior presente', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(
        buildSwipeableWidgetRealAppStructure(link, database: db),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Link eliminado'), findsOneWidget,
          reason: 'El snackbar debe aparecer incluso con Scaffolds anidados');
    });

    testWidgets('snackbar de eliminar tiene duration ≤4s con Scaffolds anidados', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://to-delete.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(
        buildSwipeableWidgetRealAppStructure(link, database: db),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration.inMilliseconds, lessThanOrEqualTo(4000),
          reason: 'Duration debe ser ≤4s también con Scaffolds anidados');
    });

    testWidgets('snackbar de revisado aparece con Scaffold exterior presente', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://example.com'));
      final link = (await db.getAllLinks()).first;

      await tester.pumpWidget(
        buildSwipeableWidgetRealAppStructure(link, database: db),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableLinkCard), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Link marcado como revisado'), findsOneWidget,
          reason: 'El snackbar de revisado debe aparecer con Scaffolds anidados');
    });
  });
}
