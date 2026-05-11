import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../features/capture/providers/capture_provider.dart';
import '../../../features/capture/services/platform_detector.dart';
import '../../../features/notifications/providers/notification_provider.dart';
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

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.link.remindAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.link.remindAt ?? now),
    );
    if (time == null || !mounted) return;
    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final title = widget.link.title ?? widget.link.url;
    await ref
        .read(linkReminderUseCaseProvider)
        .schedule(linkId: widget.link.id, title: title, scheduledAt: scheduledAt);
  }

  Future<void> _clearReminder() async {
    await ref.read(linkReminderUseCaseProvider).cancel(linkId: widget.link.id);
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatRemindAt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(watchLinkTagsProvider(widget.link.id));
    final allTagsAsync = ref.watch(allTagsProvider);
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(widget.link.url));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.link.previewImageUrl != null
                  ? Image.network(
                      widget.link.previewImageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(context),
                    )
                  : _buildImagePlaceholder(context),
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
            Text(
              widget.link.title ??
                  Uri.tryParse(widget.link.url)?.host ??
                  widget.link.url,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 6),
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
            allTagsAsync.when(
              data: (allTags) => allTags.isEmpty
                  ? const Text('Sin etiquetas', style: TextStyle(fontSize: 13))
                  : tagsAsync.when(
                      data: (linkTags) {
                        final linkTagIds = linkTags.map((t) => t.id).toSet();
                        return Wrap(
                          spacing: 8,
                          children: allTags
                              .map((tag) => FilterChip(
                                    label: Text(tag.name),
                                    selected: linkTagIds.contains(tag.id),
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref.read(databaseProvider).addTagToLink(widget.link.id, tag.id);
                                      } else {
                                        ref.read(databaseProvider).removeTagFromLink(widget.link.id, tag.id);
                                      }
                                    },
                                  ))
                              .toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
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
            const SizedBox(height: 16),
            const Text(
              'Recordatorio',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (widget.link.remindAt != null) ...[
              Text(
                _formatRemindAt(widget.link.remindAt!),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.alarm_off, size: 16),
                label: const Text('Eliminar recordatorio'),
                onPressed: _clearReminder,
              ),
            ] else
              OutlinedButton.icon(
                icon: const Icon(Icons.alarm_add, size: 16),
                label: const Text('Agregar recordatorio'),
                onPressed: _pickReminder,
              ),
          ],
        ),
      ),
    );
  }
}
