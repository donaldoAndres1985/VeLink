import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final priorityLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchPriorityLinks();
});
