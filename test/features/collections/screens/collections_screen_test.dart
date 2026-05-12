import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/features/collections/providers/collection_providers.dart';
import 'package:velink/features/collections/screens/collections_screen.dart';
import '../../../helpers/database_helper.dart';

Widget buildCollectionsWidget({List<Collection> collections = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      allCollectionsProvider.overrideWith((ref) => Stream.value(collections)),
    ],
    child: const MaterialApp(home: Scaffold(body: CollectionsContent())),
  );
}

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

void main() {
  group('CollectionsContent — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay colecciones', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay colecciones aún'), findsOneWidget);
    });

    testWidgets('muestra descripción cuando no hay colecciones', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget());
      await tester.pumpAndSettle();
      expect(find.text('Crea colecciones para agrupar tus links.'), findsOneWidget);
    });
  });

  group('CollectionsContent — lista', () {
    testWidgets('muestra nombre de colección', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'Flutter Dev')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Dev'), findsOneWidget);
    });

    testWidgets('muestra múltiples colecciones', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [
          makeCollection(id: 1, name: 'Flutter'),
          makeCollection(id: 2, name: 'Android'),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);
    });

    testWidgets('muestra botón de editar por colección', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'Dev')],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('muestra botón de eliminar por colección', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'Dev')],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('CollectionsContent — eliminar colección', () {
    testWidgets('tapping eliminar muestra diálogo de confirmación', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'Dev')],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar colección'), findsOneWidget);
    });

    testWidgets('diálogo de confirmación muestra nombre de colección', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'MiColección')],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('MiColección'), findsWidgets);
    });

    testWidgets('diálogo menciona que links no serán eliminados', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'Dev')],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('no serán eliminados'), findsOneWidget);
    });

    testWidgets('cancelar cierra el diálogo', (tester) async {
      await tester.pumpWidget(buildCollectionsWidget(
        collections: [makeCollection(name: 'Dev')],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar colección'), findsNothing);
    });
  });
}
