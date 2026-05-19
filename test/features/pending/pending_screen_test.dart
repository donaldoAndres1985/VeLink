import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
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
      appStringsProvider.overrideWithValue(AppStrings('es')),
      pendingLinksProvider.overrideWith((ref) => Stream.value(links)),
    ],
    child: const MaterialApp(home: PendientesScreen()),
  );
}

void main() {
  group('PendientesScreen — app bar', () {
    testWidgets('muestra título Revisar en el header', (tester) async {
      await tester.pumpWidget(buildPendingWidget());
      await tester.pumpAndSettle();
      expect(find.text('Revisar'), findsOneWidget);
    });
  });

  group('PendientesScreen — estado vacío', () {
    testWidgets('muestra mensaje cuando no hay links por revisar', (tester) async {
      await tester.pumpWidget(buildPendingWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay links por revisar'), findsOneWidget);
    });
  });

  group('PendientesScreen — búsqueda', () {
    testWidgets('muestra campo de búsqueda', (tester) async {
      await tester.pumpWidget(buildPendingWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filtra links al escribir en búsqueda', (tester) async {
      await tester.pumpWidget(buildPendingWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1, isRead: false),
        makeLink(url: 'https://dart.dev', id: 2, isRead: false),
      ]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pumpAndSettle();

      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsNothing);
    });

    testWidgets('muestra todos los links cuando búsqueda está vacía', (tester) async {
      await tester.pumpWidget(buildPendingWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1, isRead: false),
        makeLink(url: 'https://dart.dev', id: 2, isRead: false),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsWidgets);
    });
  });

  group('PendientesScreen — lista', () {
    testWidgets('muestra links pendientes', (tester) async {
      await tester.pumpWidget(buildPendingWidget(
        links: [makeLink(url: 'https://flutter.dev', isRead: false)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsWidgets);
    });

    testWidgets('muestra múltiples links pendientes', (tester) async {
      await tester.pumpWidget(buildPendingWidget(links: [
        makeLink(url: 'https://flutter.dev', id: 1, isRead: false),
        makeLink(url: 'https://dart.dev', id: 2, isRead: false),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('flutter.dev'), findsWidgets);
      expect(find.text('dart.dev'), findsWidgets);
    });

    testWidgets('no muestra botón independiente Marcar revisado bajo la card', (tester) async {
      await tester.pumpWidget(buildPendingWidget(
        links: [makeLink(url: 'https://flutter.dev', isRead: false)],
      ));
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('PendientesScreen — marcar revisado por menú', () {
    testWidgets('no hay Dismissible en la lista de pendientes', (tester) async {
      await tester.pumpWidget(buildPendingWidget(
        links: [makeLink(url: 'https://flutter.dev', isRead: false)],
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('marcar revisado por menú actualiza isRead=true en DB', (tester) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          pendingLinksProvider.overrideWith((ref) => db.watchPendingLinks()),
        ],
        child: const MaterialApp(home: PendientesScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar revisado'));
      await tester.pumpAndSettle();

      final links = await db.getAllLinks();
      expect(links.first.isRead, true);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('muestra snackbar tras marcar revisado por menú', (tester) async {
      final link = makeLink(url: 'https://flutter.dev', isRead: false);
      final db = createTestDatabase();
      addTearDown(db.close);
      await db.insertLink(LinksCompanion.insert(url: 'https://flutter.dev'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          pendingLinksProvider.overrideWith((ref) => Stream.value([link])),
        ],
        child: const MaterialApp(home: PendientesScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar revisado'));
      await tester.pumpAndSettle();

      expect(find.text('Link marcado como revisado'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
