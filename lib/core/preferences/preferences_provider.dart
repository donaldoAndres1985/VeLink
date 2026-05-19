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

// ── AppStrings ───────────────────────────────────────────────────────────────

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localePrefProvider);
  return AppStrings(locale.languageCode);
});
