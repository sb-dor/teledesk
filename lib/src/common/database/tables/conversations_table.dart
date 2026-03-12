import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/tables/workers_table.dart';

/// Conversations table - one entry per Telegram user who contacts the bot
class ConversationsTbl extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get telegramUserId => integer().unique()();
  TextColumn get telegramUsername => text().nullable()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('open'),
  )(); // 'open', 'in_progress', 'finish_requested', 'finished'
  IntColumn get assignedWorkerId => integer().nullable().references(WorkersTbl, #id)();
  BoolColumn get canUserFinish => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get lastMessageAt => integer()(); // unix timestamp
  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  String get tableName => 'conversations';
}
