import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {
  Locale getLocale();
  Future<void> setLocale(Locale locale);
  bool getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
}

class SharedPreferencesService implements PreferencesService {
  final SharedPreferences _prefs;

  static const _keyLocale = 'locale';
  static const _keyNotifications = 'notifications_enabled';

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
}
