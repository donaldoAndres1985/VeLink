import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/core/theme/app_theme.dart';

ProviderContainer createTestContainer({List<Override> overrides = const []}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      notificationsEnabledProvider.overrideWith(
        (ref) => NotificationsEnabledNotifier(_FakePrefs(), true),
      ),
      ...overrides,
    ],
  );
}

Widget buildTestWidget(Widget child, {List<Override> overrides = const []}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      notificationsEnabledProvider.overrideWith(
        (ref) => NotificationsEnabledNotifier(_FakePrefs(), true),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: child,
    ),
  );
}

class _FakePrefs implements PreferencesService {
  @override
  Locale getLocale() => const Locale('es');
  @override
  Future<void> setLocale(Locale locale) async {}
  @override
  bool getNotificationsEnabled() => true;
  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}
  @override
  ThemeMode getThemeMode() => ThemeMode.light;
  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}
