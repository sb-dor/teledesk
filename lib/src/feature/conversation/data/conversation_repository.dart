import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/chats/model/chat_message.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';

abstract interface class IConversationRepository {
  Stream<List<Conversation>> watchConversations();

  Stream<Conversation?> watchConversation(int id);

  Future<ChatMessage> saveOutgoingMessage({
    required int conversationId,
    required String messageType,
    String? text,
    String? fileId,
    String? fileName,
    int? sentByWorkerId,
    required DateTime sentAt,
  });

  Stream<List<ChatMessage>> watchMessages(int conversationId);

  Future<ChatMessage> saveNote({
    required int conversationId,
    required String text,
    required int sentByWorkerId,
  });

  Future<void> markMessagesRead(int conversationId);

  Future<void> updateLastMessage(int conversationId, String preview, DateTime time, {bool incrementUnread = true});

  Future<void> assignConversation(int conversationId, int workerId);

  Future<void> transferConversation(int conversationId, int newWorkerId);

  Future<void> allowUserToFinish(int conversationId);

  Future<void> finishConversation(int conversationId);
}

final class ConversationRepositoryImpl implements IConversationRepository {
  ConversationRepositoryImpl({required AppDatabase database}) : _db = database;

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

  ChatMessage _rowToMessage(MessagesTblData row) => ChatMessage(
    id: row.id,
    conversationId: row.conversationId,
    telegramMessageId: row.telegramMessageId,
    type: switch (row.messageType) {
      'photo' => MessageType.photo,
      'video' => MessageType.video,
      'gif' => MessageType.gif,
      'sticker' => MessageType.sticker,
      'document' => MessageType.document,
      'voice' => MessageType.voice,
      'video_note' => MessageType.videoNote,
      'audio' => MessageType.audio,
      'note' => MessageType.note,
      _ => MessageType.text,
    },
    text: row.messageText,
    fileId: row.fileId,
    fileName: row.fileName,
    fileMimeType: row.fileMimeType,
    fileSize: row.fileSize,
    isFromBot: row.isFromBot,
    isNote: row.isNote,
    sentByWorkerId: row.sentByWorkerId,
    isRead: row.isRead,
    sentAt: DateTime.fromMillisecondsSinceEpoch(row.sentAt * 1000),
  );

  @override
  Stream<List<Conversation>> watchConversations() =>
      (_db.select(_db.conversationsTbl)
            ..where((t) => t.status.isNotValue('finished'))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch()
          .map((rows) => rows.map(_rowToConversation).toList());

  @override
  Stream<Conversation?> watchConversation(int id) =>
      (_db.select(_db.conversationsTbl)..where((t) => t.id.equals(id))).watchSingleOrNull().map(
        (row) => row != null ? _rowToConversation(row) : null,
      );

  @override
  Future<ChatMessage> saveOutgoingMessage({
    required int conversationId,
    required String messageType,
    String? text,
    String? fileId,
    String? fileName,
    int? sentByWorkerId,
    required DateTime sentAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sentAtTs = sentAt.millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.messagesTbl)
        .insert(
          MessagesTblCompanion.insert(
            conversationId: conversationId,
            telegramMessageId: const Value(null),
            messageType: messageType,
            messageText: Value(text),
            fileId: Value(fileId),
            fileName: Value(fileName),
            fileMimeType: const Value(null),
            fileSize: const Value(null),
            isFromBot: const Value(true),
            isNote: const Value(false),
            sentByWorkerId: Value(sentByWorkerId),
            isRead: const Value(true),
            sentAt: sentAtTs,
            createdAt: now,
          ),
        );
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      telegramMessageId: null,
      type: switch (messageType) {
        'photo' => MessageType.photo,
        'document' => MessageType.document,
        _ => MessageType.text,
      },
      text: text,
      fileId: fileId,
      fileName: fileName,
      fileMimeType: null,
      fileSize: null,
      isFromBot: true,
      isNote: false,
      sentByWorkerId: sentByWorkerId,
      isRead: true,
      sentAt: sentAt,
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(int conversationId) =>
      (_db.select(_db.messagesTbl)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sentAt)]))
          .watch()
          .map((rows) => rows.map(_rowToMessage).toList());

  @override
  Future<ChatMessage> saveNote({
    required int conversationId,
    required String text,
    required int sentByWorkerId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.messagesTbl)
        .insert(
          MessagesTblCompanion.insert(
            conversationId: conversationId,
            telegramMessageId: const Value(null),
            messageType: 'note',
            messageText: Value(text),
            fileId: const Value(null),
            fileName: const Value(null),
            fileMimeType: const Value(null),
            fileSize: const Value(null),
            isFromBot: const Value(false),
            isNote: const Value(true),
            sentByWorkerId: Value(sentByWorkerId),
            isRead: const Value(true),
            sentAt: now,
            createdAt: now,
          ),
        );
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      telegramMessageId: null,
      type: MessageType.note,
      text: text,
      fileId: null,
      fileName: null,
      fileMimeType: null,
      fileSize: null,
      isFromBot: false,
      isNote: true,
      sentByWorkerId: sentByWorkerId,
      isRead: true,
      sentAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  @override
  Future<void> markMessagesRead(int conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.messagesTbl)
          ..where((t) => t.conversationId.equals(conversationId))
          ..where((t) => t.isRead.equals(false))
          ..where((t) => t.isFromBot.equals(false)))
        .write(const MessagesTblCompanion(isRead: Value(true)));
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(unreadCount: const Value(0), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> updateLastMessage(int conversationId, String preview, DateTime time, {bool incrementUnread = true}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sql = incrementUnread
        ? 'UPDATE conversations SET last_message_preview = ?, last_message_at = ?, updated_at = ?, unread_count = unread_count + 1 WHERE id = ?'
        : 'UPDATE conversations SET last_message_preview = ?, last_message_at = ?, updated_at = ? WHERE id = ?';
    await _db.customUpdate(
      sql,
      variables: [
        Variable<String>(preview),
        Variable<int>(time.millisecondsSinceEpoch ~/ 1000),
        Variable<int>(now),
        Variable<int>(conversationId),
      ],
      updates: {_db.conversationsTbl},
    );
  }

  @override
  Future<void> assignConversation(int conversationId, int workerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(
        status: const Value('in_progress'),
        assignedWorkerId: Value(workerId),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> transferConversation(int conversationId, int newWorkerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(assignedWorkerId: Value(newWorkerId), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> allowUserToFinish(int conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(canUserFinish: const Value(true), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> finishConversation(int conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(status: const Value('finished'), updatedAt: Value(now)),
    );
  }
}
