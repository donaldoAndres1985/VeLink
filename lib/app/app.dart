import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/preferences/preferences_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/capture/providers/capture_provider.dart';
import '../features/capture/screens/capture_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pending/screens/pending_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/collections/screens/organize_screen.dart';
import '../features/collections/screens/create_collection_dialog.dart';
import '../features/collections/providers/organize_tab_provider.dart';
import '../features/tags/screens/create_tag_dialog.dart';
import '../core/database/database.dart';
import '../features/notifications/providers/notification_provider.dart';

class VerLinkApp extends ConsumerWidget {
  const VerLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePrefProvider);
    final s = ref.watch(appStringsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: s.homeTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.microtask(_startUp);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startUp() async {
    final service = ref.read(notificationServiceProvider);
    await service.init();
    await _checkFavoriteLinks();
  }

  Future<void> _checkFavoriteLinks() async {
    final enabled = ref.read(notificationsEnabledProvider);
    if (!enabled) return;

    final db = ref.read(databaseProvider);
    final service = ref.read(notificationServiceProvider);
    final links = await db.getPriorityLinks();
    if (links.isNotEmpty && mounted) {
      final s = ref.read(appStringsProvider);
      await service.showFavoriteLinksNotification(
        links.length,
        title: s.notifFavoritesTitle,
        body: s.notifFavoritesBody(links.length),
      );
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _isFabEnabled(int navIndex) {
    return navIndex == 0 || navIndex == 2;
  }

  void _handleFabAction(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        _handleAddLinkTap(context);
      case 2:
        final organizeTab = ref.read(organizeTabIndexProvider);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => organizeTab == 0
              ? const CreateCollectionDialog()
              : const CreateTagDialog(),
        );
    }
  }

  void _handleAddLinkTap(BuildContext context) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CaptureScreen(url: text)),
        );
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    _showAddLinkDialog(context);
  }

  void _showAddLinkDialog(BuildContext context) {
    final s = ref.read(appStringsProvider);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addLink),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste_rounded),
              tooltip: s.paste,
              onPressed: () async {
                try {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    controller.text = data!.text!.trim();
                    controller.selection = TextSelection.collapsed(
                        offset: controller.text.length);
                  }
                } catch (_) {}
              },
            ),
          ),
          onSubmitted: (url) {
            Navigator.pop(ctx);
            final trimmed = url.trim();
            if (trimmed.isNotEmpty) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CaptureScreen(url: trimmed)));
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.pop(ctx);
              if (trimmed.isNotEmpty) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => CaptureScreen(url: trimmed)));
              }
            },
            child: Text(s.go),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final fabEnabled = _isFabEnabled(_currentIndex);

    ref.listen<String?>(
      captureProvider.select((s) => s.pendingUrl),
      (previous, next) {
        if (next != null && previous != next) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CaptureScreen(url: next)),
          );
        }
      },
    );

    ref.listen<bool>(
      notificationsEnabledProvider,
      (previous, next) {
        if (previous == true && next == false) {
          ref.read(notificationServiceProvider).cancelAll();
        }
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: const [
              _KeepAlivePage(child: HomeScreen()),
              _KeepAlivePage(child: PendientesScreen()),
              _KeepAlivePage(child: OrganizeScreen()),
              _KeepAlivePage(child: AjustesScreen()),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              onAddTap: () => _handleFabAction(context),
              fabEnabled: fabEnabled,
              bottomInset: bottomInset,
              labels: [s.navLinks, s.navPending, s.navOrganize, s.navSettings],
              icons: const [
                Icons.link_outlined,
                Icons.schedule_outlined,
                Icons.folder_outlined,
                Icons.settings_outlined,
              ],
              activeIcons: const [
                Icons.link,
                Icons.schedule,
                Icons.folder,
                Icons.settings,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;
  final bool fabEnabled;
  final double bottomInset;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> activeIcons;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
    required this.fabEnabled,
    required this.bottomInset,
    required this.labels,
    required this.icons,
    required this.activeIcons,
  });

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar> {
  bool _addPressed = false;

  @override
  void didUpdateWidget(_FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.fabEnabled && _addPressed) {
      setState(() => _addPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: vc.navBarBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: vc.shadow25,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: vc.shadow12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: AppTheme.floatingNavHeight,
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0)),
                Expanded(child: _buildNavItem(1)),
                Expanded(child: _buildAddButton()),
                Expanded(child: _buildNavItem(2)),
                Expanded(child: _buildNavItem(3)),
              ],
            ),
          ),
          SizedBox(height: widget.bottomInset),
        ],
      ),
    );
  }

  Widget _buildNavItem(int i) {
    final isActive = i == widget.currentIndex;
    final vc = VeLinkSemanticColors.of(context);
    return Semantics(
      label: widget.labels[i],
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: () => widget.onTap(i),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppTheme.floatingNavHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isActive ? widget.activeIcons[i] : widget.icons[i],
                  key: ValueKey('nav_${i}_$isActive'),
                  size: 22,
                  color: isActive ? VerLinkColors.green : vc.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? VerLinkColors.green : vc.textTertiary,
                ),
                child: Text(widget.labels[i]),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 4 : 0,
                height: isActive ? 4 : 0,
                decoration: const BoxDecoration(
                  color: VerLinkColors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final isEnabled = widget.fabEnabled;
    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _addPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _addPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _addPressed = false) : null,
      onTap: isEnabled ? widget.onAddTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppTheme.floatingNavHeight,
        child: Center(
          child: AnimatedScale(
            scale: _addPressed ? 0.88 : (isEnabled ? 1.0 : 0.92),
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: isEnabled ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? VerLinkColors.green
                      : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: isEnabled
                      ? Colors.white
                      : Colors.white.withAlpha(89),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
