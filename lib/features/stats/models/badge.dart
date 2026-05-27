import 'package:flutter/material.dart';
import '../../../core/database/database.dart';

class BadgeData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool earned;
  final double progress;
  final int target;
  final int current;

  const BadgeData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.earned,
    required this.progress,
    required this.target,
    required this.current,
  });
}

class BadgeComputer {
  static List<BadgeData> compute(LinkStats stats, {required int streak}) {
    return [
      _badge(
        id: 'primer_link',
        label: 'Primer link',
        icon: Icons.link_rounded,
        color: const Color(0xFF3B82F6),
        current: stats.total,
        target: 1,
      ),
      _badge(
        id: 'lector',
        label: 'Lector',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF22C55E),
        current: stats.reviewed,
        target: 10,
      ),
      _badge(
        id: 'racha7',
        label: 'Racha 7',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6B35),
        current: streak,
        target: 7,
      ),
      _badge(
        id: 'explorador',
        label: 'Explorador',
        icon: Icons.explore_rounded,
        color: const Color(0xFFA855F7),
        current: stats.uniquePlatforms,
        target: 3,
      ),
      _badge(
        id: 'colector',
        label: 'Colector',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFF59E0B),
        current: stats.total,
        target: 50,
      ),
      _badge(
        id: 'curador',
        label: 'Curador',
        icon: Icons.verified_rounded,
        color: const Color(0xFF06B6D4),
        current: stats.reviewed,
        target: 50,
      ),
      _badge(
        id: 'racha30',
        label: 'Racha 30',
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFEF4444),
        current: streak,
        target: 30,
      ),
      _badge(
        id: 'gran_colector',
        label: 'Gran colector',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFEAB308),
        current: stats.total,
        target: 200,
      ),
    ];
  }

  static BadgeData? nextMilestone(LinkStats stats, {required int streak}) {
    final unearned = compute(stats, streak: streak).where((b) => !b.earned).toList();
    if (unearned.isEmpty) return null;
    unearned.sort((a, b) => b.progress.compareTo(a.progress));
    return unearned.first;
  }

  static BadgeData _badge({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required int current,
    required int target,
  }) {
    final earned = current >= target;
    return BadgeData(
      id: id,
      label: label,
      icon: icon,
      color: color,
      earned: earned,
      progress: earned ? 1.0 : (current / target).clamp(0.0, 1.0),
      target: target,
      current: current,
    );
  }
}
