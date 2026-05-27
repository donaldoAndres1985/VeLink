import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/l10n/app_strings.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/core/theme/app_theme.dart';
import 'package:velink/features/stats/screens/stats_screen.dart';
import '../../helpers/database_helper.dart';

class _FixedPrefs implements PreferencesService {
  final int streak;
  final bool premium;
  _FixedPrefs({this.streak = 0, this.premium = true});

  @override
  int getStreak() => streak;
  @override
  String? getStreakLastDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> setStreak(int c) async {}
  @override
  Future<void> setStreakLastDate(String d) async {}
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
  bool isPremium() => premium;
  @override
  Future<void> setPremium(bool v) async {}
}

List<DayCount> _fakeDays(int days) => List.generate(
      days,
      (i) => DayCount(
        date: DateTime.now().subtract(Duration(days: days - 1 - i)),
        count: 0,
      ),
    );

List<DayCount> _fakeYear() => List.generate(
      364,
      (i) => DayCount(
        date: DateTime.now().subtract(Duration(days: 363 - i)),
        count: 0,
      ),
    );

Widget buildStatsWidget(
  LinkStats stats, {
  int streak = 0,
  bool isPremium = true,
  List<DayCount>? dayData,
  List<PlatformCount>? platforms,
  List<DayCount>? yearData,
}) {
  final db = createTestDatabase();
  final prefs = _FixedPrefs(streak: streak, premium: isPremium);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appStringsProvider.overrideWithValue(AppStrings('es')),
      preferencesServiceProvider.overrideWithValue(prefs),
      linkStatsProvider.overrideWith((ref) => Future.value(stats)),
      streakProvider.overrideWith((ref) => StreakNotifier(prefs)),
      premiumProvider.overrideWith((ref) => PremiumNotifier(prefs)),
      linksPerDayProvider.overrideWith(
        (ref, days) => Future.value(dayData ?? _fakeDays(days)),
      ),
      platformBreakdownProvider.overrideWith(
        (ref) => Future.value(platforms ?? []),
      ),
      linksForYearProvider.overrideWith(
        (ref) => Future.value(yearData ?? _fakeYear()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const StatsScreen(),
    ),
  );
}

const _kEmpty = LinkStats(
  total: 0,
  thisWeek: 0,
  thisMonth: 0,
  reviewed: 0,
  pending: 0,
  favorites: 0,
);

const _kStats = LinkStats(
  total: 10,
  thisWeek: 2,
  thisMonth: 5,
  reviewed: 8,
  pending: 2,
  favorites: 1,
);

