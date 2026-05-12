import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../providers/collection_providers.dart';
import 'collection_detail_screen.dart';
import 'create_collection_dialog.dart';

class CollectionsContent extends ConsumerWidget {
  const CollectionsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(allCollectionsProvider);
    final s = ref.watch(appStringsProvider);

    return collectionsAsync.when(
      data: (collections) => collections.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noCollectionsYet,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.noCollectionsDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: collections.length,
              itemBuilder: (_, i) => _CollectionCard(collection: collections[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(ref.read(appStringsProvider).errorLoadCollections),
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final Collection collection;

  const _CollectionCard({required this.collection});

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(collectionLinkCountProvider(collection.id));
    final s = ref.watch(appStringsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(collection: collection),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ListTile(
            leading: Semantics(
              label: collection.name,
              child: CircleAvatar(
                backgroundColor: _hexToColor(collection.color),
                radius: 20,
                child: Icon(
                  _iconData(collection.icon),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            title: Text(collection.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (collection.description != null &&
                    collection.description!.isNotEmpty) ...[
                  Text(
                    collection.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                countAsync.when(
                  data: (count) => Text(
                    s.collectionLinkCount(count),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: s.editCollection,
                  onPressed: () => _showEditDialog(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: s.delete,
                  onPressed: () => _confirmDelete(context, ref, s),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconData(String icon) {
    switch (icon) {
      case 'star':
        return Icons.star_outline;
      case 'code':
        return Icons.code;
      case 'work':
        return Icons.work_outline;
      case 'book':
        return Icons.book_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'link':
        return Icons.link;
      case 'heart':
        return Icons.favorite_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateCollectionDialog(existing: collection),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCollectionTitle),
        content: Text(s.confirmDeleteCollection(collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(databaseProvider).deleteCollection(collection.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}
