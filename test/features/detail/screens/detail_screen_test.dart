import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/detail/providers/detail_provider.dart';
import 'package:velink/features/detail/screens/detail_screen.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/link_factory.dart';

Widget buildDetailWidget(Link link, {List<Tag> tags = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      linkTagsProvider(link.id).overrideWith((ref) => Future.value(tags)),
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
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('guardar nota llama updateLinkNotes en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final id = await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          linkTagsProvider(id).overrideWith((ref) => Future.value(<Tag>[])),
        ],
        child: MaterialApp(home: DetailScreen(link: makeLink(id: id, url: 'https://flutter.dev'))),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Nueva nota');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

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
}
