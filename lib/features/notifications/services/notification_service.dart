import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> init();
  Future<void> showFavoriteLinksNotification(
    int count, {
    String? title,
    String? body,
  });
  Future<void> scheduleLinkReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  });
  Future<void> cancelReminder(int id);
  Future<void> cancelAll();
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _favoritesChannelId = 'favorites';
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
  Future<void> showFavoriteLinksNotification(
    int count, {
    String? title,
    String? body,
  }) async {
    final notifTitle = title ?? 'Links favoritos';
    final notifBody = body ??
        'Tienes $count link${count != 1 ? "s" : ""} favorito${count != 1 ? "s" : ""} pendiente${count != 1 ? "s" : ""} de revisar';

    await _plugin.show(
      0,
      notifTitle,
      notifBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _favoritesChannelId,
          'Favoritos',
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
    required String body,
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
      title,
      body,
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

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
