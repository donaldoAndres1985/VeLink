import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/notifications/services/notification_service.dart';
import '../../helpers/database_helper.dart';

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
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    mockService = MockNotificationService();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(mockService),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      notificationsEnabledProvider.overrideWith(
        (ref) => NotificationsEnabledNotifier(_FakePrefs(), true),
      ),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('notifyFavoriteLinksProvider', () {
    test('llama showFavoriteLinksNotification cuando hay links favoritos', () async {
      when(() => mockService.showFavoriteLinksNotification(
            any(),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      await db.insertLink(LinksCompanion.insert(
        url: 'https://ejemplo.com',
        priority: const Value(1),
      ));

      await container.read(notifyFavoriteLinksProvider.future);

      verify(() => mockService.showFavoriteLinksNotification(
            1,
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('no llama showFavoriteLinksNotification cuando no hay links favoritos',
        () async {
      when(() => mockService.showFavoriteLinksNotification(
            any(),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      await container.read(notifyFavoriteLinksProvider.future);

      verifyNever(() => mockService.showFavoriteLinksNotification(any()));
    });

    test('no llama showFavoriteLinksNotification cuando notificaciones desactivadas',
        () async {
      final disabledContainer = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(mockService),
        appStringsProvider.overrideWithValue(AppStrings('es')),
        notificationsEnabledProvider.overrideWith(
          (ref) => NotificationsEnabledNotifier(_FakePrefs(), false),
        ),
      ]);

      await db.insertLink(LinksCompanion.insert(
        url: 'https://ejemplo.com',
        priority: const Value(1),
      ));

      await disabledContainer.read(notifyFavoriteLinksProvider.future);

      verifyNever(() => mockService.showFavoriteLinksNotification(any()));
      disabledContainer.dispose();
    });
  });

  group('LinkReminderUseCase', () {
    final scheduledAt = DateTime(2026, 7, 1, 9, 0);

    test('schedule: agenda notificación y guarda remindAt en la DB', () async {
      when(() => mockService.scheduleLinkReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledAt: any(named: 'scheduledAt'),
          )).thenAnswer((_) async {});

      final linkId = await db.insertLink(LinksCompanion.insert(
        url: 'https://ejemplo.com',
        title: const Value('Mi link'),
      ));

      final useCase = container.read(linkReminderUseCaseProvider);
      await useCase.schedule(
          linkId: linkId, title: 'Mi link', scheduledAt: scheduledAt);

      verify(() => mockService.scheduleLinkReminder(
            id: linkId,
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledAt: scheduledAt,
          )).called(1);

      final links = await db.getAllLinks();
      expect(links.first.remindAt, scheduledAt);
    });

    test('cancel: cancela notificación y borra remindAt de la DB', () async {
      when(() => mockService.cancelReminder(any())).thenAnswer((_) async {});

      final linkId = await db.insertLink(LinksCompanion.insert(
        url: 'https://ejemplo.com',
        remindAt: Value(DateTime(2026, 7, 1)),
      ));

      final useCase = container.read(linkReminderUseCaseProvider);
      await useCase.cancel(linkId: linkId);

      verify(() => mockService.cancelReminder(linkId)).called(1);

      final links = await db.getAllLinks();
      expect(links.first.remindAt, null);
    });
  });
}
