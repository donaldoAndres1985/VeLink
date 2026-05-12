import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/home_provider.dart';
import '../../capture/screens/capture_screen.dart';
import '../../search/providers/search_provider.dart';

const _kPlatforms = [
  (label: 'Todos', value: null),
  (label: 'YouTube', value: 'youtube'),
  (label: 'Instagram', value: 'instagram'),
  (label: 'Facebook', value: 'facebook'),
  (label: 'TikTok', value: 'tiktok'),
  (label: 'LinkedIn', value: 'linkedin'),
  (label: 'Twitter', value: 'twitter'),
  (label: 'GitHub', value: 'github'),
  (label: 'Web', value: 'web'),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final linksAsync = ref.watch(filteredHomeLinksProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final selectedPlatform = ref.watch(selectedPlatformProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VeLink')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_link_fab'),
        onPressed: () => _showAddLinkDialog(context),
        child: const Icon(Icons.add),
      ),
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
          SizedBox(
            height: 44,
            child: ListView(
              key: const Key('platform_filter'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _kPlatforms.map((p) {
                final isSelected = selectedPlatform == p.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(p.label),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(selectedPlatformProvider.notifier).state =
                            isSelected ? null : p.value,
                  ),
                );
              }).toList(),
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error al buscar')),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://...'),
          onSubmitted: (url) {
            Navigator.pop(ctx);
            final trimmed = url.trim();
            if (trimmed.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CaptureScreen(url: trimmed)),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.pop(ctx);
              if (trimmed.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CaptureScreen(url: trimmed)),
                );
              }
            },
            child: const Text('Ir'),
          ),
        ],
      ),
    );
  }
}
