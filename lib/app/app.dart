import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/capture/providers/capture_provider.dart';
import '../features/capture/screens/capture_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../features/priority/screens/priority_screen.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(_startUp);
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

  final _screens = const [
    HomeScreen(),
    SavedScreen(),
    PriorityScreen(),
    TagsScreen(),
  ];

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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), activeIcon: Icon(Icons.bookmark), label: 'Guardados'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), activeIcon: Icon(Icons.star), label: 'Prioritarios'),
          BottomNavigationBarItem(icon: Icon(Icons.label_outline), activeIcon: Icon(Icons.label), label: 'Etiquetas'),
        ],
      ),
    );
  }
}
