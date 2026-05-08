import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final linkTagsProvider = FutureProvider.family<List<Tag>, int>((ref, linkId) {
  return ref.watch(databaseProvider).getTagsForLink(linkId);
});

final watchLinkTagsProvider = StreamProvider.family<List<Tag>, int>((ref, linkId) {
  return ref.watch(databaseProvider).watchTagsForLink(linkId);
});
