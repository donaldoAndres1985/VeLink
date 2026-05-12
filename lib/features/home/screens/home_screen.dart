import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/home_provider.dart';
import '../../capture/screens/capture_screen.dart';
import '../../pending/providers/pending_provider.dart';
import '../../priority/providers/priority_provider.dart';
import '../../search/providers/search_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);

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
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          _buildFilterBar(context),
          Expanded(
            child: query.trim().isEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: const [
                      _AllLinksPage(),
                      _PriorityPage(),
                      _PendingPage(),
                    ],
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

  Widget _buildFilterBar(BuildContext context) {
    final idx = _tabController.index;
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
              selected: idx == 0,
              onSelected: (_) => _tabController.animateTo(0),
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
              selected: idx == 1,
              onSelected: (_) => _tabController.animateTo(1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.schedule_outlined, size: 13),
                  SizedBox(width: 4),
                  Text('Pendientes'),
                ],
              ),
              selected: idx == 2,
              onSelected: (_) => _tabController.animateTo(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Filtrar'),
                  SizedBox(width: 4),
                  Icon(Icons.filter_list, size: 13),
                ],
              ),
              onPressed: () => _showFilterSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PlatformFilterSheet(
        selectedPlatform: ref.read(selectedPlatformProvider),
        onSelect: (p) {
          ref.read(selectedPlatformProvider.notifier).state = p;
          Navigator.pop(ctx);
          _tabController.animateTo(0);
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

class _AllLinksPage extends ConsumerWidget {
  const _AllLinksPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(filteredHomeLinksProvider);
    return linksAsync.when(
      data: (links) => links.isEmpty
          ? const Center(child: Text('No hay links guardados aún'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: links.length,
              itemBuilder: (_, i) => LinkCard(link: links[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error al cargar los links')),
    );
  }
}

class _PriorityPage extends ConsumerWidget {
  const _PriorityPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(priorityLinksProvider);
    return linksAsync.when(
      data: (links) => links.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No hay links prioritarios',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: links.length,
              itemBuilder: (_, i) => LinkCard(link: links[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error al cargar')),
    );
  }
}

class _PendingPage extends ConsumerWidget {
  const _PendingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(pendingLinksProvider);
    return linksAsync.when(
      data: (links) => links.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No hay links pendientes',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: links.length,
              itemBuilder: (_, i) => LinkCard(link: links[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error al cargar')),
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
