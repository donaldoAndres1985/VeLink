import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/home_provider.dart';
import '../../search/providers/search_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final linksAsync = ref.watch(recentLinksProvider);
    final searchAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VeLink')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar links...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? linksAsync.when(
                    data: (links) => links.isEmpty
                        ? const Center(child: Text('No hay links guardados aún'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: links.length,
                            itemBuilder: (_, i) => LinkCard(link: links[i]),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error al cargar los links')),
                  )
                : searchAsync.when(
                    data: (links) => links.isEmpty
                        ? const Center(child: Text('Sin resultados'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: links.length,
                            itemBuilder: (_, i) => LinkCard(link: links[i]),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error al buscar')),
                  ),
          ),
        ],
      ),
    );
  }
}
