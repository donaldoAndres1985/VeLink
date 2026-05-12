import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/settings/screens/settings_screen.dart';

class _FakePrefs implements PreferencesService {
  Locale _locale;
  bool _notifications;

  _FakePrefs({Locale locale = const Locale('es'), bool notifications = true})
      : _locale = locale,
        _notifications = notifications;

  @override
  Locale getLocale() => _locale;
  @override
  Future<void> setLocale(Locale locale) async => _locale = locale;
  @override
  bool getNotificationsEnabled() => _notifications;
  @override
  Future<void> setNotificationsEnabled(bool enabled) async =>
      _notifications = enabled;
}

Widget _wrap({String lang = 'es', bool notifications = true}) {
  final prefs = _FakePrefs(locale: Locale(lang), notifications: notifications);
  return ProviderScope(
    overrides: [
      appStringsProvider.overrideWithValue(AppStrings(lang)),
      localePrefProvider.overrideWith(
        (ref) => LocaleNotifier(prefs, Locale(lang)),
      ),
      notificationsEnabledProvider.overrideWith(
        (ref) => NotificationsEnabledNotifier(prefs, notifications),
      ),
    ],
    child: const MaterialApp(home: AjustesScreen()),
  );
}

void main() {
  group('AjustesScreen', () {
    testWidgets('muestra sección de Idioma con Español y English', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('muestra switch de Notificaciones', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byKey(const Key('notifications_switch')), findsOneWidget);
    });

    testWidgets('switch de notificaciones inicia activado por defecto', (tester) async {
      await tester.pumpWidget(_wrap(notifications: true));
      final sw = tester.widget<SwitchListTile>(
        find.byKey(const Key('notifications_switch')),
      );
      expect(sw.value, isTrue);
    });

    testWidgets('switch de notificaciones inicia desactivado si preference=false',
        (tester) async {
      await tester.pumpWidget(_wrap(notifications: false));
      final sw = tester.widget<SwitchListTile>(
        find.byKey(const Key('notifications_switch')),
      );
      expect(sw.value, isFalse);
    });

    testWidgets('Español está marcado cuando lang=es', (tester) async {
      await tester.pumpWidget(_wrap(lang: 'es'));
      final tile = tester.widget<ListTile>(find.byKey(const Key('lang_es')));
      expect(tile.selected, isTrue);
    });

    testWidgets('English está marcado cuando lang=en', (tester) async {
      await tester.pumpWidget(_wrap(lang: 'en'));
      final tile = tester.widget<ListTile>(find.byKey(const Key('lang_en')));
      expect(tile.selected, isTrue);
    });

    testWidgets('tap en English cambia la selección a en', (tester) async {
      await tester.pumpWidget(_wrap(lang: 'es'));
      await tester.tap(find.byKey(const Key('lang_en')));
      await tester.pump();
      final tile = tester.widget<ListTile>(find.byKey(const Key('lang_en')));
      expect(tile.selected, isTrue);
    });

    testWidgets('tap en switch muestra snackbar de confirmación', (tester) async {
      await tester.pumpWidget(_wrap(notifications: true));
      await tester.tap(find.byKey(const Key('notifications_switch')));
      await tester.pump();
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
    });

    testWidgets('muestra información de la app con versión', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('título en inglés cuando lang=en', (tester) async {
      await tester.pumpWidget(_wrap(lang: 'en'));
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
