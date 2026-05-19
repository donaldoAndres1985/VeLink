import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {
  Locale getLocale();
  Future<void> setLocale(Locale locale);
  bool getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}

class SharedPreferencesService implements PreferencesService {
  final SharedPreferences _prefs;

  static const _keyLocale = 'locale';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyThemeMode = 'theme_mode';

  SharedPreferencesService(this._prefs);

  @override
  Locale getLocale() {
    final code = _prefs.getString(_keyLocale) ?? 'es';
    return Locale(code);
  }

  @override
  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_keyLocale, locale.languageCode);
  }

  @override
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotifications, enabled);
  }

  @override
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode) ?? 'light';
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
