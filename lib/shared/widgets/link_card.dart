import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/database.dart';
import '../../core/preferences/preferences_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/capture/services/platform_detector.dart';
import '../../features/detail/screens/detail_screen.dart';

class LinkCard extends ConsumerWidget {
  final Link link;

  const LinkCard({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformInfo =
        PlatformInfo.forPlatform(PlatformDetector.detect(link.url));
    final s = ref.watch(appStringsProvider);

    return Semantics(
      label: link.title ?? link.url,
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: VerLinkColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: VerLinkColors.shadow06,
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: VerLinkColors.shadow08,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailScreen(link: link)),
              ),
              splashColor: VerLinkColors.green.withAlpha(20),
              highlightColor: VerLinkColors.softSurface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildThumbnail(context, platformInfo),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlatformBadge(platformInfo, s),
                          const SizedBox(height: 6),
                          Text(
                            link.title ??
                                Uri.tryParse(link.url)?.host ??
                                link.url,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: VerLinkColors.textPrimary,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cleanDisplayUrl(link.url),
                            style: const TextStyle(
                              color: VerLinkColors.greenSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                s.timeAgo(link.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: VerLinkColors.textTertiary,
                                ),
                              ),
                              if (link.isFavorite) ...[
                                const SizedBox(width: 6),
                                Semantics(
                                  label: s.favoriteSemantics,
                                  child: const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Color(0xFFD89B3C),
                                  ),
                                ),
                              ],
                              if (link.remindAt != null) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.alarm_rounded,
                                  size: 13,
                                  color: VerLinkColors.green,
                                ),
                              ],
                              const Spacer(),
                              _buildOpenButton(s),
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
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, PlatformInfo platformInfo) {
    Widget content;

    if (link.previewImagePath != null) {
      content = Image.file(
        File(link.previewImagePath!),
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _buildPlaceholder(context, platformInfo),
      );
    } else if (link.previewImageUrl != null) {
      final rawUrl = link.previewImageUrl!;
      final imageUrl =
          rawUrl.startsWith('//') ? 'https:$rawUrl' : rawUrl;
      content = Image.network(
        imageUrl,
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _buildPlaceholder(context, platformInfo),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _buildShimmer();
        },
      );
    } else {
      return _buildPlaceholder(context, platformInfo);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 78, height: 78, child: content),
    );
  }

  Widget _buildPlaceholder(BuildContext context, PlatformInfo platformInfo) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: VerLinkColors.softSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.link,
        size: 28,
        color: platformInfo.color.withAlpha(180),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: VerLinkColors.softSurface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildPlatformBadge(PlatformInfo info, dynamic s) {
    return Semantics(
      label: s.platformSemantics(info.label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: info.color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 11, color: info.color),
            const SizedBox(width: 4),
            Text(
              info.label,
              style: TextStyle(
                color: info.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenButton(dynamic s) {
    return Semantics(
      label: s.openLinkTooltip,
      button: true,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(link.url),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: VerLinkColors.primaryBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            s.openLink,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VerLinkColors.green,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref, dynamic s) {
    final isFavorite = link.isFavorite;
    final isReviewed = link.isRead;

    return Semantics(
      label: s.linkMenuTooltip,
      button: true,
      child: PopupMenuButton<_LinkAction>(
        icon: const Icon(
          Icons.more_vert,
          size: 18,
          color: VerLinkColors.textTertiary,
        ),
        tooltip: s.linkMenuTooltip,
        onSelected: (action) => _handleAction(context, ref, action, s),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: VerLinkColors.surface,
        elevation: 8,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _LinkAction.toggleFavorite,
            child: Row(
              children: [
                Icon(
                  isFavorite ? Icons.star_outline : Icons.star_rounded,
                  size: 18,
                  color: isFavorite
                      ? VerLinkColors.textTertiary
                      : const Color(0xFFD89B3C),
                ),
                const SizedBox(width: 10),
                Text(isFavorite ? s.removeFavorite : s.addFavorite),
              ],
            ),
          ),
          PopupMenuItem(
            value: _LinkAction.toggleReviewed,
            child: Row(
              children: [
                Icon(
                  isReviewed
                      ? Icons.schedule_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: VerLinkColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(isReviewed ? s.markPending : s.markReviewedAction),
              ],
            ),
          ),
          PopupMenuItem(
            value: _LinkAction.delete,
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: VerLinkColors.error,
                ),
                const SizedBox(width: 10),
                Text(
                  s.delete,
                  style: const TextStyle(color: VerLinkColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(
      BuildContext context, WidgetRef ref, _LinkAction action, dynamic s) {
    final db = ref.read(databaseProvider);
    switch (action) {
      case _LinkAction.toggleFavorite:
        db.setLinkFavorite(link.id, !link.isFavorite);
        _snack(
            context,
            link.isFavorite
                ? s.removedFromFavorites
                : s.markedAsFavorite);
      case _LinkAction.toggleReviewed:
        db.setLinkReviewed(link.id, !link.isRead);
        _snack(context,
            link.isRead ? s.markedAsPending : s.markedAsReviewed);
      case _LinkAction.delete:
        db.deleteLink(link.id);
        _snack(context, s.linkDeleted);
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _cleanDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      final path =
          (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
      final query = uri.query.isEmpty ? '' : '?${uri.query}';
      return '$host$path$query';
    } catch (_) {
      return url;
    }
  }
}

enum _LinkAction { toggleFavorite, toggleReviewed, delete }
