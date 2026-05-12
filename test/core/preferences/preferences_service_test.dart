import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velink/core/preferences/preferences_service.dart';

void main() {
  late SharedPreferencesService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = SharedPreferencesService(prefs);
  });

  group('SharedPreferencesService', () {
    group('getLocale', () {
      test('devuelve Locale(es) por defecto', () {
        expect(service.getLocale(), const Locale('es'));
      });

      test('devuelve Locale(en) después de setLocale(en)', () async {
        await service.setLocale(const Locale('en'));
        expect(service.getLocale(), const Locale('en'));
      });

      test('devuelve Locale(es) después de setLocale(es)', () async {
        await service.setLocale(const Locale('es'));
        expect(service.getLocale(), const Locale('es'));
      });
    });

    group('getNotificationsEnabled', () {
      test('devuelve true por defecto', () {
        expect(service.getNotificationsEnabled(), isTrue);
      });

      test('devuelve false después de setNotificationsEnabled(false)', () async {
        await service.setNotificationsEnabled(false);
        expect(service.getNotificationsEnabled(), isFalse);
      });

      test('devuelve true después de setNotificationsEnabled(true)', () async {
        await service.setNotificationsEnabled(false);
        await service.setNotificationsEnabled(true);
        expect(service.getNotificationsEnabled(), isTrue);
      });
    });

    group('persistencia', () {
      test('el locale persiste en SharedPreferences', () async {
        await service.setLocale(const Locale('en'));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('locale'), 'en');
      });

      test('las notificaciones persisten en SharedPreferences', () async {
        await service.setNotificationsEnabled(false);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('notifications_enabled'), isFalse);
      });
    });
  });
}
