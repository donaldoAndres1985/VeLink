import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../shared/widgets/link_card.dart';
import '../../capture/providers/capture_provider.dart';
import '../providers/saved_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(filteredSavedLinksProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final selectedTagId = ref.watch(selectedTagIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guardados')),
      body: Column(
        children: [
          tagsAsync.when(
            data: (tags) => tags.isEmpty
                ? const SizedBox.shrink()
                : _TagFilterBar(tags: tags, selectedTagId: selectedTagId),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: linksAsync.when(
              data: (links) => links.isEmpty
                  ? const Center(child: Text('No hay links guardados aún'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: links.length,
                      itemBuilder: (_, i) => _DismissibleLinkCard(link: links[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Error al cargar los links')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleLinkCard extends ConsumerWidget {
  final Link link;

  const _DismissibleLinkCard({required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(link.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(databaseProvider).deleteLink(link.id);
      },
      child: LinkCard(link: link),
    );
  }
}

class _TagFilterBar extends ConsumerWidget {
  final List<Tag> tags;
  final int? selectedTagId;

  const _TagFilterBar({required this.tags, required this.selectedTagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: tags
            .map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag.name),
                    selected: selectedTagId == tag.id,
                    onSelected: (_) {
                      final notifier =
                          ref.read(selectedTagIdProvider.notifier);
                      notifier.state =
                          selectedTagId == tag.id ? null : tag.id;
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}
