import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/priority_provider.dart';

class PriorityScreen extends ConsumerWidget {
  const PriorityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(priorityLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prioritarios'),
        actions: [
          Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 16),
        ],
      ),
      body: linksAsync.when(
        data: (links) => links.isEmpty
            ? const Center(child: Text('No hay links prioritarios aún'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: links.length,
                itemBuilder: (_, i) => _PriorityLinkCard(link: links[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error al cargar los links')),
      ),
    );
  }
}

class _PriorityLinkCard extends StatelessWidget {
  final link;

  const _PriorityLinkCard({required this.link});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LinkCard(link: link),
        Positioned(
          top: 8,
          right: 8,
          child: Icon(Icons.star, color: Colors.amber, size: 16),
        ),
      ],
    );
  }
}
