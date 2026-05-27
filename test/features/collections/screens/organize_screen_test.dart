import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/collections/providers/collection_providers.dart';
import 'package:velink/features/collections/screens/organize_screen.dart';
import '../../../helpers/database_helper.dart';

class _FakePrefs implements PreferencesService {
  @override bool isPremium() => true;
  @override Future<void> setPremium(bool v) async {}
  @override Locale getLocale() => const Locale('es');
  @override Future<void> setLocale(Locale l) async {}
  @override bool getNotificationsEnabled() => true;
  @override Future<void> setNotificationsEnabled(bool e) async {}
  @override ThemeMode getThemeMode() => ThemeMode.light;
  @override Future<void> setThemeMode(ThemeMode m) async {}
  @override int getStreak() => 0;
  @override Future<void> setStreak(int c) async {}
  @override String? getStreakLastDate() => null;
  @override Future<void> setStreakLastDate(String d) async {}
}

Widget buildOrganizeWidget() {
  final db = createTestDatabase();
  final prefs = _FakePrefs();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      preferencesServiceProvider.overrideWithValue(prefs),
      premiumProvider.overrideWith((ref) => PremiumNotifier(prefs)),
      allCollectionsProvider.overrideWith((ref) => Stream.value([])),
      allTagsProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: const MaterialApp(home: OrganizeScreen()),
  );
}

void main() {
  group('OrganizeScreen — estructura', () {
    testWidgets('muestra título Organizar', (tester) async {
      await tester.pumpWidget(buildOrganizeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Organizar'), findsOneWidget);
    });

    testWidgets('muestra pestaña Colecciones', (tester) async {
      await tester.pumpWidget(buildOrganizeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Colecciones'), findsOneWidget);
    });

    testWidgets('muestra pestaña Etiquetas', (tester) async {
      await tester.pumpWidget(buildOrganizeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Etiquetas'), findsOneWidget);
    });

    testWidgets('muestra título Organizar en el header', (tester) async {
      await tester.pumpWidget(buildOrganizeWidget());
      await tester.pumpAndSettle();
      expect(find.text('Organizar'), findsOneWidget);
    });
  });

  group('OrganizeScreen — navegación entre tabs', () {
    testWidgets('tab Colecciones está activo por defecto', (tester) async {
      await tester.pumpWidget(buildOrganizeWidget());
      await tester.pumpAndSettle();
      expect(find.text('No hay colecciones aún'), findsOneWidget);
    });

    testWidgets('al tocar tab Etiquetas muestra contenido de etiquetas', (tester) async {
      await tester.pumpWidget(buildOrganizeWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Etiquetas'));
      await tester.pumpAndSettle();
      expect(find.text('No hay etiquetas aún'), findsOneWidget);
    });
  });
}
