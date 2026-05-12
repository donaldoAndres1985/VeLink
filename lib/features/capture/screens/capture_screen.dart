import 'dart:io';
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
    final platformInfo =
        PlatformInfo.forPlatform(PlatformDetector.detect(widget.url));

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlatformBadge(platformInfo),
              const SizedBox(height: 14),
              TextField(
                key: const Key('title_field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ingresa el título...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) =>
                    ref.read(captureProvider.notifier).setTitle(v),
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
              const SizedBox(height: 20),
              _buildImageSection(context, state),
              const SizedBox(height: 16),
              _buildLinkSection(context),
              const SizedBox(height: 20),
              _buildTagsSection(context, state, tagsAsync),
              const SizedBox(height: 16),
              _buildFavoriteRow(context, state),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isSaving
                          ? null
                          : () {
                              ref.read(captureProvider.notifier).dismiss();
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
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
                              ref
                                  .read(captureProvider.notifier)
                                  .setUrl(widget.url);
                              try {
                                await ref
                                    .read(captureProvider.notifier)
                                    .saveLink();
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                }
                              } on DuplicateUrlException {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Este link ya está guardado'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: state.isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
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

  // ── Sección imagen ────────────────────────────────────────────────────────

  Widget _buildImageSection(BuildContext context, CaptureState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Imagen o captura'),
        const SizedBox(height: 8),
        _buildImageCard(context, state),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context, CaptureState state) {
    if (state.isPickingImage) {
      return _imageShell(
        context,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.pickImageError) {
      return _imageShell(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 28),
              const SizedBox(height: 6),
              Text(
                'Error al cargar imagen',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.read(captureProvider.notifier).clearPickedImage(),
                child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    final localPath = state.pickedImagePath;
    final remoteUrl =
        state.ogImageDismissed ? null : state.metadata?.imageUrl;

    if (localPath != null || remoteUrl != null) {
      return _buildSelectedImageCard(context, state, localPath, remoteUrl);
    }

    return _buildEmptyImageCard(context);
  }

  Widget _buildEmptyImageCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _imageShell(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: scheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              'Agregar imagen o screenshot',
              style:
                  TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 15),
                  label: const Text('Galería'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () =>
                      ref.read(captureProvider.notifier).pickFromGallery(),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined, size: 15),
                  label: const Text('Captura'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () =>
                      ref.read(captureProvider.notifier).pickFromCamera(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImageCard(BuildContext context, CaptureState state,
      String? localPath, String? remoteUrl) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: localPath != null
                ? Image.file(
                    File(localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(context),
                  )
                : Image.network(
                    remoteUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(context),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Cambiar'),
              style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 13)),
              onPressed: () => _showChangePicker(context),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Eliminar'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: () {
                if (localPath != null) {
                  ref.read(captureProvider.notifier).clearPickedImage();
                } else {
                  ref.read(captureProvider.notifier).dismissOgImage();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _imageShell(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _showChangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(captureProvider.notifier).pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Captura'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(captureProvider.notifier).pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Sección Link ──────────────────────────────────────────────────────────

  Widget _buildLinkSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Link'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.link, size: 14, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.url,
                  style: TextStyle(color: scheme.primary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

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

  // ── Favorito ──────────────────────────────────────────────────────────────

  Widget _buildFavoriteRow(BuildContext context, CaptureState state) {
    return Row(
      children: [
        Icon(
          Icons.star_outline,
          size: 20,
          color: state.isFavorite
              ? Colors.amber
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Marcar como favorito',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Switch(
          value: state.isFavorite,
          onChanged: (_) =>
              ref.read(captureProvider.notifier).toggleFavorite(),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
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
}
