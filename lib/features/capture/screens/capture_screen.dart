import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/og_metadata.dart';
import '../providers/capture_provider.dart';
import '../services/platform_detector.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String url;

  const CaptureScreen({super.key, required this.url});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(captureProvider.notifier).fetchMetadata(widget.url);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(widget.url));

    // Pre-llenar el título con el metadata cuando llega (si el usuario no ha escrito nada)
    ref.listen<OgMetadata?>(
      captureProvider.select((s) => s.metadata),
      (prev, next) {
        if (next?.title != null && _titleController.text.isEmpty) {
          _titleController.text = next!.title!;
          _titleController.selection =
              TextSelection.collapsed(offset: next.title!.length);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Guardar link')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPreview(context, state.isFetchingMetadata, state.metadata?.imageUrl),
            const SizedBox(height: 12),
            _buildPlatformBadge(platformInfo),
            const SizedBox(height: 12),
            TextField(
              key: const Key('title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ingresa el título...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => ref.read(captureProvider.notifier).setTitle(value),
            ),
            if (state.metadata?.description != null) ...[
              const SizedBox(height: 8),
              Text(
                state.metadata!.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.url,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            _buildTagsSection(context, state, tagsAsync),
            const SizedBox(height: 16),
            _buildPriorityRow(context, state),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            ref.read(captureProvider.notifier).dismiss();
                            Navigator.pop(context);
                          },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            ref.read(captureProvider.notifier).setUrl(widget.url);
                            try {
                              await ref.read(captureProvider.notifier).saveLink();
                              if (context.mounted) {
                                Navigator.of(context).popUntil(
                                  (route) => route.isFirst,
                                );
                              }
                            } on DuplicateUrlException {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Este link ya está guardado'),
                                  ),
                                );
                              }
                            }
                          },
                    child: state.isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    CaptureState state,
    AsyncValue tagsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        tagsAsync.when(
          data: (tags) => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...tags.map((tag) => FilterChip(
                    label: Text(tag.name),
                    selected: state.selectedTagIds.contains(tag.id),
                    onSelected: (_) =>
                        ref.read(captureProvider.notifier).toggleTag(tag.id),
                  )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo'),
                onPressed: () => _showCreateTagDialog(context),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPriorityRow(BuildContext context, CaptureState state) {
    return Row(
      children: [
        Icon(
          Icons.star_outline,
          size: 20,
          color: state.isPriority
              ? Colors.amber
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Marcar como prioritario',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Switch(
          value: state.isPriority,
          onChanged: (_) => ref.read(captureProvider.notifier).togglePriority(),
        ),
      ],
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo tag'),
        content: TextField(
          key: const Key('tag_name_field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre del tag'),
          onSubmitted: (value) => _submitNewTag(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _submitNewTag(context, controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _submitNewTag(BuildContext context, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    ref.read(captureProvider.notifier).createTag(trimmed);
    Navigator.pop(context);
  }

  Widget _buildPreview(BuildContext context, bool isFetching, String? imageUrl) {
    if (isFetching) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        ),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlatformBadge(PlatformInfo info) {
    return Row(
      children: [
        Icon(info.icon, size: 16, color: info.color),
        const SizedBox(width: 6),
        Text(
          info.label,
          style: TextStyle(
            color: info.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.link,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
