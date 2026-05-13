import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/home_provider.dart';
import '../../capture/screens/capture_screen.dart';
import '../../search/providers/search_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

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
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final linksAsync = ref.watch(filteredHomeLinksProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final filter = ref.watch(homeFilterProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.homeTitle)),
      floatingActionButton: Semantics(
        label: s.addLink,
        button: true,
        child: FloatingActionButton(
          key: const Key('add_link_fab'),
          onPressed: () => _handleFabTap(context),
          tooltip: s.addLink,
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.searchLinks,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          _buildFilterBar(context, ref, filter, s),
          Expanded(
            child: query.trim().isEmpty
                ? linksAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (links) => links.isEmpty
                        ? Center(
                            child: Semantics(
                              label: s.noLinksYet,
                              child: Text(s.noLinksYet),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                                left: 12, top: 12, right: 12, bottom: kBottomNavigationBarHeight + 56.0 + 24.0),
                            itemCount: links.length,
                            itemBuilder: (_, i) => LinkCard(link: links[i]),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        Center(child: Text(s.errorLoadLinks)),
                  )
                : searchAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (links) => links.isEmpty
                        ? Center(child: Text(s.noResults))
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                                left: 12, top: 12, right: 12, bottom: kBottomNavigationBarHeight + 56.0 + 24.0),
                            itemCount: links.length,
                            itemBuilder: (_, i) => LinkCard(link: links[i]),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        Center(child: Text(s.errorSearch)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, HomeFilter filter, dynamic s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: _FilterBtn(
              label: s.filterAll,
              selected: filter == HomeFilter.todos,
              onTap: () {
                ref.read(homeFilterProvider.notifier).state = HomeFilter.todos;
                ref.read(selectedPlatformProvider.notifier).state = null;
                _clearSearch();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterBtn(
              label: s.filterFavorites,
              leadingIcon: Icons.star_outline,
              selected: filter == HomeFilter.favoritos,
              onTap: () => ref.read(homeFilterProvider.notifier).state =
                  HomeFilter.favoritos,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterBtn(
              label: s.filterPlatform,
              leadingIcon: Icons.filter_list,
              onTap: () => _showFilterSheet(context, ref, s),
            ),
          ),
        ],
      ),
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

  void _handleFabTap(BuildContext context) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CaptureScreen(url: text)),
        );
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    _showAddLinkDialog(context);
  }

  void _showAddLinkDialog(BuildContext context) {
    final s = ref.read(appStringsProvider);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addLink),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              tooltip: s.paste,
              onPressed: () async {
                try {
                  final data =
                      await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    controller.text = data!.text!.trim();
                    controller.selection = TextSelection.collapsed(
                        offset: controller.text.length);
                  }
                } catch (_) {}
              },
            ),
          ),
          onSubmitted: (url) {
            Navigator.pop(ctx);
            final trimmed = url.trim();
            if (trimmed.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CaptureScreen(url: trimmed)),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.pop(ctx);
              if (trimmed.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CaptureScreen(url: trimmed)),
                );
              }
            },
            child: Text(s.go),
          ),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.label,
    this.leadingIcon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: SizedBox(
        height: 40,
        child: Material(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 14,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(filterTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: platforms.map((p) {
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selectedPlatform == p.value,
                  onSelected: (_) => onSelect(p.value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
