import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../features/capture/providers/capture_provider.dart';
import '../providers/tag_providers.dart';
import 'create_tag_dialog.dart';
import 'edit_tag_dialog.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.tagsTitle)),
      floatingActionButton: Semantics(
        label: s.createTagTitle,
        button: true,
        child: FloatingActionButton(
          onPressed: () => _showCreateDialog(context),
          tooltip: s.createTagTitle,
          child: const Icon(Icons.add),
        ),
      ),
      body: const TagsContent(),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateTagDialog(),
    );
  }
}

class TagsContent extends ConsumerWidget {
  const TagsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final s = ref.watch(appStringsProvider);

    return tagsAsync.when(
      data: (tags) => tags.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noTagsYet,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.noTagsDesc,
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
              itemCount: tags.length,
              itemBuilder: (_, i) => _TagCard(tag: tags[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(ref.read(appStringsProvider).errorLoadTags),
      ),
    );
  }
}

class _TagCard extends ConsumerWidget {
  final Tag tag;

  const _TagCard({required this.tag});

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(tagLinkCountProvider(tag.id));
    final s = ref.watch(appStringsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Semantics(
          label: tag.name,
          child: CircleAvatar(
            backgroundColor: _hexToColor(tag.color),
            radius: 14,
          ),
        ),
        title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: countAsync.when(
          data: (count) => Text(
            s.tagLinkCount(count),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: s.editTagTooltip,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: s.editTagTooltip,
                onPressed: () => _showEditDialog(context),
              ),
            ),
            Semantics(
              label: s.deleteTagTitle,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: s.deleteTagTitle,
                onPressed: () => _confirmDelete(context, ref, s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditTagDialog(tag: tag),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteTagTitle),
        content: Text(s.confirmDeleteTag(tag.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(databaseProvider).deleteTag(tag.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}
