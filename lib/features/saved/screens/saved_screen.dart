import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/saved_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(savedLinksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guardados')),
      body: linksAsync.when(
        data: (links) => links.isEmpty
            ? const Center(child: Text('No hay links guardados aún'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: links.length,
                itemBuilder: (_, i) => LinkCard(link: links[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar los links')),
      ),
    );
  }
}
