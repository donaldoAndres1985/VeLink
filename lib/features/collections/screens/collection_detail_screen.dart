import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/collection_providers.dart';

final _collectionSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

class CollectionDetailScreen extends ConsumerWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksInCollectionProvider(collection.id));
    final searchQuery = ref.watch(_collectionSearchQueryProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: Column(
        children: [
          Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: s.searchInCollection,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) =>
                    ref.read(_collectionSearchQueryProvider.notifier).state = v,
              ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 56,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.trim().isEmpty
                                ? s.noLinksInCollection
                                : s.noResults,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          if (searchQuery.trim().isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              s.noLinksInCollectionDesc,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 12,
                    top: 8,
                    right: 12,
                    bottom: 24,
                  ),
                  itemCount: links.length,
                  itemBuilder: (_, i) {
                    final link = links[i];
                    return Dismissible(
                      key: ValueKey(link.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.folder_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(databaseProvider)
                            .removeLinkFromCollection(link.id, collection.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.linkRemovedFromCollection),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      child: LinkCard(link: link),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(s.errorLoadCollections)),
            ),
          ),
        ],
      ),
    );
  }
}
