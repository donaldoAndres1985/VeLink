import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final savedLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchAllLinks();
});

final selectedTagIdProvider = StateProvider<int?>((ref) => null);

final filteredSavedLinksProvider = StreamProvider<List<Link>>((ref) {
  final db = ref.watch(databaseProvider);
  final tagId = ref.watch(selectedTagIdProvider);
  if (tagId == null) return db.watchAllLinks();
  return db.watchLinksByTag(tagId);
});
