import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import 'preferences_service.dart';

// ── ThemeMode ────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesService _prefs;

  ThemeModeNotifier(this._prefs, ThemeMode initial) : super(initial);

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.read(preferencesServiceProvider);
  return ThemeModeNotifier(prefs, prefs.getThemeMode());
});

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override in main with SharedPreferences.getInstance()'),
);

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return SharedPreferencesService(ref.read(sharedPreferencesProvider));
});

// ── Locale ───────────────────────────────────────────────────────────────────

class LocaleNotifier extends StateNotifier<Locale> {
  final PreferencesService _prefs;

  LocaleNotifier(this._prefs, Locale initial) : super(initial);

  Future<void> setLocale(Locale locale) async {
    await _prefs.setLocale(locale);
    state = locale;
  }
}

final localePrefProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.read(preferencesServiceProvider);
  return LocaleNotifier(prefs, prefs.getLocale());
});

// ── Notifications enabled ────────────────────────────────────────────────────

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final PreferencesService _prefs;

  NotificationsEnabledNotifier(this._prefs, bool initial) : super(initial);

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    state = enabled;
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  final prefs = ref.read(preferencesServiceProvider);
  return NotificationsEnabledNotifier(prefs, prefs.getNotificationsEnabled());
});

// ── Streak ───────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<int> {
  final PreferencesService _prefs;

  StreakNotifier(this._prefs) : super(_prefs.getStreak());

  void recordOpen([DateTime? now]) {
    now ??= DateTime.now();
    final today = _dateKey(now);
    final lastDate = _prefs.getStreakLastDate();

    if (lastDate == today) return;

    final int newStreak;
    if (lastDate == null) {
      newStreak = 1;
    } else {
      final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
      newStreak = lastDate == yesterday ? state + 1 : 1;
    }

    _prefs.setStreak(newStreak);
    _prefs.setStreakLastDate(today);
    state = newStreak;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

final streakProvider = StateNotifierProvider<StreakNotifier, int>((ref) {
  final prefs = ref.read(preferencesServiceProvider);
  return StreakNotifier(prefs)..recordOpen();
});

// ── Premium ───────────────────────────────────────────────────────────────────

class PremiumNotifier extends StateNotifier<bool> {
  final PreferencesService _prefs;

  PremiumNotifier(this._prefs) : super(_prefs.isPremium());

  Future<void> upgrade() async {
    await _prefs.setPremium(true);
    state = true;
  }

  Future<void> downgrade() async {
    await _prefs.setPremium(false);
    state = false;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  final prefs = ref.read(preferencesServiceProvider);
  return PremiumNotifier(prefs);
});

// ── AppStrings ───────────────────────────────────────────────────────────────

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localePrefProvider);
  return AppStrings(locale.languageCode);
});
