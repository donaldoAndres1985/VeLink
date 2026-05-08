import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/home/providers/home_provider.dart';
import 'package:velink/features/home/screens/home_screen.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildHomeWidget({List<Link> links = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      recentLinksProvider.overrideWith((ref) => Stream.value(links)),
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

  group('HomeScreen — lista de links recientes', () {
    testWidgets('muestra la URL de cada link', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://flutter.dev')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
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
      expect(find.text('https://flutter.dev'), findsOneWidget);
      expect(find.text('https://dart.dev'), findsOneWidget);
    });

    testWidgets('muestra el badge de plataforma de cada link', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://youtube.com/watch?v=abc', platform: 'youtube')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('muestra placeholder cuando no hay imagen de preview', (tester) async {
      await tester.pumpWidget(buildHomeWidget(
        links: [makeLink(url: 'https://example.com')],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsWidgets);
    });
  });
}
