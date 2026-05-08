import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:velink/core/database/database.dart';

ProviderContainer createTestContainer({List<Override> overrides = const []}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      ...overrides,
    ],
  );
}

Widget buildTestWidget(Widget child, {List<Override> overrides = const []}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      ...overrides,
    ],
    child: MaterialApp(home: child),
  );
}
