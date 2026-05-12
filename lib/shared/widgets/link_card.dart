import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/database.dart';
import '../../features/capture/services/platform_detector.dart';
import '../../features/detail/screens/detail_screen.dart';

class LinkCard extends ConsumerWidget {
  final Link link;

  const LinkCard({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(link.url));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(link: link)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildThumbnail(context),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPlatformBadge(platformInfo),
                        if (link.isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star, size: 13, color: Colors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      link.title ?? Uri.tryParse(link.url)?.host ?? link.url,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.url,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _timeAgo(link.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(link.url),
                            mode: LaunchMode.externalApplication,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Abrir'),
                        ),
                        _buildMenu(context, ref),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    final isFavorite = link.isFavorite;
    final isReviewed = link.isRead;

    return PopupMenuButton<_LinkAction>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) => _handleAction(context, ref, action),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _LinkAction.toggleFavorite,
          child: Text(isFavorite ? 'Quitar favorito' : 'Marcar favorito'),
        ),
        PopupMenuItem(
          value: _LinkAction.toggleReviewed,
          child: Text(isReviewed ? 'Marcar pendiente' : 'Marcar revisado'),
        ),
        const PopupMenuItem(
          value: _LinkAction.delete,
          child: Text('Eliminar'),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, _LinkAction action) {
    final db = ref.read(databaseProvider);
    switch (action) {
      case _LinkAction.toggleFavorite:
        db.setLinkFavorite(link.id, !link.isFavorite);
        _snack(
          context,
          link.isFavorite ? 'Quitado de favoritos' : 'Marcado como favorito',
        );
      case _LinkAction.toggleReviewed:
        db.setLinkReviewed(link.id, !link.isRead);
        _snack(
          context,
          link.isRead ? 'Marcado como pendiente' : 'Link marcado como revisado',
        );
      case _LinkAction.delete:
        db.deleteLink(link.id);
        _snack(context, 'Link eliminado');
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (link.previewImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          link.previewImageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        ),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.link,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlatformBadge(PlatformInfo info) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(info.icon, size: 12, color: info.color),
        const SizedBox(width: 3),
        Text(
          info.label,
          style: TextStyle(color: info.color, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) {
      final y = (diff.inDays / 365).floor();
      return 'Hace $y año${y > 1 ? "s" : ""}';
    }
    if (diff.inDays >= 30) {
      final m = (diff.inDays / 30).floor();
      return 'Hace $m mes${m > 1 ? "es" : ""}';
    }
    if (diff.inDays > 0) {
      return 'Hace ${diff.inDays} día${diff.inDays > 1 ? "s" : ""}';
    }
    if (diff.inHours > 0) {
      return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? "s" : ""}';
    }
    if (diff.inMinutes > 0) {
      return 'Hace ${diff.inMinutes} min';
    }
    return 'Ahora';
  }
}

enum _LinkAction { toggleFavorite, toggleReviewed, delete }
