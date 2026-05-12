import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final tagLinkCountProvider = FutureProvider.family<int, int>((ref, tagId) {
  return ref.watch(databaseProvider).countLinksForTag(tagId);
});
