import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/home_provider.dart';
import '../../capture/screens/capture_screen.dart';
import '../../search/providers/search_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final linksAsync = ref.watch(filteredHomeLinksProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final filter = ref.watch(homeFilterProvider);

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
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          _buildFilterBar(context, ref, filter),
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

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, HomeFilter filter) {
    return SizedBox(
      height: 44,
      child: ListView(
        key: const Key('platform_filter'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: filter == HomeFilter.todos,
              onSelected: (_) {
                ref.read(homeFilterProvider.notifier).state = HomeFilter.todos;
                ref.read(selectedPlatformProvider.notifier).state = null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star_outline, size: 13),
                  SizedBox(width: 4),
                  Text('Prioritarios'),
                ],
              ),
              selected: filter == HomeFilter.prioritarios,
              onSelected: (_) => ref
                  .read(homeFilterProvider.notifier)
                  .state = HomeFilter.prioritarios,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.filter_list, size: 13),
                  SizedBox(width: 4),
                  Text('Filtrar'),
                ],
              ),
              onPressed: () => _showFilterSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PlatformFilterSheet(
        selectedPlatform: ref.read(selectedPlatformProvider),
        onSelect: (p) {
          ref.read(selectedPlatformProvider.notifier).state = p;
          ref.read(homeFilterProvider.notifier).state = HomeFilter.todos;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    _prefillFromClipboard(controller);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              tooltip: 'Pegar',
              onPressed: () async {
                try {
                  final data =
                      await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    controller.text = data!.text!.trim();
                    controller.selection = TextSelection.collapsed(
                        offset: controller.text.length);
                  }
                } catch (_) {}
              },
            ),
          ),
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

  void _prefillFromClipboard(TextEditingController controller) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) {
        controller.text = text;
        controller.selection =
            TextSelection.collapsed(offset: text.length);
      }
    } catch (_) {}
  }
}

const _kPlatforms = [
  (label: 'Todas', value: null),
  (label: 'YouTube', value: 'youtube'),
  (label: 'Instagram', value: 'instagram'),
  (label: 'Facebook', value: 'facebook'),
  (label: 'TikTok', value: 'tiktok'),
  (label: 'LinkedIn', value: 'linkedin'),
  (label: 'Twitter', value: 'twitter'),
  (label: 'GitHub', value: 'github'),
  (label: 'Web', value: 'web'),
];

class _PlatformFilterSheet extends StatelessWidget {
  final String? selectedPlatform;
  final ValueChanged<String?> onSelect;

  const _PlatformFilterSheet({
    required this.selectedPlatform,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtrar por plataforma',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kPlatforms.map((p) {
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selectedPlatform == p.value,
                  onSelected: (_) => onSelect(p.value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
