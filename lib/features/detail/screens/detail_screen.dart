import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../features/capture/services/platform_detector.dart';
import '../providers/detail_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Link link;

  const DetailScreen({super.key, required this.link});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.link.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    ref.read(databaseProvider).updateLinkNotes(widget.link.id, notes);
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(linkTagsProvider(widget.link.id));
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(widget.link.url));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.link.previewImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.link.previewImageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(platformInfo.icon, size: 16, color: platformInfo.color),
                const SizedBox(width: 6),
                Text(
                  platformInfo.label,
                  style: TextStyle(
                    color: platformInfo.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.link.title != null) ...[
              Text(
                widget.link.title!,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.link.url,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir'),
                  onPressed: () => launchUrl(
                    Uri.parse(widget.link.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
            if (widget.link.description != null) ...[
              const SizedBox(height: 10),
              Text(widget.link.description!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 16),
            const Text(
              'Etiquetas',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            tagsAsync.when(
              data: (tags) => tags.isEmpty
                  ? const Text('Sin etiquetas', style: TextStyle(fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      children: tags
                          .map((t) => Chip(label: Text(t.name)))
                          .toList(),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notas',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Escribe tus notas aquí...',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveNotes,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
