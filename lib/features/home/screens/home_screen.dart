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
        onPressed: () => _handleFabTap(context),
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
                    skipLoadingOnRefresh: true,
                    data: (links) => links.isEmpty
                        ? const Center(child: Text('No hay links guardados aún'))
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 80),
                            itemCount: links.length,
                            itemBuilder: (_, i) => LinkCard(link: links[i]),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error al cargar los links')),
                  )
                : searchAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (links) => links.isEmpty
                        ? const Center(child: Text('Sin resultados'))
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 80),
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

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, HomeFilter filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: _FilterBtn(
              label: 'Todos',
              selected: filter == HomeFilter.todos,
              onTap: () {
                ref.read(homeFilterProvider.notifier).state = HomeFilter.todos;
                ref.read(selectedPlatformProvider.notifier).state = null;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterBtn(
              label: 'Favoritos',
              leadingIcon: Icons.star_outline,
              selected: filter == HomeFilter.favoritos,
              onTap: () => ref.read(homeFilterProvider.notifier).state =
                  HomeFilter.favoritos,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterBtn(
              label: 'Filtrar',
              leadingIcon: Icons.filter_list,
              onTap: () => _showFilterSheet(context, ref),
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

  void _handleFabTap(BuildContext context) {
    _showAddLinkDialog(context);
  }

  // Verifica el portapapeles luego de mostrar el dialog;
  // si hay una URL válida, cierra el dialog y navega directo a CaptureScreen.
  void _checkClipboardForCapture(BuildContext context) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CaptureScreen(url: text)),
        );
      }
    } catch (_) {}
  }

  void _showAddLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    _checkClipboardForCapture(context);

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
}

// Botón de filtro con ancho expandible (igual distribución horizontal)
class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.label,
    this.leadingIcon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: Material(
        color:
            selected ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 14,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
