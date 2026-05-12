import 'package:drift/drift.dart';
import 'links_table.dart';
import 'collections_table.dart';

class LinkCollections extends Table {
  IntColumn get linkId => integer().references(Links, #id)();
  IntColumn get collectionId => integer().references(Collections, #id)();

  @override
  Set<Column> get primaryKey => {linkId, collectionId};
}
