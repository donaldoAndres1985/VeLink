import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/link_card.dart';
import '../../../shared/widgets/screen_header.dart';
import '../providers/home_provider.dart';
import '../../search/providers/search_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _searchFocused = false);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final linksAsync = ref.watch(filteredHomeLinksProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final filter = ref.watch(homeFilterProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(s),
            const SizedBox(height: 10),
            _buildSearchBar(s),
            _buildFilterBar(context, ref, filter, s),
            Expanded(
              child: query.trim().isEmpty
                  ? linksAsync.when(
                      skipLoadingOnRefresh: true,
                      data: (links) => links.isEmpty
                          ? _buildEmptyState(context, s)
                          : _buildList(links),
                      loading: () => _buildSkeletonList(),
                      error: (_, __) => _buildError(s.errorLoadLinks),
                    )
                  : searchAsync.when(
                      skipLoadingOnRefresh: true,
                      data: (links) => links.isEmpty
                          ? _buildSearchEmpty(context, s)
                          : _buildList(links),
                      loading: () => _buildSkeletonList(),
                      error: (_, __) => _buildError(s.errorSearch),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic s) {
    return ScreenHeader(title: s.navLinks, subtitle: s.homeSubtitle);
  }

  Widget _buildSearchBar(dynamic s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: VerLinkColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: VerLinkColors.shadow08,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _searchFocused
                ? VerLinkColors.green
                : VerLinkColors.outline,
            width: _searchFocused ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: VerLinkColors.textTertiary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 14,
                  color: VerLinkColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: s.searchLinks,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  isDense: true,
                  filled: false,
                ),
                onTap: () => setState(() => _searchFocused = true),
                onChanged: (v) {
                  ref.read(searchQueryProvider.notifier).state = v;
                },
                onTapOutside: (_) {
                  setState(() => _searchFocused = false);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: VerLinkColors.textTertiary,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: VerLinkColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, HomeFilter filter, dynamic s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PremiumFilterChip(
              label: s.filterAll,
              selected: filter == HomeFilter.todos,
              onTap: () {
                ref.read(homeFilterProvider.notifier).state = HomeFilter.todos;
                ref.read(selectedPlatformProvider.notifier).state = null;
                _clearSearch();
              },
            ),
            const SizedBox(width: 8),
            _PremiumFilterChip(
              label: s.filterFavorites,
              icon: Icons.star_rounded,
              selected: filter == HomeFilter.favoritos,
              onTap: () => ref.read(homeFilterProvider.notifier).state =
                  HomeFilter.favoritos,
            ),
            const SizedBox(width: 8),
            _PremiumFilterChip(
              label: s.filterPlatform,
              icon: Icons.filter_list_rounded,
              selected: ref.watch(selectedPlatformProvider) != null,
              onTap: () => _showFilterSheet(context, ref, s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List links) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        AppTheme.contentBottomPaddingFab,
      ),
      itemCount: links.length,
      itemBuilder: (_, i) => LinkCard(link: links[i]),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [VerLinkColors.greenLight, VerLinkColors.softSurface],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.link_rounded,
                size: 36,
                color: VerLinkColors.green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.noLinksYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: VerLinkColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: s.noLinksYet,
              child: const Text(
                'Toca el botón + para guardar\ntu primer link.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: VerLinkColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchEmpty(BuildContext context, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: VerLinkColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              s.noResults,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VerLinkColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta con otro término de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: VerLinkColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: VerLinkColors.textSecondary),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, dynamic s) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PlatformFilterSheet(
        selectedPlatform: ref.read(selectedPlatformProvider),
        filterTitle: s.filterByPlatform,
        platformAll: s.platformAll,
        onSelect: (p) {
          ref.read(selectedPlatformProvider.notifier).state = p;
          ref.read(homeFilterProvider.notifier).state = HomeFilter.todos;
          Navigator.pop(ctx);
        },
      ),
    );
  }

}

// ── Premium filter chip ───────────────────────────────────────────────────────

class _PremiumFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumFilterChip({
    required this.label,
    this.icon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? VerLinkColors.primaryBlack : VerLinkColors.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected ? VerLinkColors.primaryBlack : VerLinkColors.outline,
              width: 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: VerLinkColors.shadow12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? VerLinkColors.green
                      : VerLinkColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? VerLinkColors.green
                      : VerLinkColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VerLinkColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: VerLinkColors.shadow06,
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: VerLinkColors.softSurface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 18,
                    decoration: BoxDecoration(
                      color: VerLinkColors.softSurface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: VerLinkColors.softSurface,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 13,
                    decoration: BoxDecoration(
                      color: VerLinkColors.softSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Platform filter sheet ─────────────────────────────────────────────────────

const _kPlatforms = [
  (label: 'Todas', value: null),
  (label: 'YouTube', value: 'youtube'),
  (label: 'Instagram', value: 'instagram'),
  (label: 'Facebook', value: 'facebook'),
  (label: 'TikTok', value: 'tiktok'),
  (label: 'LinkedIn', value: 'linkedin'),
  (label: 'Twitter', value: 'twitter'),
  (label: 'GitHub', value: 'github'),
  (label: 'Web', value: 'web'),
];

class _PlatformFilterSheet extends StatelessWidget {
  final String? selectedPlatform;
  final String filterTitle;
  final String platformAll;
  final ValueChanged<String?> onSelect;

  const _PlatformFilterSheet({
    required this.selectedPlatform,
    required this.filterTitle,
    required this.platformAll,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final platforms = [
      (label: platformAll, value: null as String?),
      ..._kPlatforms.skip(1),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: VerLinkColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            Text(
              filterTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: VerLinkColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: platforms.map((p) {
                final isSelected = selectedPlatform == p.value;
                return GestureDetector(
                  onTap: () => onSelect(p.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VerLinkColors.primaryBlack
                          : VerLinkColors.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected
                            ? VerLinkColors.primaryBlack
                            : VerLinkColors.outline,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? VerLinkColors.green
                            : VerLinkColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