void main() {
  group('StatsScreen', () {
    testWidgets('muestra el título Tu actividad', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kEmpty));
      await tester.pumpAndSettle();
      expect(find.text('Tu actividad'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay links', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kEmpty));
      await tester.pumpAndSettle();
      expect(find.textContaining('Guarda links para ver'), findsOneWidget);
    });

    testWidgets('muestra el total de links correctamente', (tester) async {
      const stats = LinkStats(
        total: 42,
        thisWeek: 5,
        thisMonth: 15,
        reviewed: 30,
        pending: 12,
        favorites: 7,
      );
      await tester.pumpWidget(buildStatsWidget(stats));
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Total guardados'), findsOneWidget);
    });

    testWidgets('muestra estadísticas de semana y mes', (tester) async {
      const stats = LinkStats(
        total: 10,
        thisWeek: 3,
        thisMonth: 8,
        reviewed: 5,
        pending: 5,
        favorites: 2,
      );
      await tester.pumpWidget(buildStatsWidget(stats));
      await tester.pumpAndSettle();
      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('Este mes'), findsOneWidget);
    });

    testWidgets('muestra la plataforma principal cuando existe', (tester) async {
      const stats = LinkStats(
        total: 5,
        thisWeek: 1,
        thisMonth: 3,
        reviewed: 2,
        pending: 3,
        favorites: 0,
        topPlatform: 'youtube',
      );
      await tester.pumpWidget(buildStatsWidget(stats));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Plataforma principal'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Plataforma principal'), findsOneWidget);
      expect(find.text('youtube'), findsWidgets);
    });
  });

  group('StatsScreen — racha', () {
    testWidgets('muestra card de racha con valor correcto', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, streak: 7));
      await tester.pumpAndSettle();
      expect(find.text('Racha'), findsOneWidget);
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('muestra racha en 0 cuando es nueva instalación', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, streak: 0));
      await tester.pumpAndSettle();
      expect(find.text('Racha'), findsOneWidget);
    });
  });

  group('StatsScreen — score de productividad', () {
    testWidgets('muestra card de productividad', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, streak: 5));
      await tester.pumpAndSettle();
      expect(find.text('Productividad'), findsOneWidget);
    });

    testWidgets('no muestra score cuando no hay links', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kEmpty));
      await tester.pumpAndSettle();
      expect(find.text('Productividad'), findsNothing);
    });
  });

  group('StatsScreen — tasa de revisión', () {
    testWidgets('muestra barra de tasa de revisión', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      expect(find.text('Tasa de revisión'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra porcentaje correcto de revisión', (tester) async {
      const stats = LinkStats(
        total: 4, thisWeek: 1, thisMonth: 2, reviewed: 3, pending: 1, favorites: 0,
      );
      await tester.pumpWidget(buildStatsWidget(stats));
      await tester.pumpAndSettle();
      expect(find.text('75%'), findsOneWidget);
    });
  });

  group('StatsScreen — selector de tiempo', () {
    testWidgets('muestra botones Semana y Mes', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      expect(find.text('Semana'), findsOneWidget);
      expect(find.text('Mes'), findsOneWidget);
    });
  });

  group('StatsScreen — gráfica de tendencia', () {
    testWidgets('muestra sección de tendencia', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      expect(find.text('Tendencia'), findsOneWidget);
    });
  });

  group('StatsScreen — plataformas', () {
    testWidgets('muestra sección de plataformas cuando hay datos', (tester) async {
      await tester.pumpWidget(buildStatsWidget(
        _kStats,
        platforms: [
          PlatformCount(platform: 'youtube', count: 6),
          PlatformCount(platform: 'twitter', count: 2),
        ],
      ));
      await tester.pumpAndSettle();
      // drain microtasks para provider lazy (platformBreakdownProvider se
      // empieza a observar solo después de que linkStatsProvider resuelve)
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Plataformas'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Plataformas'), findsOneWidget);
      expect(find.text('youtube'), findsWidgets);
    });

    testWidgets('no muestra sección de plataformas cuando no hay datos', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();
      expect(find.text('Plataformas'), findsNothing);
    });
  });

  group('StatsScreen — heatmap', () {
    testWidgets('muestra sección de actividad anual', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Actividad'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Actividad'), findsOneWidget);
    });

    testWidgets('heatmap genera el número correcto de semanas según el offset del origen', (tester) async {
      // El origen es DateTime.now() - 363 días. Su weekday determina el offset.
      // offset = weekday - 1 (0=Lun, 6=Dom). totalWeeks = ceil((364 + offset) / 7).
      final origin = DateTime.now().subtract(const Duration(days: 363));
      final normalizedOrigin = DateTime(origin.year, origin.month, origin.day);
      final offset = normalizedOrigin.weekday - 1;
      final expectedWeeks = ((364 + offset) / 7).ceil();

      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Actividad'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      final row = tester.widget<Row>(find.byKey(const ValueKey('heatmap_grid')));
      expect(row.children.length, equals(expectedWeeks));
    });

    testWidgets('heatmap auto-scrollea al final para mostrar semanas recientes', (tester) async {
      // Usar tamaño de pantalla de teléfono real para que el heatmap desborde.
      // Con 375px de ancho: card≈343px, contenido≈689px → maxScrollExtent>0.
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Actividad'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      // Dejar que el postFrameCallback ejecute el jumpTo
      await tester.pump();
      await tester.pumpAndSettle();

      final scrollableState = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap_scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollableState.position.pixels, greaterThan(0),
          reason: 'El heatmap debería auto-scrollear al final (semanas más recientes)');
    });

    testWidgets('heatmap muestra celda activa cuando el último día tiene actividad', (tester) async {
      // Solo el último día (hoy) tiene links
      final today = DateTime.now();
      final origin = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 363));
      final yearData = List.generate(
        364,
        (i) => DayCount(date: origin.add(Duration(days: i)), count: i == 363 ? 5 : 0),
      );

      await tester.pumpWidget(buildStatsWidget(_kStats, yearData: yearData));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Actividad'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      // Debe existir al menos un Container descendiente del heatmap con color verde puro (count >= 5)
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap_grid')),
          matching: find.byType(Container),
        ),
      );
      final hasActiveCell = containers.any((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration && deco.color != null) {
          // count>=5 → _cellColor devuelve VerLinkColors.green sin modificar alpha
          return deco.color == VerLinkColors.green;
        }
        return false;
      });
      expect(hasActiveCell, isTrue,
          reason: 'El último día (hoy) tiene 5 links pero no aparece ninguna celda verde');
    });
  });

  group('StatsScreen — logros', () {
    testWidgets('muestra sección de Logros cuando hay links', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Logros'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Logros'), findsOneWidget);
    });

    testWidgets('muestra badge Primer link cuando total >= 1', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Primer link'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Primer link'), findsWidgets);
    });

    testWidgets('muestra sección Próximo logro cuando hay badges sin ganar', (tester) async {
      const stats = LinkStats(
        total: 5, thisWeek: 1, thisMonth: 3, reviewed: 2, pending: 3, favorites: 0,
      );
      await tester.pumpWidget(buildStatsWidget(stats));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Próximo logro'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Próximo logro'), findsOneWidget);
    });

    testWidgets('no muestra logros cuando no hay links', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kEmpty));
      await tester.pumpAndSettle();
      expect(find.text('Logros'), findsNothing);
    });
  });

  group('StatsScreen — premium gate', () {
    testWidgets('usuario free ve card de upgrade en lugar de secciones avanzadas', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, isPremium: false));
      await tester.pumpAndSettle();
      expect(find.text('Desbloquear estadísticas'), findsOneWidget);
    });

    testWidgets('usuario free no ve sección Tendencia', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, isPremium: false));
      await tester.pumpAndSettle();
      expect(find.text('Tendencia'), findsNothing);
    });

    testWidgets('usuario free no ve sección Logros', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, isPremium: false));
      await tester.pumpAndSettle();
      expect(find.text('Logros'), findsNothing);
    });

    testWidgets('usuario premium ve sección Tendencia', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, isPremium: true));
      await tester.pumpAndSettle();
      expect(find.text('Tendencia'), findsOneWidget);
    });

    testWidgets('card de upgrade muestra botón para ir al paywall', (tester) async {
      await tester.pumpWidget(buildStatsWidget(_kStats, isPremium: false));
      await tester.pumpAndSettle();
      expect(find.text('Ver planes'), findsOneWidget);
    });
  });
}
