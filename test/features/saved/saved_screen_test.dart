import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/saved/providers/saved_provider.dart';
import 'package:velink/features/saved/screens/saved_screen.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildSavedWidget({List<Link> links = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      savedLinksProvider.overrideWith((ref) => Stream.value(links)),
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
}
