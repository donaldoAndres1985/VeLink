import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final recentLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchAllLinks();
});

final selectedPlatformProvider = StateProvider<String?>((ref) => null);

final filteredHomeLinksProvider = StreamProvider<List<Link>>((ref) {
  final platform = ref.watch(selectedPlatformProvider);
  final db = ref.watch(databaseProvider);
  if (platform == null) return db.watchAllLinks();
  return db.watchLinksByPlatform(platform);
});
