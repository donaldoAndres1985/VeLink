import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';

class _FakePrefs implements PreferencesService {
  int _streak = 0;
  String? _lastDate;

  @override
  int getStreak() => _streak;
  @override
  Future<void> setStreak(int count) async => _streak = count;
  @override
  String? getStreakLastDate() => _lastDate;
  @override
  Future<void> setStreakLastDate(String date) async => _lastDate = date;

  @override
  Locale getLocale() => const Locale('es');
  @override
  Future<void> setLocale(Locale l) async {}
  @override
  bool getNotificationsEnabled() => true;
  @override
  Future<void> setNotificationsEnabled(bool e) async {}
  @override
  ThemeMode getThemeMode() => ThemeMode.light;
  @override
  Future<void> setThemeMode(ThemeMode m) async {}
  @override
  bool isPremium() => false;
  @override
  Future<void> setPremium(bool value) async {}
}

void main() {
  late _FakePrefs prefs;
  late StreakNotifier notifier;

  final day0 = DateTime(2026, 1, 1);
  final day1 = DateTime(2026, 1, 2);
  final day2 = DateTime(2026, 1, 3);
  final day5 = DateTime(2026, 1, 6);

  setUp(() {
    prefs = _FakePrefs();
    notifier = StreakNotifier(prefs);
  });

  group('StreakNotifier', () {
    test('estado inicial es 0 cuando no hay racha guardada', () {
      expect(notifier.state, 0);
    });

    test('primera apertura establece racha en 1', () {
      notifier.recordOpen(day0);
      expect(notifier.state, 1);
    });

    test('abrir dos veces el mismo día no incrementa la racha', () {
      notifier.recordOpen(day0);
      notifier.recordOpen(day0);
      expect(notifier.state, 1);
    });

    test('días consecutivos incrementan la racha', () {
      notifier.recordOpen(day0);
      notifier.recordOpen(day1);
      notifier.recordOpen(day2);
      expect(notifier.state, 3);
    });

    test('saltar un día resetea la racha a 1', () {
      notifier.recordOpen(day0);
      notifier.recordOpen(day1);
      notifier.recordOpen(day5);
      expect(notifier.state, 1);
    });
  });
}
