import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/pending/providers/pending_provider.dart';
import 'package:velink/features/pending/screens/pending_screen.dart';
import '../../helpers/database_helper.dart';
import '../../helpers/link_factory.dart';

Widget buildPendingWidget({List<Link> links = const []}) {
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      pendingLinksProvider.overrideWith((ref) => Stream.value(links)),
    ],
    child: const MaterialApp(home: PendientesScreen()),
  );
}

void main() {
  group('PendientesScreen — app bar', () {
    testWidgets('muestra título Pendientes en el app bar', (tester) async {
      await tester.pumpWidget(buildPendingWidget());
      await tester.pumpAndSettle();
      expect(find.text('Pendientes'), findsOneWidget);
    });
  });

  group('PendientesScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay links pendientes', (tester) async {
      await tester.pumpWidget(buildPendingWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay links pendientes'), findsOneWidget);
    });
  });

  group('PendientesScreen — lista', () {
    testWidgets('muestra links pendientes', (tester) async {
      await tester.pumpWidget(buildPendingWidget(
        links: [makeLink(url: 'https://flutter.dev', isRead: false)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('muestra múltiples links pendientes', (tester) async {
      await tester.pumpWidget(buildPendingWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1, isRead: false),
        makeLink(url: 'https://dart.dev', id: 2, isRead: false),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('https://flutter.dev'), findsOneWidget);
      expect(find.text('https://dart.dev'), findsOneWidget);
    });
  });
}
