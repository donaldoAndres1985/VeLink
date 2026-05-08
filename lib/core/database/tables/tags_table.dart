import 'package:drift/drift.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().withDefault(const Constant('#6366F1'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
