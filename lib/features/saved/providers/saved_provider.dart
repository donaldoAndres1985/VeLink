import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final savedLinksProvider = StreamProvider<List<Link>>((ref) {
  return ref.watch(databaseProvider).watchAllLinks();
});
