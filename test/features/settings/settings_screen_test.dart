import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/notifications/providers/notification_provider.dart';
import 'package:velink/features/settings/screens/settings_screen.dart';
import '../../helpers/database_helper.dart';

class _FakePrefs implements PreferencesService {
  Locale _locale;
  bool _notifications;
  ThemeMode _themeMode;

  _FakePrefs({
    Locale locale = const Locale('es'),
    bool notifications = true,
    ThemeMode themeMode = ThemeMode.light,
  })  : _locale = locale,
        _notifications = notifications,
        _themeMode = themeMode;

  @override
  Locale getLocale() => _locale;
  @override
  Future<void> setLocale(Locale locale) async => _locale = locale;
  @override
  bool getNotificationsEnabled() => _notifications;
  @override
  Future<void> setNotificationsEnabled(bool enabled) async =>
      _notifications = enabled;
  @override
  ThemeMode getThemeMode() => _themeMode;
  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;
}

Widget _wrap({
  String lang = 'es',
  bool notifications = true,
  bool notifPermGranted = true,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final prefs = _FakePrefs(
    locale: Locale(lang),
    notifications: notifications,
    themeMode: themeMode,
  );
  final db = createTestDatabase();
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      appStringsProvider.overrideWithValue(AppStrings(lang)),
      localePrefProvider.overrideWith((ref) => LocaleNotifier(prefs, Locale(lang))),
      notificationsEnabledProvider.overrideWith(
        (ref) => NotificationsEnabledNotifier(prefs, notifications),
      ),
      themeModeProvider.overrideWith((ref) => ThemeModeNotifier(prefs, themeMode)),
      notifPermissionProvider.overrideWith((ref) => Future.value(notifPermGranted)),
      databaseProvider.overrideWithValue(db),
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
      await tester.ensureVisible(find.byKey(const Key('notifications_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notifications_switch')));
      await tester.pump();
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
    });

    testWidgets('muestra información de la app con versión', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('1.0.0'), 100);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('título en inglés cuando lang=en', (tester) async {
      await tester.pumpWidget(_wrap(lang: 'en'));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('muestra sección Legal con Política de privacidad', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Política de privacidad'), 100);
      expect(find.text('Política de privacidad'), findsOneWidget);
    });

    testWidgets('muestra sección Legal con Términos de uso', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Términos de uso'), 100);
      expect(find.text('Términos de uso'), findsOneWidget);
    });

    testWidgets('muestra Eliminar mis datos', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Eliminar mis datos'), 100);
      expect(find.text('Eliminar mis datos'), findsWidgets);
    });

    testWidgets('muestra Contactar soporte', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Contactar soporte'), 100);
      expect(find.text('Contactar soporte'), findsOneWidget);
    });

    testWidgets('tap en Política de privacidad navega a página con texto', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();
      expect(find.text('POLÍTICA DE PRIVACIDAD — VerLink', findRichText: true), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('tap en Eliminar mis datos muestra diálogo de confirmación', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Eliminar mis datos'), 50);
      await tester.pump();
      await tester.tap(find.text('Eliminar mis datos'));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar todo'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('warning de permiso visible si notificaciones ON y permiso bloqueado', (tester) async {
      await tester.pumpWidget(_wrap(notifications: true, notifPermGranted: false));
      await tester.pumpAndSettle();
      expect(
        find.text('Las notificaciones están desactivadas en la configuración del sistema.'),
        findsOneWidget,
      );
    });

    testWidgets('sin warning de permiso si notificaciones están desactivadas', (tester) async {
      await tester.pumpWidget(_wrap(notifications: false, notifPermGranted: false));
      await tester.pumpAndSettle();
      expect(
        find.text('Las notificaciones están desactivadas en la configuración del sistema.'),
        findsNothing,
      );
    });

    testWidgets('muestra sección Apariencia con tiles Claro y Oscuro', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('theme_light')), findsOneWidget);
      expect(find.byKey(const Key('theme_dark')), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
    });

    testWidgets('tema Claro marcado cuando themeMode=light', (tester) async {
      await tester.pumpWidget(_wrap(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(find.byKey(const Key('theme_light')));
      expect(tile.selected, isTrue);
    });

    testWidgets('tema Oscuro marcado cuando themeMode=dark', (tester) async {
      await tester.pumpWidget(_wrap(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(find.byKey(const Key('theme_dark')));
      expect(tile.selected, isTrue);
    });

    testWidgets('tap en Oscuro lo selecciona', (tester) async {
      await tester.pumpWidget(_wrap(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme_dark')));
      await tester.pump();
      final tile = tester.widget<ListTile>(find.byKey(const Key('theme_dark')));
      expect(tile.selected, isTrue);
    });

    testWidgets('tap en Claro lo selecciona', (tester) async {
      await tester.pumpWidget(_wrap(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme_light')));
      await tester.pump();
      final tile = tester.widget<ListTile>(find.byKey(const Key('theme_light')));
      expect(tile.selected, isTrue);
    });
  });
}
