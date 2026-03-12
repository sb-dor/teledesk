import 'package:drift/drift.dart';

/// Workers table - admin and support workers
class WorkersTbl extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get passwordHash => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  TextColumn get role => text().withDefault(const Constant('worker'))(); // 'admin' or 'worker'
  TextColumn get colorCode => text().withDefault(const Constant('#2196F3'))();
  TextColumn get status =>
      text().withDefault(const Constant('offline'))(); // 'online', 'away', 'busy', 'offline'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()(); // unix timestamp
  IntColumn get updatedAt => integer()();

  @override
  String get tableName => 'workers';
}
