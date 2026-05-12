import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/pending_provider.dart';

class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(pendingLinksProvider);
    final searchQuery = ref.watch(pendingSearchQueryProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.pendingTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: s.searchPending,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(pendingSearchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: linksAsync.when(
              skipLoadingOnRefresh: true,
              data: (allLinks) {
                final links = searchQuery.trim().isEmpty
                    ? allLinks
                    : allLinks.where((l) {
                        final q = searchQuery.toLowerCase();
                        return (l.title?.toLowerCase().contains(q) ?? false) ||
                            l.url.toLowerCase().contains(q) ||
                            l.platform.toLowerCase().contains(q);
                      }).toList();

                if (links.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: searchQuery.trim().isEmpty
                              ? s.noPendingLinks
                              : s.noResults,
                          child: Text(
                            searchQuery.trim().isEmpty
                                ? s.noPendingLinks
                                : s.noResults,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (searchQuery.trim().isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            s.noPendingDesc,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 12, top: 12, right: 12, bottom: 80),
                  itemCount: links.length,
                  itemBuilder: (_, i) => _PendingItem(link: links[i], s: s),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(s.errorLoadLinks)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingItem extends ConsumerWidget {
  final Link link;
  final dynamic s;

  const _PendingItem({required this.link, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinkCard(link: link),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: Text(s.markReviewed),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 6),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () =>
                ref.read(databaseProvider).setLinkReviewed(link.id, true),
          ),
        ),
      ],
    );
  }
}
