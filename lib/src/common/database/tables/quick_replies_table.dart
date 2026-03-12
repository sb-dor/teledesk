import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/tables/workers_table.dart';

/// Quick replies table - saved message templates
class QuickRepliesTbl extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get content => text()();
  IntColumn get createdByWorkerId => integer().nullable().references(WorkersTbl, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  String get tableName => 'quick_replies';
}
