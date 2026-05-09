import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class NotificationService {
  Future<void> init();
  Future<void> showPriorityLinksNotification(int count);
  Future<void> scheduleLinkReminder({
    required int id,
    required String title,
    required DateTime scheduledAt,
  });
  Future<void> cancelReminder(int id);
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _priorityChannelId = 'priority';
  static const _remindersChannelId = 'reminders';

  @override
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  @override
  Future<void> showPriorityLinksNotification(int count) async {
    await _plugin.show(
      0,
      'Links prioritarios',
      'Tienes $count link(s) prioritario(s) pendientes de revisar',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _priorityChannelId,
          'Prioritarios',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> scheduleLinkReminder({
    required int id,
    required String title,
    required DateTime scheduledAt,
  }) async {
    await _plugin.show(
      id,
      'Recordatorio: $title',
      'Tienes un link guardado para revisar',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _remindersChannelId,
          'Recordatorios',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }
}
