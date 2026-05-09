import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/tags/screens/create_tag_dialog.dart';
import '../../../helpers/database_helper.dart';

Widget buildCreateTagWidget({AppDatabase? database}) {
  final db = database ?? createTestDatabase();
  if (database == null) addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
    ],
    child: const MaterialApp(home: Scaffold(body: CreateTagDialog())),
  );
}

void main() {
  group('CreateTagDialog — campos', () {
    testWidgets('muestra campo de texto para el nombre del tag', (tester) async {
      await tester.pumpWidget(buildCreateTagWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('muestra chips de colores predefinidos', (tester) async {
      await tester.pumpWidget(buildCreateTagWidget());
      await tester.pumpAndSettle();
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('muestra botón Guardar', (tester) async {
      await tester.pumpWidget(buildCreateTagWidget());
      await tester.pumpAndSettle();
      expect(find.text('Guardar'), findsOneWidget);
    });
  });

  group('CreateTagDialog — guardar', () {
    testWidgets('crear tag guarda el nombre en la DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(buildCreateTagWidget(database: db));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.tap(find.text('Guardar'));
      await tester.pump();

      final tags = await db.getAllTags();
      expect(tags.length, 1);
      expect(tags.first.name, 'flutter');
    });

    testWidgets('no crea tag si el nombre está vacío', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(buildCreateTagWidget(database: db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pump();

      final tags = await db.getAllTags();
      expect(tags, isEmpty);
    });
  });
}
