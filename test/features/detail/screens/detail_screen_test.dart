import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/detail/providers/detail_provider.dart';
import 'package:velink/features/detail/screens/detail_screen.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/notifications/services/notification_service.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/link_factory.dart';

class MockNotificationService extends Mock implements NotificationService {}

Widget buildDetailWidget(
  Link link, {
  List<Tag> tags = const [],
  List<Tag> allTags = const [],
  NotificationService? notifService,
}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  final mock = notifService ?? MockNotificationService();
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      notificationServiceProvider.overrideWithValue(mock),
      linkTagsProvider(link.id).overrideWith((ref) => Future.value(tags)),
      watchLinkTagsProvider(link.id).overrideWith((ref) => Stream.value(tags)),
      allTagsProvider.overrideWith((ref) => Stream.value(allTags)),
    ],
    child: MaterialApp(home: DetailScreen(link: link)),
  );
}

void main() {
  group('DetailScreen — contenido básico', () {
    testWidgets('muestra la URL del link', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('muestra el título cuando está disponible', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev', title: 'Flutter Docs'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Docs'), findsOneWidget);
    });

    testWidgets('muestra la descripción cuando está disponible', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev', description: 'El SDK de Flutter'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('El SDK de Flutter'), findsOneWidget);
    });

    testWidgets('muestra el badge de plataforma', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://youtube.com/watch?v=abc', platform: 'youtube'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });
  });

  group('DetailScreen — tags', () {
    testWidgets('muestra los tags del link', (tester) async {
      final tags = [
        Tag(id: 1, name: 'flutter', color: '#6366F1', createdAt: DateTime.now()),
        Tag(id: 2, name: 'dart', color: '#6366F1', createdAt: DateTime.now()),
      ];
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
        tags: tags,
        allTags: tags,
      ));
      await tester.pumpAndSettle();
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay tags', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Sin etiquetas'), findsOneWidget);
    });
  });

  group('DetailScreen — app bar', () {
    testWidgets('muestra título Detalle en el app bar', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Detalle'), findsOneWidget);
    });
  });

  group('DetailScreen — título editable', () {
    testWidgets('muestra el título en un campo editable', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev', title: 'Flutter Docs'),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('title_field')), findsOneWidget);
      expect(find.text('Flutter Docs'), findsOneWidget);
    });

    testWidgets('guardar título actualiza la DB al perder el foco', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://flutter.dev',
        title: const Value('Título viejo'),
      ));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
          linkTagsProvider(id).overrideWith((ref) => Future.value(<Tag>[])),
          watchLinkTagsProvider(id).overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(
          home: DetailScreen(
              link: makeLink(id: id, url: 'https://flutter.dev', title: 'Título viejo')),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('title_field')));
      await tester.enterText(find.byKey(const Key('title_field')), 'Título nuevo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final links = await db.getAllLinks();
      expect(links.first.title, 'Título nuevo');
    });
  });

  group('DetailScreen — notas', () {
    testWidgets('muestra notas existentes del link', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev', notes: 'Leer este fin de semana'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Leer este fin de semana'), findsOneWidget);
    });

    testWidgets('muestra campo de texto para notas', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notes_field')), findsOneWidget);
    });

    testWidgets('guardar nota llama updateLinkNotes en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
          linkTagsProvider(id).overrideWith((ref) => Future.value(<Tag>[])),
          watchLinkTagsProvider(id).overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(home: DetailScreen(link: makeLink(id: id, url: 'https://flutter.dev'))),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('notes_field')));
      await tester.enterText(find.byKey(const Key('notes_field')), 'Nueva nota');
      await tester.pump();
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pump();

      final links = await db.getAllLinks();
      expect(links.first.notes, 'Nueva nota');
    });
  });

  group('DetailScreen — abrir link', () {
    testWidgets('muestra botón para abrir el link original', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Abrir'), findsOneWidget);
    });

    testWidgets('muestra ícono de enlace externo junto al botón Abrir', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });
  });

  group('DetailScreen — recordatorio HU22', () {
    testWidgets('muestra sección de recordatorio', (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Recordatorio'), findsOneWidget);
    });

    testWidgets('muestra botón para agregar recordatorio cuando no hay remindAt',
        (tester) async {
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Agregar recordatorio'), findsOneWidget);
    });

    testWidgets('muestra la fecha del recordatorio cuando está configurado',
        (tester) async {
      final remindAt = DateTime(2026, 12, 25, 9, 0);
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev', remindAt: remindAt),
      ));
      await tester.pumpAndSettle();
      expect(find.text('25/12/2026 09:00'), findsOneWidget);
    });

    testWidgets('muestra botón para eliminar recordatorio cuando hay remindAt',
        (tester) async {
      final remindAt = DateTime(2026, 12, 25, 9, 0);
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev', remindAt: remindAt),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar recordatorio'), findsOneWidget);
    });

    testWidgets('tap en eliminar recordatorio llama cancelReminder', (tester) async {
      final mockService = MockNotificationService();
      when(() => mockService.cancelReminder(any())).thenAnswer((_) async {});

      final db = createTestDatabase();
      addTearDown(db.close);
      final remindAt = DateTime(2026, 12, 25, 9, 0);
      final id = await db.insertLink(LinksCompanion.insert(
        url: 'https://flutter.dev',
        remindAt: Value(remindAt),
      ));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider.overrideWithValue(mockService),
          linkTagsProvider(id).overrideWith((ref) => Future.value(<Tag>[])),
          watchLinkTagsProvider(id)
              .overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(
          home: DetailScreen(link: makeLink(id: id, url: 'https://flutter.dev', remindAt: remindAt)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Eliminar recordatorio'));
      await tester.tap(find.text('Eliminar recordatorio'));
      await tester.pump();

      verify(() => mockService.cancelReminder(id)).called(1);
    });
  });

  group('DetailScreen — auto-cierre al regresar de URL', () {
    testWidgets('al regresar a la app después de abrir URL, cierra el detalle',
        (tester) async {
      final link = makeLink(url: 'https://flutter.dev');
      final db = createTestDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider
              .overrideWithValue(MockNotificationService()),
          linkTagsProvider(link.id)
              .overrideWith((ref) => Future.value(<Tag>[])),
          watchLinkTagsProvider(link.id)
              .overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(link: link)),
              ),
              child: const Text('ir al detalle'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('ir al detalle'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Abrir'));
      await tester.tap(find.text('Abrir'));
      await tester.pump();

      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsNothing);
    });

    testWidgets('sin abrir URL, regresar a la app no cierra el detalle',
        (tester) async {
      final link = makeLink(url: 'https://flutter.dev');
      final db = createTestDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider
              .overrideWithValue(MockNotificationService()),
          linkTagsProvider(link.id)
              .overrideWith((ref) => Future.value(<Tag>[])),
          watchLinkTagsProvider(link.id)
              .overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(link: link)),
              ),
              child: const Text('ir al detalle'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('ir al detalle'));
      await tester.pumpAndSettle();

      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });

  group('DetailScreen — gestión de tags', () {
    testWidgets('muestra todos los tags disponibles como FilterChips', (tester) async {
      final allTags = [
        Tag(id: 1, name: 'flutter', color: '#6366F1', createdAt: DateTime.now()),
        Tag(id: 2, name: 'dart', color: '#6366F1', createdAt: DateTime.now()),
      ];
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
        allTags: allTags,
      ));
      await tester.pumpAndSettle();
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('tags del link aparecen seleccionados', (tester) async {
      final tag = Tag(id: 1, name: 'flutter', color: '#6366F1', createdAt: DateTime.now());
      await tester.pumpWidget(buildDetailWidget(
        makeLink(url: 'https://flutter.dev'),
        tags: [tag],
        allTags: [tag],
      ));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'flutter'));
      expect(chip.selected, isTrue);
    });

    testWidgets('tap en tag no seleccionado lo agrega al link en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final tag = Tag(id: tagId, name: 'flutter', color: '#6366F1', createdAt: DateTime.now());

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
          linkTagsProvider(linkId).overrideWith((ref) => Future.value(<Tag>[])),
          watchLinkTagsProvider(linkId).overrideWith((ref) => Stream.value(<Tag>[])),
          allTagsProvider.overrideWith((ref) => Stream.value([tag])),
        ],
        child: MaterialApp(home: DetailScreen(link: makeLink(id: linkId, url: 'https://flutter.dev'))),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('flutter'));
      await tester.pumpAndSettle();

      final tags = await db.getTagsForLink(linkId);
      expect(tags.length, 1);
    });

    testWidgets('tap en tag seleccionado lo quita del link en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final linkId = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));
      final tagId = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      await db.addTagToLink(linkId, tagId);
      final tag = Tag(id: tagId, name: 'flutter', color: '#6366F1', createdAt: DateTime.now());

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
          linkTagsProvider(linkId).overrideWith((ref) => Future.value([tag])),
          watchLinkTagsProvider(linkId).overrideWith((ref) => Stream.value([tag])),
          allTagsProvider.overrideWith((ref) => Stream.value([tag])),
        ],
        child: MaterialApp(home: DetailScreen(link: makeLink(id: linkId, url: 'https://flutter.dev'))),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('flutter'));
      await tester.pumpAndSettle();

      final tags = await db.getTagsForLink(linkId);
      expect(tags, isEmpty);
    });
  });
}
