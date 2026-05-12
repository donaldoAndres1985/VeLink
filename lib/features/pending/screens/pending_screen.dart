import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/pending_provider.dart';

class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(pendingLinksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pendientes')),
      body: linksAsync.when(
        data: (links) => links.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay links pendientes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los links que aún no has revisado aparecen aquí.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 80),
                itemCount: links.length,
                itemBuilder: (_, i) => _PendingItem(link: links[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar los links')),
      ),
    );
  }
}

class _PendingItem extends ConsumerWidget {
  final Link link;

  const _PendingItem({required this.link});

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
            label: const Text('Marcar revisado'),
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
