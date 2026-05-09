import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../features/capture/providers/capture_provider.dart';
import 'create_tag_dialog.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Etiquetas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: tagsAsync.when(
        data: (tags) => tags.isEmpty
            ? const Center(child: Text('No hay etiquetas aún'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: tags.length,
                itemBuilder: (_, i) => _TagTile(tag: tags[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar etiquetas')),
      ),
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

class _TagTile extends ConsumerWidget {
  final Tag tag;

  const _TagTile({required this.tag});

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _hexToColor(tag.color),
        radius: 12,
      ),
      title: Text(tag.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref.read(databaseProvider).deleteTag(tag.id),
      ),
    );
  }
}
