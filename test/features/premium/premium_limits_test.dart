import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/core/preferences/preferences_provider.dart';
import 'package:velink/core/preferences/preferences_service.dart';
import 'package:velink/features/premium/domain/premium_limits.dart';

// ── Fake prefs ────────────────────────────────────────────────────────────────
class _FakePrefs implements PreferencesService {
  bool _premium;
  _FakePrefs({bool premium = false}) : _premium = premium;
  @override Locale getLocale() => const Locale('es');
  @override Future<void> setLocale(Locale l) async {}
  @override bool getNotificationsEnabled() => true;
  @override Future<void> setNotificationsEnabled(bool v) async {}
  @override ThemeMode getThemeMode() => ThemeMode.light;
  @override Future<void> setThemeMode(ThemeMode m) async {}
  @override int getStreak() => 0;
  @override Future<void> setStreak(int c) async {}
  @override String? getStreakLastDate() => null;
  @override Future<void> setStreakLastDate(String d) async {}
  @override bool isPremium() => _premium;
  @override Future<void> setPremium(bool v) async { _premium = v; }
}

ProviderContainer _makeContainer({bool premium = false}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final prefs = _FakePrefs(premium: premium);
  return ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    preferencesServiceProvider.overrideWithValue(prefs),
  ]);
}

void main() {
  group('PremiumLimits — constantes', () {
    test('freeMaxLinks es 30', () => expect(freeMaxLinks, 30));
    test('freeMaxCollections es 2', () => expect(freeMaxCollections, 2));
    test('freeMaxTags es 3', () => expect(freeMaxTags, 3));
  });

  group('canCreateLinkProvider', () {
    test('usuario free con 0 links puede crear', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(canCreateLinkProvider.future), isTrue);
    });

    test('usuario premium siempre puede crear', () async {
      final c = _makeContainer(premium: true);
      addTearDown(c.dispose);
      expect(await c.read(canCreateLinkProvider.future), isTrue);
    });

    test('usuario free con 30 links no puede crear', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final db = c.read(databaseProvider);
      for (var i = 0; i < freeMaxLinks; i++) {
        await db.insertLink(LinksCompanion.insert(url: 'https://example$i.com'));
      }
      expect(await c.read(canCreateLinkProvider.future), isFalse);
    });
  });

  group('canCreateCollectionProvider', () {
    test('usuario free con 0 colecciones puede crear', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(canCreateCollectionProvider.future), isTrue);
    });

    test('usuario free con 2 colecciones no puede crear', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final db = c.read(databaseProvider);
      for (var i = 0; i < freeMaxCollections; i++) {
        await db.insertCollection(CollectionsCompanion.insert(name: 'Col$i'));
      }
      expect(await c.read(canCreateCollectionProvider.future), isFalse);
    });

    test('usuario premium con 2+ colecciones puede crear', () async {
      final c = _makeContainer(premium: true);
      addTearDown(c.dispose);
      final db = c.read(databaseProvider);
      for (var i = 0; i < freeMaxCollections; i++) {
        await db.insertCollection(CollectionsCompanion.insert(name: 'Col$i'));
      }
      expect(await c.read(canCreateCollectionProvider.future), isTrue);
    });
  });

  group('canCreateTagProvider', () {
    test('usuario free con 0 tags puede crear', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(canCreateTagProvider.future), isTrue);
    });

    test('usuario free con 3 tags no puede crear', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final db = c.read(databaseProvider);
      for (var i = 0; i < freeMaxTags; i++) {
        await db.insertTag(TagsCompanion.insert(name: 'Tag$i'));
      }
      expect(await c.read(canCreateTagProvider.future), isFalse);
    });
  });

  group('guards booleanos', () {
    test('canUseTagColors es false para free', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      expect(c.read(canUseTagColorsProvider), isFalse);
    });

    test('canViewFullStats es true para premium', () {
      final c = _makeContainer(premium: true);
      addTearDown(c.dispose);
      expect(c.read(canViewFullStatsProvider), isTrue);
    });
  });
}
