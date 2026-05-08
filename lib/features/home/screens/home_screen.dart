import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../capture/services/platform_detector.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(recentLinksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VeLink')),
      body: linksAsync.when(
        data: (links) => links.isEmpty
            ? const Center(child: Text('No hay links guardados aún'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: links.length,
                itemBuilder: (_, i) => _LinkCard(link: links[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar los links')),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final Link link;

  const _LinkCard({required this.link});

  @override
  Widget build(BuildContext context) {
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(link.url));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlatformBadge(context, platformInfo),
                  const SizedBox(height: 4),
                  if (link.title != null)
                    Text(
                      link.title!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    link.url,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (link.previewImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          link.previewImageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        ),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.link,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlatformBadge(BuildContext context, PlatformInfo info) {
    return Row(
      children: [
        Icon(info.icon, size: 14, color: info.color),
        const SizedBox(width: 4),
        Text(
          info.label,
          style: TextStyle(
            color: info.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
