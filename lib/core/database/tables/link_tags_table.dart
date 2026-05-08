import 'package:drift/drift.dart';
import 'links_table.dart';
import 'tags_table.dart';

class LinkTags extends Table {
  IntColumn get linkId => integer().references(Links, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {linkId, tagId};
}
