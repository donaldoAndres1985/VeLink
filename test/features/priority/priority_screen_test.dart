import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/priority/providers/priority_provider.dart';
import 'package:velink/features/priority/screens/priority_screen.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildPriorityWidget({List<Link> links = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      priorityLinksProvider.overrideWith((ref) => Stream.value(links)),
    ],
    child: const MaterialApp(home: PriorityScreen()),
  );
}

void main() {
  group('PriorityScreen — app bar', () {
    testWidgets('muestra Prioritarios en el app bar', (tester) async {
      await tester.pumpWidget(buildPriorityWidget());
      await tester.pumpAndSettle();
      expect(find.text('Prioritarios'), findsOneWidget);
    });
  });

  group('PriorityScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay links prioritarios', (tester) async {
      await tester.pumpWidget(buildPriorityWidget());
      await tester.pumpAndSettle();
      expect(find.text('No tienes links prioritarios'), findsOneWidget);
    });
  });

  group('PriorityScreen — lista de prioritarios', () {
    testWidgets('muestra la URL de cada link prioritario', (tester) async {
      await tester.pumpWidget(buildPriorityWidget(
        links: [makeLink(url: 'https://flutter.dev', priority: 1)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('muestra el título cuando está disponible', (tester) async {
      await tester.pumpWidget(buildPriorityWidget(
        links: [makeLink(url: 'https://flutter.dev', title: 'Flutter', priority: 1)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('muestra múltiples links prioritarios', (tester) async {
      await tester.pumpWidget(buildPriorityWidget(links: [
        makeLink(url: 'https://flutter.dev', priority: 1, id: 1),
        makeLink(url: 'https://dart.dev', priority: 1, id: 2),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
      expect(find.text('https://dart.dev'), findsOneWidget);
    });

    testWidgets('muestra icono de estrella para indicar prioridad', (tester) async {
      await tester.pumpWidget(buildPriorityWidget(
        links: [makeLink(url: 'https://flutter.dev', priority: 1)],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('muestra el badge de plataforma', (tester) async {
      await tester.pumpWidget(buildPriorityWidget(
        links: [makeLink(url: 'https://youtube.com/watch?v=abc', platform: 'youtube', priority: 1)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });
  });
}
