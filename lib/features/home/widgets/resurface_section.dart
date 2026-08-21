import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../detail/screens/detail_screen.dart';

final forgottenLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchForgottenLinks();
});

class ResurfaceSection extends ConsumerWidget {
  const ResurfaceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(forgottenLinksProvider);
    return linksAsync.when(
      data: (links) {
        if (links.isEmpty) return const SizedBox.shrink();
        return _ResurfaceContent(links: links);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ResurfaceContent extends ConsumerWidget {
  final List<Link> links;

  const _ResurfaceContent({required this.links});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = VeLinkSemanticColors.of(context);
    final s = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Text(
                s.resurfaceTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: vc.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: vc.primaryTint,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  s.resurfaceBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: VerLinkColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: links.length,
            itemBuilder: (ctx, i) => _ResurfaceCard(link: links[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ResurfaceCard extends ConsumerWidget {
  final Link link;

  const _ResurfaceCard({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = VeLinkSemanticColors.of(context);
    final s = ref.watch(appStringsProvider);
    final daysAgo = DateTime.now().difference(link.createdAt).inDays;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(link: link)),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vc.outline),
          boxShadow: [
            BoxShadow(
              color: vc.shadow06,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                link.title ?? link.url,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vc.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.savedDaysAgo(daysAgo),
              style: TextStyle(
                fontSize: 11,
                color: vc.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
