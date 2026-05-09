import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/tags/screens/tags_screen.dart';
import '../../../helpers/database_helper.dart';

Widget buildTagsWidget({List<Tag> tags = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      allTagsProvider.overrideWith((ref) => Stream.value(tags)),
    ],
    child: const MaterialApp(home: TagsScreen()),
  );
}

void main() {
  group('TagsScreen — app bar', () {
    testWidgets('muestra título Etiquetas en el app bar', (tester) async {
      await tester.pumpWidget(buildTagsWidget());
      await tester.pumpAndSettle();
      expect(find.text('Etiquetas'), findsOneWidget);
    });
  });

  group('TagsScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay tags', (tester) async {
      await tester.pumpWidget(buildTagsWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay etiquetas aún'), findsOneWidget);
    });
  });

  group('TagsScreen — listado', () {
    testWidgets('muestra el nombre de cada tag', (tester) async {
      final tags = [
        Tag(id: 1, name: 'flutter', color: '#6366F1', createdAt: DateTime.now()),
        Tag(id: 2, name: 'dart', color: '#EF4444', createdAt: DateTime.now()),
      ];
      await tester.pumpWidget(buildTagsWidget(tags: tags));
      await tester.pumpAndSettle();
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('muestra botón de eliminar por cada tag', (tester) async {
      final tags = [
        Tag(id: 1, name: 'flutter', color: '#6366F1', createdAt: DateTime.now()),
      ];
      await tester.pumpWidget(buildTagsWidget(tags: tags));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('TagsScreen — eliminar', () {
    testWidgets('tap en eliminar borra el tag de la DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertTag(TagsCompanion.insert(name: 'flutter'));
      final tag = Tag(id: id, name: 'flutter', color: '#6366F1', createdAt: DateTime.now());

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          allTagsProvider.overrideWith((ref) => Stream.value([tag])),
        ],
        child: const MaterialApp(home: TagsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      final tags = await db.getAllTags();
      expect(tags, isEmpty);
    });
  });

  group('TagsScreen — crear tag', () {
    testWidgets('muestra FAB para crear nuevo tag', (tester) async {
      await tester.pumpWidget(buildTagsWidget());
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
