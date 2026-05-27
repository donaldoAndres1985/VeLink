import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/core/theme/app_theme.dart';
import 'package:velink/features/premium/screens/paywall_screen.dart';

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

Widget _buildPaywall({bool isPremium = false}) {
  final prefs = _FakePrefs(premium: isPremium);
  return ProviderScope(
    overrides: [
      appStringsProvider.overrideWithValue(AppStrings('es')),
      preferencesServiceProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const PaywallScreen(),
    ),
  );
}

void main() {
  group('PaywallScreen', () {
    testWidgets('muestra título VerLink Premium', (tester) async {
      await tester.pumpWidget(_buildPaywall());
      await tester.pumpAndSettle();
      expect(find.text('VerLink Premium'), findsWidgets);
    });

    testWidgets('muestra botón Activar Premium', (tester) async {
      await tester.pumpWidget(_buildPaywall());
      await tester.pumpAndSettle();
      expect(find.text('Activar Premium'), findsOneWidget);
    });

    testWidgets('muestra botón Quizás después', (tester) async {
      await tester.pumpWidget(_buildPaywall());
      await tester.pumpAndSettle();
      expect(find.text('Quizás después'), findsOneWidget);
    });

    testWidgets('muestra feature de estadísticas avanzadas', (tester) async {
      await tester.pumpWidget(_buildPaywall());
      await tester.pumpAndSettle();
      expect(find.text('Estadísticas avanzadas'), findsOneWidget);
    });

    testWidgets('muestra feature de colecciones ilimitadas', (tester) async {
      await tester.pumpWidget(_buildPaywall());
      await tester.pumpAndSettle();
      expect(find.text('Colecciones ilimitadas'), findsOneWidget);
    });

    testWidgets('tapping Activar Premium cambia estado premium', (tester) async {
      final prefs = _FakePrefs(premium: false);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(AppStrings('es')),
          preferencesServiceProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PaywallScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activar Premium'));
      await tester.pumpAndSettle();
      expect(prefs.isPremium(), isTrue);
    });
  });
}
