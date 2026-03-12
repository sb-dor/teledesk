import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/chats/model/chat_message.dart';

abstract interface class IMessageRepository {
  Stream<List<ChatMessage>> watchMessages(int conversationId);

  Future<ChatMessage> saveIncomingMessage({
    required int conversationId,
    required int telegramMessageId,
    required String messageType,
    String? text,
    String? fileId,
    String? fileName,
    String? fileMimeType,
    int? fileSize,
    required DateTime sentAt,
  });

  Future<ChatMessage> saveOutgoingMessage({
    required int conversationId,
    required String messageType,
    String? text,
    String? fileId,
    String? fileName,
    int? sentByWorkerId,
    required DateTime sentAt,
  });

  Future<ChatMessage> saveNote({
    required int conversationId,
    required String text,
    required int sentByWorkerId,
  });

  Future<void> markMessagesRead(int conversationId);

  Future<void> updateLastMessage(int conversationId, String preview, DateTime time);
}

final class MessageRepositoryImpl implements IMessageRepository {
  MessageRepositoryImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

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
  Stream<List<ChatMessage>> watchMessages(int conversationId) =>
      (_db.select(_db.messagesTbl)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sentAt)]))
          .watch()
          .map((rows) => rows.map(_rowToMessage).toList());

  @override
  Future<ChatMessage> saveIncomingMessage({
    required int conversationId,
    required int telegramMessageId,
    required String messageType,
    String? text,
    String? fileId,
    String? fileName,
    String? fileMimeType,
    int? fileSize,
    required DateTime sentAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sentAtTs = sentAt.millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.messagesTbl)
        .insert(
          MessagesTblCompanion.insert(
            conversationId: conversationId,
            telegramMessageId: Value(telegramMessageId),
            messageType: messageType,
            messageText: Value(text),
            fileId: Value(fileId),
            fileName: Value(fileName),
            fileMimeType: Value(fileMimeType),
            fileSize: Value(fileSize),
            isFromBot: const Value(false),
            isNote: const Value(false),
            sentByWorkerId: const Value(null),
            isRead: const Value(false),
            sentAt: sentAtTs,
            createdAt: now,
          ),
        );
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      telegramMessageId: telegramMessageId,
      type: switch (messageType) {
        'photo' => MessageType.photo,
        'video' => MessageType.video,
        'gif' => MessageType.gif,
        'sticker' => MessageType.sticker,
        'document' => MessageType.document,
        'voice' => MessageType.voice,
        'video_note' => MessageType.videoNote,
        'audio' => MessageType.audio,
        _ => MessageType.text,
      },
      text: text,
      fileId: fileId,
      fileName: fileName,
      fileMimeType: fileMimeType,
      fileSize: fileSize,
      isFromBot: false,
      isNote: false,
      sentByWorkerId: null,
      isRead: false,
      sentAt: sentAt,
    );
  }

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
  Future<void> updateLastMessage(int conversationId, String preview, DateTime time) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(
        lastMessagePreview: Value(preview),
        lastMessageAt: Value(time.millisecondsSinceEpoch ~/ 1000),
        updatedAt: Value(now),
      ),
    );
    final row = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.id.equals(conversationId))).getSingleOrNull();
    if (row != null) {
      await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
        ConversationsTblCompanion(unreadCount: Value(row.unreadCount + 1)),
      );
    }
  }
}
