import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/link_card.dart';
import '../../../shared/widgets/screen_header.dart';
import '../providers/pending_provider.dart';

class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(pendingLinksProvider);
    final searchQuery = ref.watch(pendingSearchQueryProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: s.pendingTitle, subtitle: s.pendingSubtitle),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: VerLinkColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: VerLinkColors.shadow08,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: VerLinkColors.outline),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: VerLinkColors.textTertiary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          fontSize: 14,
                          color: VerLinkColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: s.searchPending,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          isDense: true,
                          filled: false,
                        ),
                        onChanged: (v) => ref
                            .read(pendingSearchQueryProvider.notifier)
                            .state = v,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: linksAsync.when(
                skipLoadingOnRefresh: true,
                data: (allLinks) {
                  final links = searchQuery.trim().isEmpty
                      ? allLinks
                      : allLinks.where((l) {
                          final q = searchQuery.toLowerCase();
                          return (l.title?.toLowerCase().contains(q) ?? false) ||
                              l.url.toLowerCase().contains(q) ||
                              l.platform.toLowerCase().contains(q);
                        }).toList();

                  if (links.isEmpty) {
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
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    VerLinkColors.greenLight,
                                    VerLinkColors.softSurface,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                size: 36,
                                color: VerLinkColors.green,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Semantics(
                              label: searchQuery.trim().isEmpty
                                  ? s.noPendingLinks
                                  : s.noResults,
                              child: Text(
                                searchQuery.trim().isEmpty
                                    ? s.noPendingLinks
                                    : s.noResults,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: VerLinkColors.textPrimary,
                                ),
                              ),
                            ),
                            if (searchQuery.trim().isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                s.noPendingDesc,
                                style: const TextStyle(
                                  color: VerLinkColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      AppTheme.contentBottomPadding,
                    ),
                    itemCount: links.length,
                    itemBuilder: (_, i) => LinkCard(link: links[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: VerLinkColors.green,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => Center(
                  child: Text(
                    s.errorLoadLinks,
                    style: const TextStyle(color: VerLinkColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
