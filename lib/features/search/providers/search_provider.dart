import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Link>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(databaseProvider).searchLinks(query.trim());
});
