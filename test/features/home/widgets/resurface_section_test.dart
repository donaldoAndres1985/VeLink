import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/theme/app_theme.dart';
import 'package:velink/features/home/widgets/resurface_section.dart';
import '../../../helpers/database_helper.dart';
import '../../../helpers/link_factory.dart';

Widget buildResurface(List<Link> links) {
  final db = createTestDatabase();
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      forgottenLinksProvider.overrideWith((ref) => Stream.value(links)),
      appStringsProvider.overrideWithValue(AppStrings('es')),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ResurfaceSection()),
    ),
  );
}

void main() {
  group('ResurfaceSection', () {
    testWidgets('no muestra nada cuando no hay links olvidados', (tester) async {
      await tester.pumpWidget(buildResurface([]));
      await tester.pumpAndSettle();
      expect(find.text('Redescubrir'), findsNothing);
    });

    testWidgets('muestra el título cuando hay links olvidados', (tester) async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      final link = makeLink(url: 'https://old.com', title: 'Viejo link', createdAt: old);
      await tester.pumpWidget(buildResurface([link]));
      await tester.pumpAndSettle();
      expect(find.text('Redescubrir'), findsOneWidget);
    });

    testWidgets('muestra el badge Para ti', (tester) async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      final link = makeLink(url: 'https://old.com', title: 'Link antiguo', createdAt: old);
      await tester.pumpWidget(buildResurface([link]));
      await tester.pumpAndSettle();
      expect(find.text('Para ti'), findsOneWidget);
    });

    testWidgets('muestra el título del link en el carrusel', (tester) async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      final link = makeLink(url: 'https://old.com', title: 'Mi link olvidado', createdAt: old);
      await tester.pumpWidget(buildResurface([link]));
      await tester.pumpAndSettle();
      expect(find.text('Mi link olvidado'), findsOneWidget);
    });

    testWidgets('muestra días transcurridos', (tester) async {
      final old = DateTime.now().subtract(const Duration(days: 10));
      final link = makeLink(url: 'https://old.com', title: 'Link', createdAt: old);
      await tester.pumpWidget(buildResurface([link]));
      await tester.pumpAndSettle();
      expect(find.text('Guardado hace 10 días'), findsOneWidget);
    });
  });
}
