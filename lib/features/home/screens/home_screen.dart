import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/link_card.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(recentLinksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VeLink')),
      body: linksAsync.when(
        data: (links) => links.isEmpty
            ? const Center(child: Text('No hay links guardados aún'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: links.length,
                itemBuilder: (_, i) => LinkCard(link: links[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar los links')),
      ),
    );
  }
}
