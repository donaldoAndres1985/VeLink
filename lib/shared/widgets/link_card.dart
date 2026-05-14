import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/database.dart';
import '../../core/preferences/preferences_provider.dart';
import '../../features/capture/services/platform_detector.dart';
import '../../features/detail/screens/detail_screen.dart';

class LinkCard extends ConsumerWidget {
  final Link link;

  const LinkCard({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformInfo = PlatformInfo.forPlatform(PlatformDetector.detect(link.url));
    final theme = Theme.of(context);
    final s = ref.watch(appStringsProvider);

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
                        _buildPlatformBadge(platformInfo, s),
                        if (link.isFavorite) ...[
                          const SizedBox(width: 6),
                          Semantics(
                            label: s.favoriteSemantics,
                            child: const Icon(Icons.star, size: 13, color: Colors.amber),
                          ),
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
                      _cleanDisplayUrl(link.url),
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
                          s.timeAgo(link.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          label: s.openLinkTooltip,
                          button: true,
                          child: TextButton(
                            onPressed: () => launchUrl(
                              Uri.parse(link.url),
                              mode: LaunchMode.externalApplication,
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(44, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: Text(s.openLink),
                          ),
                        ),
                        _buildMenu(context, ref, s),
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

  Widget _buildMenu(BuildContext context, WidgetRef ref, appStrings) {
    final s = appStrings;
    final isFavorite = link.isFavorite;
    final isReviewed = link.isRead;

    return Semantics(
      label: s.linkMenuTooltip,
      button: true,
      child: PopupMenuButton<_LinkAction>(
        icon: const Icon(Icons.more_vert, size: 20),
        tooltip: s.linkMenuTooltip,
        onSelected: (action) => _handleAction(context, ref, action, s),
        padding: EdgeInsets.zero,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _LinkAction.toggleFavorite,
            child: Text(isFavorite ? s.removeFavorite : s.addFavorite),
          ),
          PopupMenuItem(
            value: _LinkAction.toggleReviewed,
            child: Text(isReviewed ? s.markPending : s.markReviewedAction),
          ),
          PopupMenuItem(
            value: _LinkAction.delete,
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, _LinkAction action, dynamic s) {
    final db = ref.read(databaseProvider);
    switch (action) {
      case _LinkAction.toggleFavorite:
        db.setLinkFavorite(link.id, !link.isFavorite);
        _snack(context, link.isFavorite ? s.removedFromFavorites : s.markedAsFavorite);
      case _LinkAction.toggleReviewed:
        db.setLinkReviewed(link.id, !link.isRead);
        _snack(context, link.isRead ? s.markedAsPending : s.markedAsReviewed);
      case _LinkAction.delete:
        db.deleteLink(link.id);
        _snack(context, s.linkDeleted);
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (link.previewImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(link.previewImagePath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        ),
      );
    }
    if (link.previewImageUrl != null) {
      final rawUrl = link.previewImageUrl!;
      final imageUrl = rawUrl.startsWith('//') ? 'https:$rawUrl' : rawUrl;
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
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

  Widget _buildPlatformBadge(PlatformInfo info, dynamic s) {
    return Semantics(
      label: s.platformSemantics(info.label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 12, color: info.color),
          const SizedBox(width: 3),
          Text(
            info.label,
            style: TextStyle(color: info.color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static String _cleanDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      final path = (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
      final query = uri.query.isEmpty ? '' : '?${uri.query}';
      return '$host$path$query';
    } catch (_) {
      return url;
    }
  }
}

enum _LinkAction { toggleFavorite, toggleReviewed, delete }
