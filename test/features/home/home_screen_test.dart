import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/features/home/providers/home_provider.dart';
import 'package:velink/features/home/screens/home_screen.dart';
import 'package:velink/features/search/providers/search_provider.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildHomeWidget({List<Link> links = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      filteredHomeLinksProvider.overrideWith((ref) => Stream.value(links)),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  group('HomeScreen — app bar', () {
    testWidgets('muestra VeLink en el app bar', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.text('VeLink'), findsOneWidget);
    });
  });

  group('HomeScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay links guardados', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay links guardados aún'), findsOneWidget);
    });
  });

  group('HomeScreen — FAB', () {
    testWidgets('muestra FloatingActionButton para agregar link', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB muestra diálogo al tocar', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Agregar link'), findsOneWidget);
    });
  });

  group('HomeScreen — filtros', () {
    testWidgets('muestra botón Todos', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('muestra botón Favoritos', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Favoritos'), findsOneWidget);
    });

    testWidgets('muestra botón Filtrar', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Filtrar'), findsOneWidget);
    });

    testWidgets('los tres botones están distribuidos horizontalmente', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      final todosPos = tester.getCenter(find.text('Todos'));
      final favoritosPos = tester.getCenter(find.text('Favoritos'));
      final filtrarPos = tester.getCenter(find.text('Filtrar'));
      // Todos debe estar a la izquierda de Favoritos, y este a la izquierda de Filtrar
      expect(todosPos.dx, lessThan(favoritosPos.dx));
      expect(favoritosPos.dx, lessThan(filtrarPos.dx));
    });
  });

  group('HomeScreen — lista de links recientes', () {
    testWidgets('muestra la URL de cada link', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://flutter.dev')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsWidgets);
    });

    testWidgets('muestra el título cuando está disponible', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://flutter.dev', title: 'Flutter Framework')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Framework'), findsOneWidget);
    });

    testWidgets('muestra múltiples links', (tester) async {
      await tester.pumpWidget(buildHomeWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1),
        makeLink(url: 'https://dart.dev', id: 2),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsWidgets);
    });

    testWidgets('muestra el badge de plataforma de cada link', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://youtube.com/watch?v=abc', platform: 'youtube')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsWidgets);
    });

    testWidgets('muestra placeholder cuando no hay imagen de preview', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://example.com')],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsWidgets);
    });
  });

  group('HomeScreen — filtros limpian búsqueda', () {
    testWidgets('tap en Todos limpia el texto del campo de búsqueda', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pump();

      await tester.tap(find.text('Todos'));
      await tester.pump();

      final editableText = tester.firstWidget<EditableText>(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.controller.text, isEmpty);
    });
  });

  group('HomeScreen — padding de lista', () {
    testWidgets('lista tiene padding inferior correcto para FAB y barra de navegación', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://flutter.dev', id: 1)],
      ));
      await tester.pumpAndSettle();
      final listView = tester.widget<ListView>(find.byType(ListView).first);
      expect((listView.padding as EdgeInsets).bottom, kBottomNavigationBarHeight + 56.0 + 24.0);
    });
  });

  group('HomeScreen — búsqueda', () {
    testWidgets('muestra campo de búsqueda', (tester) async {
      await tester.pumpWidget(buildHomeWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filtra links al escribir en búsqueda', (tester) async {
      final link1 = makeLink(url: 'https://flutter.dev', id: 1);
      final link2 = makeLink(url: 'https://dart.dev', id: 2);
      final db = createTestDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          filteredHomeLinksProvider.overrideWith((_) => Stream.value([link1, link2])),
          searchResultsProvider.overrideWith((_) async => [link1]),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pumpAndSettle();

      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsNothing);
    });
  });
}
