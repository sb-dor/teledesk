import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';

abstract interface class IChatsRepository {
  Stream<List<Conversation>> watchOpenConversations();

  Stream<List<Conversation>> watchWorkerConversations(int workerId);
}

final class ChatsRepositoryImpl implements IChatsRepository {
  ChatsRepositoryImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Conversation _rowToConversation(ConversationsTblData row) => Conversation(
    id: row.id,
    telegramUserId: row.telegramUserId,
    telegramUsername: row.telegramUsername,
    firstName: row.firstName,
    lastName: row.lastName,
    status: switch (row.status) {
      'in_progress' => ConversationStatus.inProgress,
      'finish_requested' => ConversationStatus.finishRequested,
      'finished' => ConversationStatus.finished,
      _ => ConversationStatus.open,
    },
    assignedWorkerId: row.assignedWorkerId,
    canUserFinish: row.canUserFinish,
    unreadCount: row.unreadCount,
    lastMessageAt: DateTime.fromMillisecondsSinceEpoch(row.lastMessageAt * 1000),
    lastMessagePreview: row.lastMessagePreview,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000),
  );

  @override
  Stream<List<Conversation>> watchOpenConversations() =>
      (_db.select(_db.conversationsTbl)
            ..where((t) => t.status.equals('open'))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch()
          .map((rows) => rows.map(_rowToConversation).toList());

  @override
  Stream<List<Conversation>> watchWorkerConversations(int workerId) =>
      (_db.select(_db.conversationsTbl)
            ..where((t) => t.assignedWorkerId.equals(workerId))
            ..where((t) => t.status.isNotValue('finished'))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch()
          .map((rows) => rows.map(_rowToConversation).toList());
}
