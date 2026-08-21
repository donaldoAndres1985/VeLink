import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/database.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/badge.dart';
import '../../premium/screens/paywall_screen.dart';
import '../../premium/presentation/widgets/premium_upgrade_card.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final linkStatsProvider = FutureProvider<LinkStats>((ref) {
  return ref.watch(databaseProvider).getLinkStats();
});

final linksPerDayProvider = FutureProvider.family<List<DayCount>, int>((ref, days) {
  return ref.watch(databaseProvider).getLinksPerDay(days: days);
});

final platformBreakdownProvider = FutureProvider<List<PlatformCount>>((ref) {
  return ref.watch(databaseProvider).getPlatformBreakdown();
});

final linksForYearProvider = FutureProvider<List<DayCount>>((ref) {
  return ref.watch(databaseProvider).getLinksForYear();
});

// ── Screen ──────────────────────────────────────────────────────────────────

enum _TimeRange { week, month }

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _TimeRange _range = _TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    final s = ref.watch(appStringsProvider);
    final statsAsync = ref.watch(linkStatsProvider);
    final streak = ref.watch(streakProvider);
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: vc.surface,
      appBar: AppBar(
        backgroundColor: vc.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: vc.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s.statsTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: vc.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: vc.textSecondary),
            tooltip: s.statsShare,
            onPressed: () => _shareStats(s),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => stats.total == 0
            ? _buildEmpty(vc, s)
            : _buildContent(stats, streak, isPremium, vc, s),
        loading: () => const Center(
          child: CircularProgressIndicator(color: VerLinkColors.primary, strokeWidth: 2),
        ),
        error: (_, __) => Center(
          child: Text(s.errorLoadLinks, style: TextStyle(color: vc.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildEmpty(VeLinkSemanticColors vc, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 56, color: vc.textTertiary),
            const SizedBox(height: 16),
            Text(
              s.statsEmptyState,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: vc.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(LinkStats stats, int streak, bool isPremium, VeLinkSemanticColors vc, AppStrings s) {
    final days = _range == _TimeRange.week ? 7 : 30;
    final dayDataAsync = isPremium ? ref.watch(linksPerDayProvider(days)) : null;
    final platformsAsync = isPremium ? ref.watch(platformBreakdownProvider) : null;
    final yearAsync = isPremium ? ref.watch(linksForYearProvider) : null;
    final score = _computeScore(stats, streak);
    final pct = (stats.reviewed / stats.total * 100).round();

    return Column(
      children: [
        _TimeRangeSelector(
          range: _range,
          vc: vc,
          s: s,
          onChanged: (r) => setState(() => _range = r),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Hero: Score + Streak
              Row(
                children: [
                  Expanded(
                    child: _HeroCard(
                      label: s.statsScore,
                      value: score,
                      icon: Icons.bolt_rounded,
                      color: _scoreColor(score),
                      vc: vc,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroCard(
                      label: s.statsStreak,
                      value: streak,
                      icon: Icons.local_fire_department_rounded,
                      color: streak > 0 ? const Color(0xFFFF6B35) : vc.textTertiary,
                      vc: vc,
                      suffix: s.statsStreakDays,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: s.statsTotalLinks,
                      value: stats.total,
                      icon: Icons.link_rounded,
                      vc: vc,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: s.statsThisWeek,
                      value: stats.thisWeek,
                      icon: Icons.calendar_today_rounded,
                      vc: vc,
                      small: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: s.statsThisMonth,
                      value: stats.thisMonth,
                      icon: Icons.calendar_month_rounded,
                      vc: vc,
                      small: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Review ratio
              _ReviewRatioCard(
                reviewed: stats.reviewed,
                total: stats.total,
                pct: pct,
                vc: vc,
                s: s,
              ),
              const SizedBox(height: 12),
              // Upgrade card for free users
              if (!isPremium) PremiumUpgradeCard(
                customTitle: s.premiumStatsLocked,
                customBtn: s.premiumViewPlans,
              ),
              // Advanced sections — premium only
              if (isPremium) ...[
                _SectionCard(
                  title: s.statsTrend,
                  vc: vc,
                  child: dayDataAsync!.when(
                    data: (data) => _TrendBarChart(data: data, range: _range, vc: vc),
                    loading: () => const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: VerLinkColors.primary)),
                    ),
                    error: (_, __) => const SizedBox(height: 80),
                  ),
                ),
                const SizedBox(height: 12),
                platformsAsync!.when(
                  data: (platforms) => platforms.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            _SectionCard(
                              title: s.statsPlatformsSection,
                              vc: vc,
                              child: _PlatformBreakdown(
                                platforms: platforms.take(5).toList(),
                                vc: vc,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                _SectionCard(
                  title: s.statsActivityYear,
                  vc: vc,
                  child: yearAsync!.when(
                    data: (yearData) => _ActivityHeatmap(data: yearData, vc: vc),
                    loading: () => const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: VerLinkColors.primary)),
                    ),
                    error: (_, __) => const SizedBox(height: 80),
                  ),
                ),
                const SizedBox(height: 12),
                _AchievementsSection(stats: stats, streak: streak, vc: vc, s: s),
                const SizedBox(height: 12),
              ] else ...[
                _PremiumLockCard(vc: vc, s: s, onTap: _goToPaywall),
                const SizedBox(height: 12),
              ],
              // Favorites + top platform card
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: s.statsFavorites,
                      value: stats.favorites,
                      icon: Icons.star_rounded,
                      vc: vc,
                    ),
                  ),
                  if (stats.topPlatform != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlatformCard(
                        platform: stats.topPlatform!,
                        label: s.statsTopPlatform,
                        vc: vc,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _goToPaywall() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
  }

  void _shareStats(AppStrings s) {
    final statsAsync = ref.read(linkStatsProvider);
    final streak = ref.read(streakProvider);
    statsAsync.whenData((stats) {
      final score = _computeScore(stats, streak);
      final text = '📊 ${s.statsTitle}\n'
          '🔗 ${stats.total} ${s.statsTotalLinks}\n'
          '⚡ ${s.statsScore}: $score/100\n'
          '🔥 ${s.statsStreak}: $streak ${s.statsStreakDays}\n'
          '#VerLink';
      SharePlus.instance.share(ShareParams(text: text));
    });
  }

  static int _computeScore(LinkStats stats, int streak) {
    if (stats.total == 0) return 0;
    final ratio = stats.reviewed / stats.total;
    final streakFactor = (streak / 30).clamp(0.0, 1.0);
    final favFactor = stats.favorites > 0 ? 1.0 : 0.0;
    return ((ratio * 60) + (streakFactor * 30) + (favFactor * 10)).round().clamp(0, 100);
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return VerLinkColors.primary;
    if (score >= 50) return const Color(0xFFF59E0B);
    return VerLinkColors.error;
  }
}

// ── Time range selector ────────────────────────────────────────────────────

class _TimeRangeSelector extends StatelessWidget {
  final _TimeRange range;
  final VeLinkSemanticColors vc;
  final AppStrings s;
  final ValueChanged<_TimeRange> onChanged;

  const _TimeRangeSelector({
    required this.range,
    required this.vc,
    required this.s,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: vc.surface,
        border: Border(bottom: BorderSide(color: vc.outline.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          _Pill(
            label: s.statsPeriodWeek,
            selected: range == _TimeRange.week,
            vc: vc,
            onTap: () => onChanged(_TimeRange.week),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: s.statsPeriodMonth,
            selected: range == _TimeRange.month,
            vc: vc,
            onTap: () => onChanged(_TimeRange.month),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VeLinkSemanticColors vc;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.vc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? VerLinkColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? VerLinkColors.primary : vc.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : vc.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VeLinkSemanticColors vc;

  const _SectionCard({required this.title, required this.child, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: vc.shadow06, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: vc.textPrimary),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Trend bar chart ─────────────────────────────────────────────────────────

class _TrendBarChart extends StatelessWidget {
  final List<DayCount> data;
  final _TimeRange range;
  final VeLinkSemanticColors vc;

  const _TrendBarChart({required this.data, required this.range, required this.vc});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 80);

    final maxCount = data.map((d) => d.count).fold(0, max);

    if (maxCount == 0) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No hay datos aún',
            style: TextStyle(color: vc.textTertiary, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final ratio = d.count / maxCount;
          final barH = 60 * ratio + (d.count > 0 ? 4.0 : 2.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barH,
                    decoration: BoxDecoration(
                      color: d.count > 0
                          ? VerLinkColors.primary
                          : vc.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label(d.date, range),
                    style: TextStyle(fontSize: 9, color: vc.textTertiary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _label(DateTime date, _TimeRange range) {
    if (range == _TimeRange.month) {
      return (date.day % 5 == 0 || date.day == 1) ? '${date.day}' : '';
    }
    const abbr = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return abbr[date.weekday - 1];
  }
}

// ── Platform breakdown ──────────────────────────────────────────────────────

const _kPlatformColors = [
  Color(0xFFEF4444),
  Color(0xFF3B82F6),
  Color(0xFFF97316),
  Color(0xFF22C55E),
  Color(0xFFA855F7),
];

class _PlatformBreakdown extends StatelessWidget {
  final List<PlatformCount> platforms;
  final VeLinkSemanticColors vc;

  const _PlatformBreakdown({required this.platforms, required this.vc});

  @override
  Widget build(BuildContext context) {
    final total = platforms.fold(0, (s, p) => s + p.count);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _DonutPainter(platforms: platforms, total: total),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: platforms.asMap().entries.map((e) {
              final p = e.value;
              final pct = (p.count / total * 100).round();
              final color = _kPlatformColors[e.key % _kPlatformColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.platform,
                        style: TextStyle(fontSize: 12, color: vc.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$pct%', style: TextStyle(fontSize: 12, color: vc.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<PlatformCount> platforms;
  final int total;

  const _DonutPainter({required this.platforms, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;
    for (int i = 0; i < platforms.length; i++) {
      final sweep = 2 * pi * platforms[i].count / total;
      paint.color = _kPlatformColors[i % _kPlatformColors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.06,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

// ── Activity heatmap ────────────────────────────────────────────────────────

class _ActivityHeatmap extends StatefulWidget {
  final List<DayCount> data;
  final VeLinkSemanticColors vc;

  const _ActivityHeatmap({required this.data, required this.vc});

  @override
  State<_ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<_ActivityHeatmap> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Saltar al final en el primer frame para mostrar las semanas más recientes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox(height: 80);

    // Alinear el primer dato con su día de la semana real.
    // weekday en Dart: 1=Lun … 7=Dom → offset 0-indexed: 0=Lun, 6=Dom.
    final offset = widget.data.first.date.weekday - 1;

    // Semanas necesarias para encajar todos los datos con el offset del inicio.
    final totalWeeks = ((widget.data.length + offset) / 7).ceil();

    return SingleChildScrollView(
      key: const ValueKey('heatmap_scroll'),
      controller: _scrollCtrl,
      scrollDirection: Axis.horizontal,
      child: Row(
        key: const ValueKey('heatmap_grid'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(totalWeeks, (week) {
          return Column(
            children: List.generate(7, (day) {
              final idx = week * 7 + day - offset;
              final isValid = idx >= 0 && idx < widget.data.length;
              final count = isValid ? widget.data[idx].count : 0;
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  // Celdas fuera del rango de datos son transparentes.
                  color: isValid ? _cellColor(count) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Color _cellColor(int count) {
    if (count == 0) return widget.vc.outline.withValues(alpha: 0.15);
    if (count <= 2) return VerLinkColors.primary.withValues(alpha: 0.35);
    if (count <= 4) return VerLinkColors.primary.withValues(alpha: 0.65);
    return VerLinkColors.primary;
  }
}

// ── Reused cards from Phase 1 ───────────────────────────────────────────────

class _AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;

  const _AnimatedCounter({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, v, __) => Text(v.round().toString(), style: style),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VeLinkSemanticColors vc;
  final String? suffix;

  const _HeroCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.vc,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: vc.shadow06, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AnimatedCounter(
                value: value,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: vc.textPrimary),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(suffix!, style: TextStyle(fontSize: 12, color: vc.textSecondary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: vc.textSecondary)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final VeLinkSemanticColors vc;
  final bool small;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.vc,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(small ? 12 : 16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: vc.shadow06, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: VerLinkColors.primary),
          const SizedBox(height: 8),
          _AnimatedCounter(
            value: value,
            style: TextStyle(
              fontSize: small ? 22 : 28,
              fontWeight: FontWeight.w800,
              color: vc.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: vc.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReviewRatioCard extends StatelessWidget {
  final int reviewed;
  final int total;
  final int pct;
  final VeLinkSemanticColors vc;
  final AppStrings s;

  const _ReviewRatioCard({
    required this.reviewed,
    required this.total,
    required this.pct,
    required this.vc,
    required this.s,
  });

  Color get _barColor {
    if (pct >= 80) return VerLinkColors.primary;
    if (pct >= 50) return const Color(0xFFF59E0B);
    return VerLinkColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: vc.shadow06, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.statsReviewRate,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: vc.textPrimary)),
              Text('$pct%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _barColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? reviewed / total : 0,
              backgroundColor: vc.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$reviewed / $total ${s.statsReviewed.toLowerCase()}',
            style: TextStyle(fontSize: 12, color: vc.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String platform;
  final String label;
  final VeLinkSemanticColors vc;

  const _PlatformCard({required this.platform, required this.label, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: vc.shadow06, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.public_rounded, size: 18, color: VerLinkColors.primary),
          const SizedBox(height: 8),
          Text(platform,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: vc.textPrimary)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: vc.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Premium lock card ───────────────────────────────────────────────────────

class _PremiumLockCard extends StatelessWidget {
  final VeLinkSemanticColors vc;
  final AppStrings s;
  final VoidCallback onTap;

  const _PremiumLockCard({required this.vc, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VerLinkColors.primary.withValues(alpha: 0.08),
            const Color(0xFFEAB308).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VerLinkColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAB308), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.premiumStatsLocked,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: vc.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  s.premiumSubtitle,
                  style: TextStyle(fontSize: 12, color: vc.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: VerLinkColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: VerLinkColors.primary.withValues(alpha: 0.4)),
              ),
            ),
            onPressed: onTap,
            child: Text(s.premiumViewPlans, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Achievements ────────────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final LinkStats stats;
  final int streak;
  final VeLinkSemanticColors vc;
  final AppStrings s;

  const _AchievementsSection({
    required this.stats,
    required this.streak,
    required this.vc,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final badges = BadgeComputer.compute(stats, streak: streak);
    final earned = badges.where((b) => b.earned).toList();
    final milestone = BadgeComputer.nextMilestone(stats, streak: streak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: s.statsAchievements,
          vc: vc,
          child: earned.isEmpty
              ? Text(
                  'Guarda links para desbloquear logros',
                  style: TextStyle(fontSize: 13, color: vc.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: earned.map((b) => _BadgeChip(badge: b, vc: vc)).toList(),
                ),
        ),
        if (milestone != null) ...[
          const SizedBox(height: 12),
          _NextMilestoneCard(milestone: milestone, vc: vc, s: s),
        ],
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeData badge;
  final VeLinkSemanticColors vc;

  const _BadgeChip({required this.badge, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 14, color: badge.color),
          const SizedBox(width: 5),
          Text(
            badge.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge.color),
          ),
        ],
      ),
    );
  }
}

class _NextMilestoneCard extends StatelessWidget {
  final BadgeData milestone;
  final VeLinkSemanticColors vc;
  final AppStrings s;

  const _NextMilestoneCard({required this.milestone, required this.vc, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: vc.shadow06, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(milestone.icon, size: 18, color: milestone.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.statsNextMilestone,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: vc.textPrimary),
                ),
              ),
              Text(
                milestone.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: milestone.color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: milestone.progress,
              backgroundColor: vc.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${milestone.current} / ${milestone.target}',
            style: TextStyle(fontSize: 12, color: vc.textSecondary),
          ),
        ],
      ),
    );
  }
}
