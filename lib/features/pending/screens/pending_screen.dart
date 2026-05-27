import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/swipeable_link_card.dart';
import '../providers/pending_provider.dart';

class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = VeLinkSemanticColors.of(context);
    final linksAsync = ref.watch(pendingLinksProvider);
    final searchQuery = ref.watch(pendingSearchQueryProvider);
    final s = ref.watch(appStringsProvider);

    // ScaffoldMessenger aislado — mismo motivo que HomeScreen.
    // Con _KeepAlivePage hay 5 Scaffolds registrados en el mismo messenger;
    // sin aislamiento el timer de auto-dismiss del snackbar no funciona.
    return ScaffoldMessenger(
      child: Scaffold(
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
                  color: vc.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: vc.shadow08,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: vc.outline),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: vc.textTertiary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          fontSize: 14,
                          color: vc.textPrimary,
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
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    vc.greenLight,
                                    vc.surfaceContainer,
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
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: vc.textPrimary,
                                ),
                              ),
                            ),
                            if (searchQuery.trim().isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                s.noPendingDesc,
                                style: TextStyle(
                                  color: vc.textSecondary,
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
                    itemBuilder: (_, i) => SwipeableLinkCard(link: links[i]),
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
                    style: TextStyle(color: vc.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),  // Scaffold
    );  // ScaffoldMessenger
  }
}
