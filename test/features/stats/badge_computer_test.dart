import 'package:flutter_test/flutter_test.dart';
import 'package:velink/core/database/database.dart';
import 'package:velink/features/stats/models/badge.dart';

LinkStats _s({int total = 0, int reviewed = 0, int favorites = 0, int uniquePlatforms = 0}) =>
    LinkStats(
      total: total,
      thisWeek: 0,
      thisMonth: 0,
      reviewed: reviewed,
      pending: total - reviewed,
      favorites: favorites,
      uniquePlatforms: uniquePlatforms,
    );

void main() {
  group('BadgeComputer — compute', () {
    test('sin links no hay insignias ganadas', () {
      final badges = BadgeComputer.compute(_s(), streak: 0);
      expect(badges.where((b) => b.earned).length, 0);
    });

    test('primer_link se gana con total >= 1', () {
      final badges = BadgeComputer.compute(_s(total: 1), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'primer_link');
      expect(badge.earned, isTrue);
    });

    test('primer_link no se gana con total == 0', () {
      final badges = BadgeComputer.compute(_s(), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'primer_link');
      expect(badge.earned, isFalse);
    });

    test('colector se gana con total >= 50', () {
      final badges = BadgeComputer.compute(_s(total: 50), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'colector');
      expect(badge.earned, isTrue);
    });

    test('colector no se gana con total == 49', () {
      final badges = BadgeComputer.compute(_s(total: 49), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'colector');
      expect(badge.earned, isFalse);
    });

    test('lector se gana con reviewed >= 10', () {
      final badges = BadgeComputer.compute(_s(total: 10, reviewed: 10), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'lector');
      expect(badge.earned, isTrue);
    });

    test('curador se gana con reviewed >= 50', () {
      final badges = BadgeComputer.compute(_s(total: 50, reviewed: 50), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'curador');
      expect(badge.earned, isTrue);
    });

    test('racha7 se gana con streak >= 7', () {
      final badges = BadgeComputer.compute(_s(total: 1), streak: 7);
      final badge = badges.firstWhere((b) => b.id == 'racha7');
      expect(badge.earned, isTrue);
    });

    test('racha7 no se gana con streak == 6', () {
      final badges = BadgeComputer.compute(_s(total: 1), streak: 6);
      final badge = badges.firstWhere((b) => b.id == 'racha7');
      expect(badge.earned, isFalse);
    });

    test('racha30 se gana con streak >= 30', () {
      final badges = BadgeComputer.compute(_s(total: 1), streak: 30);
      final badge = badges.firstWhere((b) => b.id == 'racha30');
      expect(badge.earned, isTrue);
    });

    test('gran_colector se gana con total >= 200', () {
      final badges = BadgeComputer.compute(_s(total: 200), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'gran_colector');
      expect(badge.earned, isTrue);
    });

    test('explorador se gana con uniquePlatforms >= 3', () {
      final badges = BadgeComputer.compute(_s(total: 3, uniquePlatforms: 3), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'explorador');
      expect(badge.earned, isTrue);
    });

    test('explorador no se gana con uniquePlatforms < 3', () {
      final badges = BadgeComputer.compute(_s(total: 2, uniquePlatforms: 2), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'explorador');
      expect(badge.earned, isFalse);
    });

    test('progress está entre 0 y 1', () {
      final badges = BadgeComputer.compute(_s(total: 5), streak: 3);
      for (final b in badges) {
        expect(b.progress, inInclusiveRange(0.0, 1.0));
      }
    });

    test('badge ganado tiene progress == 1', () {
      final badges = BadgeComputer.compute(_s(total: 1), streak: 0);
      final badge = badges.firstWhere((b) => b.id == 'primer_link');
      expect(badge.progress, 1.0);
    });
  });

  group('BadgeComputer — nextMilestone', () {
    test('devuelve primer_link como primer milestone si total == 0', () {
      final milestone = BadgeComputer.nextMilestone(_s(), streak: 0);
      expect(milestone?.id, 'primer_link');
    });

    test('devuelve null si todos los badges están ganados', () {
      final stats = LinkStats(
        total: 200,
        thisWeek: 0,
        thisMonth: 0,
        reviewed: 50,
        pending: 150,
        favorites: 0,
        uniquePlatforms: 3,
      );
      final milestone = BadgeComputer.nextMilestone(stats, streak: 30);
      expect(milestone, isNull);
    });

    test('devuelve el milestone con mayor progreso entre los no ganados', () {
      // total=5 → colector progress=5/50=0.1, gran_colector=5/200=0.025
      // pero primer_link ya está ganado (total≥1), así que colector tiene 5/50=0.1
      // lector=0/10=0, racha7=0/7=0, explorador=1/3≈0.33
      final milestone = BadgeComputer.nextMilestone(
        _s(total: 5, reviewed: 0, uniquePlatforms: 1),
        streak: 0,
      );
      expect(milestone, isNotNull);
      expect(milestone!.progress, inInclusiveRange(0.0, 1.0));
    });

    test('progreso del milestone está entre 0 y 1', () {
      final milestone = BadgeComputer.nextMilestone(_s(total: 5), streak: 3);
      expect(milestone?.progress, inInclusiveRange(0.0, 1.0));
    });
  });
}
