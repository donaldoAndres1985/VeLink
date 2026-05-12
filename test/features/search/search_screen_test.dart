import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/detail/providers/detail_provider.dart';
import 'package:velink/features/search/providers/search_provider.dart';
import 'package:velink/features/search/screens/search_screen.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildSearchWidget({List<Link> results = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      searchResultsProvider.overrideWith((ref) => Future.value(results)),
      allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
    ],
    child: const MaterialApp(home: SearchScreen()),
  );
}

void main() {
  group('SearchScreen — app bar', () {
    testWidgets('muestra Buscar en el app bar', (tester) async {
      await tester.pumpWidget(buildSearchWidget());
      await tester.pumpAndSettle();
      expect(find.text('Buscar'), findsOneWidget);
    });
  });

  group('SearchScreen — campo de búsqueda', () {
    testWidgets('muestra un TextField para la búsqueda', (tester) async {
      await tester.pumpWidget(buildSearchWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('muestra placeholder en el campo de búsqueda', (tester) async {
      await tester.pumpWidget(buildSearchWidget());
      await tester.pumpAndSettle();
      expect(find.text('Buscar links...'), findsOneWidget);
    });
  });

  group('SearchScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando la búsqueda está vacía', (tester) async {
      await tester.pumpWidget(buildSearchWidget());
      await tester.pumpAndSettle();
      expect(find.text('Escribe para buscar'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay resultados', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          searchResultsProvider.overrideWith((ref) => Future.value(<Link>[])),
          searchQueryProvider.overrideWith((ref) => 'kotlin'),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Sin resultados'), findsOneWidget);
    });
  });

  group('SearchScreen — resultados', () {
    testWidgets('muestra LinkCard por cada resultado', (tester) async {
      final links = [
        makeLink(url: 'https://flutter.dev', title: 'Flutter', id: 1),
        makeLink(url: 'https://dart.dev', title: 'Dart', id: 2),
      ];
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          searchResultsProvider.overrideWith((ref) => Future.value(links)),
          searchQueryProvider.overrideWith((ref) => 'flutter'),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
          watchLinkTagsProvider(1).overrideWith((ref) => Stream.value(<Tag>[])),
          watchLinkTagsProvider(2).overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsOneWidget);
      expect(find.text('dart.dev'), findsOneWidget);
    });

    testWidgets('muestra el título de cada resultado', (tester) async {
      final links = [makeLink(url: 'https://flutter.dev', title: 'Flutter Docs', id: 1)];
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          searchResultsProvider.overrideWith((ref) => Future.value(links)),
          searchQueryProvider.overrideWith((ref) => 'flutter'),
          allTagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
          watchLinkTagsProvider(1).overrideWith((ref) => Stream.value(<Tag>[])),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Docs'), findsOneWidget);
    });
  });
}
