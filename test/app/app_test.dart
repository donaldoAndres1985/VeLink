import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velink/app/app.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/capture/providers/capture_provider.dart';
import 'package:velink/features/home/providers/home_provider.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/notifications/services/notification_service.dart';
import 'package:velink/features/pending/providers/pending_provider.dart';
import 'package:velink/features/search/providers/search_provider.dart';
import '../helpers/database_helper.dart';
import '../helpers/mock_capture_service.dart';
import '../helpers/mock_metadata_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

class _FakePrefs implements PreferencesService {
  @override
  Locale getLocale() => const Locale('es');
  @override
  Future<void> setLocale(Locale locale) async {}
  @override
  bool getNotificationsEnabled() => true;
  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}
  @override
  ThemeMode getThemeMode() => ThemeMode.light;
  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

void main() {
  late AppDatabase db;
  late MockNotificationService mockService;

  setUp(() {
    db = createTestDatabase();
    mockService = MockNotificationService();
    when(() => mockService.init()).thenAnswer((_) async {});
    when(() => mockService.showFavoriteLinksNotification(
          any(),
          title: any(named: 'title'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp() => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(mockService),
          appStringsProvider.overrideWithValue(AppStrings('es')),
          notificationsEnabledProvider.overrideWith(
            (ref) => NotificationsEnabledNotifier(_FakePrefs(), true),
          ),
          localePrefProvider.overrideWith(
            (ref) => LocaleNotifier(_FakePrefs(), const Locale('es')),
          ),
          themeModeProvider.overrideWith(
            (ref) => ThemeModeNotifier(_FakePrefs(), ThemeMode.light),
          ),
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          recentLinksProvider.overrideWith((_) => Stream.value(const [])),
          filteredHomeLinksProvider.overrideWith((_) => Stream.value(const [])),
          pendingLinksProvider.overrideWith((_) => Stream.value(const [])),
          allTagsProvider.overrideWith((_) => Stream.value(const [])),
          searchResultsProvider.overrideWith((_) async => const []),
        ],
        child: const VerLinkApp(),
      );

  group('MainShell — navegación', () {
    testWidgets('muestra pantalla de inicio por defecto', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      // Home screen shows 'Guardados' as title (in header and navbar)
      expect(find.text('Guardados'), findsAtLeastNWidgets(1));
    });

    testWidgets('tiene 4 tabs en la barra de navegación', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      // 'Guardados' aparece en el header Y en la navbar
      expect(find.text('Guardados'), findsAtLeastNWidgets(1));
      expect(find.text('Revisar'), findsOneWidget);
      expect(find.text('Organizar'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
    });
  });

  group('MainShell — navegación por deslizamiento', () {
    testWidgets('deslizar hacia la izquierda pasa a la pantalla Revisar',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Home screen is active on start
      expect(find.text('Guardados'), findsAtLeastNWidgets(1));

      await tester.fling(
          find.byType(PageView), const Offset(-500, 0), 1500);
      await tester.pumpAndSettle();

      // Pending screen is now shown with its empty state
      expect(find.text('No hay links por revisar'), findsOneWidget);
    });

    testWidgets('tap en tab inferior sincroniza el PageView', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.tap(find.text('Revisar'));
      await tester.pumpAndSettle();

      // Pending screen is now shown with its empty state
      expect(find.text('No hay links por revisar'), findsOneWidget);
    });
  });

  group('MainShell — notificación HU21', () {
    testWidgets('muestra notificación al arrancar si hay links favoritos',
        (tester) async {
      await db.insertLink(LinksCompanion.insert(
        url: 'https://favorito.com',
        priority: const Value(1),
      ));

      await tester.runAsync(() async {
        await tester.pumpWidget(buildApp());
        await Future.delayed(const Duration(milliseconds: 50));
      });

      verify(() => mockService.showFavoriteLinksNotification(
            1,
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).called(1);
    });

    testWidgets('no muestra notificación si no hay links favoritos',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildApp());
        await Future.delayed(const Duration(milliseconds: 50));
      });

      verifyNever(() => mockService.showFavoriteLinksNotification(any()));
    });
  });
}
