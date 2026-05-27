import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';

class _FakePrefs implements PreferencesService {
  bool _premium;
  _FakePrefs({bool premium = false}) : _premium = premium;

  @override bool isPremium() => _premium;
  @override Future<void> setPremium(bool v) async => _premium = v;
  @override Locale getLocale() => const Locale('es');
  @override Future<void> setLocale(Locale l) async {}
  @override bool getNotificationsEnabled() => true;
  @override Future<void> setNotificationsEnabled(bool e) async {}
  @override ThemeMode getThemeMode() => ThemeMode.light;
  @override Future<void> setThemeMode(ThemeMode m) async {}
  @override int getStreak() => 0;
  @override Future<void> setStreak(int c) async {}
  @override String? getStreakLastDate() => null;
  @override Future<void> setStreakLastDate(String d) async {}
}

void main() {
  group('PremiumNotifier', () {
    test('estado inicial es false (free)', () {
      final notifier = PremiumNotifier(_FakePrefs(premium: false));
      expect(notifier.state, isFalse);
    });

    test('estado inicial es true si el servicio retorna true', () {
      final notifier = PremiumNotifier(_FakePrefs(premium: true));
      expect(notifier.state, isTrue);
    });

    test('upgrade() cambia estado a true', () async {
      final notifier = PremiumNotifier(_FakePrefs(premium: false));
      await notifier.upgrade();
      expect(notifier.state, isTrue);
    });

    test('downgrade() cambia estado a false', () async {
      final notifier = PremiumNotifier(_FakePrefs(premium: true));
      await notifier.downgrade();
      expect(notifier.state, isFalse);
    });

    test('upgrade() persiste en el servicio', () async {
      final prefs = _FakePrefs(premium: false);
      final notifier = PremiumNotifier(prefs);
      await notifier.upgrade();
      expect(prefs.isPremium(), isTrue);
    });

    test('premiumProvider expone estado desde preferencesServiceProvider', () {
      final prefs = _FakePrefs(premium: true);
      final container = ProviderContainer(overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      expect(container.read(premiumProvider), isTrue);
    });
  });
}
