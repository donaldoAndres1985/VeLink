import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/collection_providers.dart';
import '../../premium/screens/paywall_screen.dart';
import 'collection_detail_screen.dart';
import 'create_collection_dialog.dart';

class CollectionsContent extends ConsumerWidget {
  const CollectionsContent({super.key});

  static const _freeLimit = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(allCollectionsProvider);
    final s = ref.watch(appStringsProvider);
    final isPremium = ref.watch(premiumProvider);

    return collectionsAsync.when(
      data: (collections) => collections.isEmpty
          ? Builder(builder: (context) {
              final vc = VeLinkSemanticColors.of(context);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [vc.greenLight, vc.surfaceContainer],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          size: 36,
                          color: VerLinkColors.green,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        s.noCollectionsYet,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: vc.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.noCollectionsDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: vc.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
          : Builder(builder: (ctx) {
              final showBanner = !isPremium && collections.length >= _freeLimit;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  AppTheme.contentBottomPaddingFab,
                ),
                itemCount: collections.length + (showBanner ? 1 : 0),
                itemBuilder: (_, i) {
                  if (showBanner && i == collections.length) {
                    return _PremiumCollectionBanner(s: s);
                  }
                  return _CollectionCard(collection: collections[i]);
                },
              );
            }),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: VerLinkColors.green,
          strokeWidth: 2,
        ),
      ),
      error: (_, __) => Center(
        child: Builder(builder: (ctx) {
          final vc = VeLinkSemanticColors.of(ctx);
          return Text(
            ref.read(appStringsProvider).errorLoadCollections,
            style: TextStyle(color: vc.textSecondary),
          );
        }),
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final Collection collection;

  const _CollectionCard({required this.collection});

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = VeLinkSemanticColors.of(context);
    final countAsync = ref.watch(collectionLinkCountProvider(collection.id));
    final s = ref.watch(appStringsProvider);
    final collectionColor = _hexToColor(collection.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: vc.shadow06,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CollectionDetailScreen(collection: collection),
              ),
            ),
            splashColor: collectionColor.withAlpha(20),
            highlightColor: vc.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: collectionColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconData(collection.icon),
                      color: collectionColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: vc.textPrimary,
                          ),
                        ),
                        if (collection.description != null &&
                            collection.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            collection.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: vc.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        countAsync.when(
                          data: (count) => Text(
                            s.collectionLinkCount(count),
                            style: TextStyle(
                              fontSize: 12,
                              color: vc.textTertiary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        tooltip: s.editCollection,
                        onTap: () => _showEditDialog(context, ref),
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        tooltip: s.delete,
                        color: VerLinkColors.error,
                        onTap: () => _confirmDelete(context, ref, s),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconData(String icon) {
    switch (icon) {
      case 'star':
        return Icons.star_outline;
      case 'code':
        return Icons.code;
      case 'work':
        return Icons.work_outline;
      case 'book':
        return Icons.book_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'link':
        return Icons.link;
      case 'heart':
        return Icons.favorite_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateCollectionDialog(existing: collection),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCollectionTitle),
        content: Text(s.confirmDeleteCollection(collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: VerLinkColors.error),
            onPressed: () {
              ref.read(databaseProvider).deleteCollection(collection.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (color ?? vc.textTertiary).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? vc.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PremiumCollectionBanner extends StatelessWidget {
  final AppStrings s;

  const _PremiumCollectionBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VerLinkColors.green.withValues(alpha: 0.08),
            const Color(0xFFEAB308).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VerLinkColors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 18, color: Color(0xFFEAB308)),
              const SizedBox(width: 8),
              Text(
                s.premiumCollectionLimit,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: vc.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.premiumCollectionLimitDesc,
            style: TextStyle(fontSize: 13, color: vc.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: VerLinkColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: VerLinkColors.green.withValues(alpha: 0.4)),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            child: Text(s.premiumViewPlans, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
