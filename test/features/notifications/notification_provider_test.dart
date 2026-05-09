import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/notifications/services/notification_service.dart';
import '../../helpers/database_helper.dart';

class MockNotificationService extends Mock implements NotificationService {}

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
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('notifyPriorityLinksIfAny', () {
    test('llama showPriorityLinksNotification cuando hay links prioritarios', () async {
      when(() => mockService.showPriorityLinksNotification(any()))
          .thenAnswer((_) async {});

      await db.insertLink(LinksCompanion.insert(
        url: 'https://ejemplo.com',
        priority: const Value(1),
      ));

      await container.read(notifyPriorityLinksProvider.future);

      verify(() => mockService.showPriorityLinksNotification(1)).called(1);
    });

    test('no llama showPriorityLinksNotification cuando no hay links prioritarios',
        () async {
      when(() => mockService.showPriorityLinksNotification(any()))
          .thenAnswer((_) async {});

      await container.read(notifyPriorityLinksProvider.future);

      verifyNever(() => mockService.showPriorityLinksNotification(any()));
    });
  });

  group('LinkReminderUseCase', () {
    final scheduledAt = DateTime(2026, 7, 1, 9, 0);

    test('schedule: agenda notificación y guarda remindAt en la DB', () async {
      when(() => mockService.scheduleLinkReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
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
            title: 'Mi link',
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
