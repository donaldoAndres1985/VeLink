import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../features/capture/services/platform_detector.dart';
import '../providers/detail_provider.dart';

class DetailScreen extends ConsumerWidget {
  final Link link;

  const DetailScreen({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(linkTagsProvider(link.id));
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(link.url));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (link.previewImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  link.previewImageUrl!,
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
            if (link.title != null) ...[
              Text(
                link.title!,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              link.url,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
            if (link.description != null) ...[
              const SizedBox(height: 10),
              Text(link.description!, style: const TextStyle(fontSize: 14)),
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
          ],
        ),
      ),
    );
  }
}
