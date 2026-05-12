import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

enum HomeFilter { todos, favoritos }

final homeFilterProvider =
    StateProvider<HomeFilter>((ref) => HomeFilter.todos);

final selectedPlatformProvider = StateProvider<String?>((ref) => null);

final recentLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchAllLinks();
});

final filteredHomeLinksProvider = StreamProvider<List<Link>>((ref) {
  final filter = ref.watch(homeFilterProvider);
  final platform = ref.watch(selectedPlatformProvider);
  final db = ref.watch(databaseProvider);

  if (filter == HomeFilter.favoritos) {
    return db.watchFavoriteLinks();
  }
  if (platform != null) {
    return db.watchLinksByPlatform(platform);
  }
  return db.watchAllLinks();
});
