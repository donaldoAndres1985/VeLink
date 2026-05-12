import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

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

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    tzData.initializeTimeZones();
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
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
    final tzScheduledAt = tz.TZDateTime(
      tz.local,
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );

    await _plugin.zonedSchedule(
      id,
      'Recordatorio: $title',
      'Tienes un link guardado para revisar',
      tzScheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _remindersChannelId,
          'Recordatorios',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }
}
