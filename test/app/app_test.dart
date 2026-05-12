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
          captureServiceProvider.overrideWithValue(MockCaptureService()),
          metadataServiceProvider.overrideWithValue(MockMetadataService()),
          recentLinksProvider.overrideWith((_) => Stream.value(const [])),
          filteredHomeLinksProvider.overrideWith((_) => Stream.value(const [])),
          pendingLinksProvider.overrideWith((_) => Stream.value(const [])),
          allTagsProvider.overrideWith((_) => Stream.value(const [])),
          searchResultsProvider.overrideWith((_) async => const []),
        ],
        child: const VeLinkApp(),
      );

  group('MainShell — navegación', () {
    testWidgets('muestra pantalla de inicio por defecto', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.text('VeLink'), findsOneWidget);
    });

    testWidgets('tiene 4 tabs en la barra de navegación', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final bar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(bar.items.length, 4);
    });
  });

  group('MainShell — navegación por deslizamiento', () {
    testWidgets('deslizar hacia la izquierda pasa a la pantalla Pendientes',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      final barBefore = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(barBefore.currentIndex, 0);

      await tester.fling(
          find.byType(PageView), const Offset(-500, 0), 1500);
      await tester.pumpAndSettle();

      final barAfter = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(barAfter.currentIndex, 1);
    });

    testWidgets('tap en tab inferior sincroniza el PageView', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.tap(find.text('Pendientes'));
      await tester.pumpAndSettle();

      final bar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(bar.currentIndex, 1);
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
