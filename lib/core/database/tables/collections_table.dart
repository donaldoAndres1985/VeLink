import 'package:drift/drift.dart';

class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#6366F1'))();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
