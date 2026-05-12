import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/capture/providers/capture_provider.dart';
import '../features/capture/screens/capture_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pending/screens/pending_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/tags/screens/tags_screen.dart';
import '../core/database/database.dart';
import '../features/notifications/providers/notification_provider.dart';

class VeLinkApp extends StatelessWidget {
  const VeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
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
    await _checkPriorityLinks();
  }

  Future<void> _checkPriorityLinks() async {
    final db = ref.read(databaseProvider);
    final service = ref.read(notificationServiceProvider);
    final links = await db.getPriorityLinks();
    if (links.isNotEmpty && mounted) {
      await service.showPriorityLinksNotification(links.length);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          _KeepAlivePage(child: HomeScreen()),
          _KeepAlivePage(child: PendientesScreen()),
          _KeepAlivePage(child: TagsScreen()),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.link_outlined),
            activeIcon: Icon(Icons.link),
            label: 'Links',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Pendientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.label_outline),
            activeIcon: Icon(Icons.label),
            label: 'Etiquetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
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
