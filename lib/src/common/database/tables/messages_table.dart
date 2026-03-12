import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/tables/conversations_table.dart';
import 'package:teledesk/src/common/database/tables/workers_table.dart';

/// Messages table - all messages in conversations
class MessagesTbl extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(ConversationsTbl, #id)();
  IntColumn get telegramMessageId => integer().nullable()(); // null for internal notes
  TextColumn get messageType =>
      text()(); // 'text', 'photo', 'video', 'gif', 'sticker', 'document', 'voice', 'video_note', 'audio', 'note'
  TextColumn get messageText => text().nullable()();
  TextColumn get fileId => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get fileMimeType => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  BoolColumn get isFromBot =>
      boolean().withDefault(const Constant(false))(); // true = sent by admin/worker via bot
  BoolColumn get isNote =>
      boolean().withDefault(const Constant(false))(); // internal note, not visible to user
  IntColumn get sentByWorkerId => integer().nullable().references(WorkersTbl, #id)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  IntColumn get sentAt => integer()(); // unix timestamp
  IntColumn get createdAt => integer()();

  @override
  String get tableName => 'messages';
}
