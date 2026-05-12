import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final allCollectionsProvider = StreamProvider<List<Collection>>((ref) {
  return ref.watch(databaseProvider).watchAllCollections();
});

final collectionLinkCountProvider = FutureProvider.family<int, int>((ref, collectionId) {
  return ref.watch(databaseProvider).countLinksInCollection(collectionId);
});

final collectionLastLinkProvider = FutureProvider.family<Link?, int>((ref, collectionId) {
  return ref.watch(databaseProvider).getLastLinkAddedToCollection(collectionId);
});

final collectionsForLinkProvider = StreamProvider.family<List<Collection>, int>((ref, linkId) {
  return ref.watch(databaseProvider).watchCollectionsForLink(linkId);
});

final linksInCollectionProvider = StreamProvider.family<List<Link>, int>((ref, collectionId) {
  return ref.watch(databaseProvider).watchLinksInCollection(collectionId);
});
