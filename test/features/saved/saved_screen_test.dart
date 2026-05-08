import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/saved/providers/saved_provider.dart';
import 'package:velink/features/saved/screens/saved_screen.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';
import '../../helpers/mock_capture_service.dart';
import '../../helpers/mock_metadata_service.dart';

Widget buildSavedWidget({List<Link> links = const [], List<Tag> tags = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      captureServiceProvider.overrideWithValue(MockCaptureService()),
      metadataServiceProvider.overrideWithValue(MockMetadataService()),
      filteredSavedLinksProvider.overrideWith((ref) => Stream.value(links)),
      allTagsProvider.overrideWith((ref) => Stream.value(tags)),
    ],
    child: const MaterialApp(home: SavedScreen()),
  );
}

void main() {
  group('SavedScreen — app bar', () {
    testWidgets('muestra Guardados en el app bar', (tester) async {
      await tester.pumpWidget(buildSavedWidget());
      await tester.pumpAndSettle();
      expect(find.text('Guardados'), findsOneWidget);
    });
  });

  group('SavedScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay links guardados', (tester) async {
      await tester.pumpWidget(buildSavedWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay links guardados aún'), findsOneWidget);
    });
  });

  group('SavedScreen — listado completo', () {
    testWidgets('muestra la URL de cada link', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        links: [makeLink(url: 'https://flutter.dev')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('muestra el título cuando está disponible', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        links: [makeLink(url: 'https://flutter.dev', title: 'Flutter Framework')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Framework'), findsOneWidget);
    });

    testWidgets('muestra múltiples links', (tester) async {
      await tester.pumpWidget(buildSavedWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1),
        makeLink(url: 'https://dart.dev', id: 2),
        makeLink(url: 'https://pub.dev', id: 3),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
      expect(find.text('https://dart.dev'), findsOneWidget);
      expect(find.text('https://pub.dev'), findsOneWidget);
    });

    testWidgets('muestra el badge de plataforma de cada link', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        links: [makeLink(url: 'https://github.com/flutter', platform: 'github')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('muestra placeholder cuando no hay imagen de preview', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        links: [makeLink(url: 'https://example.com')],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsWidgets);
    });
  });

  group('SavedScreen — filtrado por tag', () {
    testWidgets('muestra chips de los tags disponibles', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        tags: [
          Tag(id: 1, name: 'flutter', color: '#000000', createdAt: DateTime.now()),
          Tag(id: 2, name: 'dart', color: '#000000', createdAt: DateTime.now()),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('chip no seleccionado está inactivo por defecto', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        tags: [Tag(id: 1, name: 'flutter', color: '#000000', createdAt: DateTime.now())],
      ));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(find.byType(FilterChip).first);
      expect(chip.selected, isFalse);
    });

    testWidgets('tap en chip lo marca como seleccionado', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        tags: [Tag(id: 1, name: 'flutter', color: '#000000', createdAt: DateTime.now())],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('flutter'));
      await tester.pump();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip).first);
      expect(chip.selected, isTrue);
    });

    testWidgets('tap en chip seleccionado lo deselecciona', (tester) async {
      await tester.pumpWidget(buildSavedWidget(
        tags: [Tag(id: 1, name: 'flutter', color: '#000000', createdAt: DateTime.now())],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('flutter'));
      await tester.pump();
      await tester.tap(find.text('flutter'));
      await tester.pump();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip).first);
      expect(chip.selected, isFalse);
    });
  });
}
