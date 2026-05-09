import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

final notifyPriorityLinksProvider = FutureProvider<void>((ref) async {
  final db = ref.read(databaseProvider);
  final service = ref.read(notificationServiceProvider);
  final priorityLinks = await db.getPriorityLinks();
  if (priorityLinks.isNotEmpty) {
    await service.showPriorityLinksNotification(priorityLinks.length);
  }
});

class LinkReminderUseCase {
  final AppDatabase _db;
  final NotificationService _service;

  LinkReminderUseCase(this._db, this._service);

  Future<void> schedule({
    required int linkId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    await _db.setLinkReminder(linkId, scheduledAt);
    await _service.scheduleLinkReminder(
      id: linkId,
      title: title,
      scheduledAt: scheduledAt,
    );
  }

  Future<void> cancel({required int linkId}) async {
    await _db.setLinkReminder(linkId, null);
    await _service.cancelReminder(linkId);
  }
}

final linkReminderUseCaseProvider = Provider<LinkReminderUseCase>((ref) {
  return LinkReminderUseCase(
    ref.read(databaseProvider),
    ref.read(notificationServiceProvider),
  );
});
