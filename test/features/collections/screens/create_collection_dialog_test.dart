import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/features/collections/screens/create_collection_dialog.dart';
import 'package:velink/features/premium/domain/premium_limits.dart';
import '../../../helpers/database_helper.dart';

Widget buildDialog({Collection? existing, AppDatabase? db}) {
  final database = db ?? createTestDatabase();
  addTearDown(database.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      canCreateCollectionProvider.overrideWith((ref) => Future.value(true)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => CreateCollectionDialog(existing: existing),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CreateCollectionDialog — estructura', () {
    testWidgets('muestra título Nueva colección cuando no hay existente', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Nueva colección'), findsOneWidget);
    });

    testWidgets('muestra título Editar colección cuando hay existente', (tester) async {
      final col = Collection(
        id: 1,
        name: 'Flutter',
        color: '#6366F1',
        icon: 'folder',
        description: null,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      await tester.pumpWidget(buildDialog(existing: col));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Editar colección'), findsOneWidget);
    });

    testWidgets('muestra campo de nombre', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('muestra botón Guardar', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Guardar'), findsOneWidget);
    });
  });

  group('CreateCollectionDialog — validación', () {
    testWidgets('no guarda si el nombre está vacío', (tester) async {
      final db = createTestDatabase();
      await tester.pumpWidget(buildDialog(db: db));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final cols = await db.getAllCollections();
      expect(cols, isEmpty);
      await db.close();
    });

    testWidgets('muestra error si nombre está vacío', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
    });

    testWidgets('muestra error de nombre duplicado', (tester) async {
      final db = createTestDatabase();
      await db.insertCollection(CollectionsCompanion.insert(name: 'Flutter'));
      await tester.pumpWidget(buildDialog(db: db));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Flutter');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una colección con ese nombre'), findsOneWidget);
      await db.close();
    });
  });

  group('CreateCollectionDialog — guardar', () {
    testWidgets('guarda colección con nombre válido', (tester) async {
      final db = createTestDatabase();
      await tester.pumpWidget(buildDialog(db: db));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Mi Colección');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final cols = await db.getAllCollections();
      expect(cols.length, 1);
      expect(cols.first.name, 'Mi Colección');
      await db.close();
    });

    testWidgets('cierra el diálogo al guardar exitosamente', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Nueva');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Nueva colección'), findsNothing);
    });
  });

  group('CreateCollectionDialog — editar', () {
    testWidgets('pre-rellena el nombre existente', (tester) async {
      final col = Collection(
        id: 1,
        name: 'Flutter',
        color: '#6366F1',
        icon: 'folder',
        description: null,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      await tester.pumpWidget(buildDialog(existing: col));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Flutter'), findsWidgets);
    });
  });
}
