import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../features/capture/services/platform_detector.dart';
import '../../features/detail/screens/detail_screen.dart';

class LinkCard extends ConsumerWidget {
  final Link link;

  const LinkCard({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(link.url));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(link: link)),
        ),
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
                    _buildPlatformBadge(platformInfo),
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
              IconButton(
                icon: Icon(
                  link.priority == 1 ? Icons.star : Icons.star_outline,
                  color: link.priority == 1 ? Colors.amber : null,
                ),
                onPressed: () {
                  final newPriority = link.priority == 1 ? 0 : 1;
                  ref.read(databaseProvider).setLinkPriority(link.id, newPriority);
                },
              ),
            ],
          ),
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

  Widget _buildPlatformBadge(PlatformInfo info) {
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
