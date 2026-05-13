import 'package:flutter/material.dart';
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
import '../core/database/database.dart';
import '../features/notifications/providers/notification_provider.dart';

class VeLinkApp extends ConsumerWidget {
  const VeLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePrefProvider);
    final s = ref.watch(appStringsProvider);

    return MaterialApp(
      title: s.homeTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

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
      body: PageView(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.link_outlined),
            activeIcon: const Icon(Icons.link),
            label: s.navLinks,
            tooltip: s.navLinks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.schedule_outlined),
            activeIcon: const Icon(Icons.schedule),
            label: s.navPending,
            tooltip: s.navPending,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: s.navOrganize,
            tooltip: s.navOrganize,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: s.navSettings,
            tooltip: s.navSettings,
          ),
        ],
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
