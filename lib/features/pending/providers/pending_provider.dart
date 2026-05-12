import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final pendingLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchPendingLinks();
});
