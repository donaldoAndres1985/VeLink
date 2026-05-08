import 'package:drift/native.dart';
import 'package:velink/core/database/database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
