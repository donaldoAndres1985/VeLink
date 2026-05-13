import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

final notifyFavoriteLinksProvider = FutureProvider<void>((ref) async {
  final enabled = ref.read(notificationsEnabledProvider);
  if (!enabled) return;

  final db = ref.read(databaseProvider);
  final service = ref.read(notificationServiceProvider);
  final s = ref.read(appStringsProvider);
  final favoriteLinks = await db.getPriorityLinks();
  if (favoriteLinks.isNotEmpty) {
    await service.showFavoriteLinksNotification(
      favoriteLinks.length,
      title: s.notifFavoritesTitle,
      body: s.notifFavoritesBody(favoriteLinks.length),
    );
  }
});

class LinkReminderUseCase {
  final AppDatabase _db;
  final NotificationService _service;
  final String Function(String) _buildTitle;
  final String _reminderBody;

  LinkReminderUseCase({
    required AppDatabase db,
    required NotificationService service,
    required String Function(String) buildTitle,
    required String reminderBody,
  })  : _db = db,
        _service = service,
        _buildTitle = buildTitle,
        _reminderBody = reminderBody;

  Future<void> schedule({
    required int linkId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    await _db.setLinkReminder(linkId, scheduledAt);
    await _service.scheduleLinkReminder(
      id: linkId,
      title: _buildTitle(title),
      body: _reminderBody,
      scheduledAt: scheduledAt,
    );
  }

  Future<void> cancel({required int linkId}) async {
    await _db.setLinkReminder(linkId, null);
    await _service.cancelReminder(linkId);
  }
}

final notifPermissionProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.read(notificationServiceProvider).isPermissionGranted();
});

final linkReminderUseCaseProvider = Provider<LinkReminderUseCase>((ref) {
  final s = ref.read(appStringsProvider);
  return LinkReminderUseCase(
    db: ref.read(databaseProvider),
    service: ref.read(notificationServiceProvider),
    buildTitle: s.notifReminderTitle,
    reminderBody: s.notifReminderBody,
  );
});
