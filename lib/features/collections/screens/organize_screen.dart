import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../tags/screens/tags_screen.dart';
import '../../tags/screens/create_tag_dialog.dart';
import 'collections_screen.dart';
import 'create_collection_dialog.dart';

class OrganizeScreen extends ConsumerStatefulWidget {
  const OrganizeScreen({super.key});

  @override
  ConsumerState<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends ConsumerState<OrganizeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isCollectionsTab = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navOrganize),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.tabCollections),
            Tab(text: s.tabLabels),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        label: isCollectionsTab ? s.createCollection : s.createTagTitle,
        button: true,
        child: FloatingActionButton(
          onPressed: () => _onFabPressed(context, isCollectionsTab),
          tooltip: isCollectionsTab ? s.createCollection : s.createTagTitle,
          child: const Icon(Icons.add),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CollectionsContent(),
          TagsContent(),
        ],
      ),
    );
  }

  void _onFabPressed(BuildContext context, bool isCollectionsTab) {
    if (isCollectionsTab) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const CreateCollectionDialog(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const CreateTagDialog(),
      );
    }
  }
}
