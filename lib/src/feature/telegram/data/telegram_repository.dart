import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/bot_settings/model/bot_command.dart';
import 'package:teledesk/src/feature/chats/model/chat_message.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';
import 'package:teledesk/src/feature/telegram/model/telegram_update.dart';

abstract interface class ITelegramRepository {
  /// Get pending updates via long-polling. Returns empty list if timeout.
  Future<List<TelegramUpdate>> getUpdates({required int offset, required int timeoutSeconds});

  /// Send a text message
  Future<void> sendMessage({required int chatId, required String text, String? parseMode});

  /// Send a photo (from file bytes). Returns the Telegram file_id of the sent photo.
  Future<String?> sendPhoto({
    required int chatId,
    required Uint8List photoBytes,
    String? fileName,
    String? caption,
  });

  /// Send a photo by file_id (already on Telegram servers)
  Future<void> sendPhotoByFileId({required int chatId, required String fileId, String? caption});

  /// Send a video by file_id
  Future<void> sendVideoByFileId({required int chatId, required String fileId, String? caption});

  /// Send a document (from file bytes)
  Future<void> sendDocument({
    required int chatId,
    required Uint8List fileBytes,
    required String fileName,
    String? caption,
  });

  /// Send a document by file_id
  Future<void> sendDocumentByFileId({
    required int chatId,
    required String fileId,
    String? fileName,
    String? caption,
  });

  /// Send any media by file_id for any type
  Future<void> sendMediaByFileId({
    required int chatId,
    required String fileId,
    required String messageType,
    String? caption,
  });

  /// Set bot commands
  Future<void> setMyCommands({required List<BotCommand> commands});

  /// Get bot commands
  Future<List<BotCommand>> getMyCommands();

  /// Set bot description
  Future<void> setMyDescription({required String description});

  /// Set bot short description
  Future<void> setMyShortDescription({required String shortDescription});

  /// Get bot info
  Future<Map<String, dynamic>> getMe();

  /// Delete a message
  Future<void> deleteMessage({required int chatId, required int messageId});

  /// Send chat action (typing, upload_photo, etc.)
  Future<void> sendChatAction({required int chatId, required String action});

  /// Get file download URL
  Future<String?> getFileUrl({required String fileId});

  /// Update the bot token at runtime (called after user saves new token)
  void updateToken(String newToken);

  /// Clear the bot token — disables all API calls until a new token is set
  void clearToken();

  Future<Conversation?> findByTelegramUserId(int telegramUserId);

  Future<Conversation> createOrGetConversation({
    required int telegramUserId,
    String? username,
    String? firstName,
    String? lastName,
  });

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
}

final class TelegramRepositoryImpl implements ITelegramRepository {
  TelegramRepositoryImpl({required String? botToken, required final AppDatabase appDatabase})
    : _baseUrl = 'https://api.telegram.org/bot$botToken',
      _fileBaseUrl = 'https://api.telegram.org/file/bot$botToken',
      _db = appDatabase;

  String _baseUrl;
  String _fileBaseUrl;
  final http.Client _client = http.Client();
  final AppDatabase _db;

  @override
  void updateToken(String newToken) {
    _baseUrl = 'https://api.telegram.org/bot$newToken';
    _fileBaseUrl = 'https://api.telegram.org/file/bot$newToken';
  }

  @override
  void clearToken() {
    _baseUrl = '';
    _fileBaseUrl = '';
  }

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

  Future<Map<String, dynamic>> _post(String method, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/$method'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 35));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) {
      throw Exception('Telegram API error: ${json['description']}');
    }
    return json;
  }

  @override
  Future<List<TelegramUpdate>> getUpdates({
    required int offset,
    required int timeoutSeconds,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/getUpdates'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'offset': offset, 'timeout': timeoutSeconds, 'limit': 100}),
          )
          .timeout(Duration(seconds: timeoutSeconds + 5));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['ok'] != true) return [];

      final results = json['result'] as List<dynamic>;
      return results.map((u) => TelegramUpdate.fromJson(u as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> sendMessage({required int chatId, required String text, String? parseMode}) async {
    await _post('sendMessage', {
      'chat_id': chatId,
      'text': text,
      if (parseMode != null) 'parse_mode': parseMode,
    });
  }

  @override
  Future<String?> sendPhoto({
    required int chatId,
    required Uint8List photoBytes,
    String? fileName,
    String? caption,
  }) async {
    final uri = Uri.parse('$_baseUrl/sendPhoto');
    final request = http.MultipartRequest('POST', uri);
    request.fields['chat_id'] = chatId.toString();
    if (caption != null) request.fields['caption'] = caption;
    request.files.add(
      http.MultipartFile.fromBytes('photo', photoBytes, filename: fileName ?? 'photo.jpg'),
    );
    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) throw Exception('Telegram API error: ${json['description']}');
    // Return file_id of the largest photo size
    try {
      final result = json['result'] as Map<String, dynamic>;
      final photos = result['photo'] as List<dynamic>;
      if (photos.isNotEmpty) {
        return (photos.last as Map<String, dynamic>)['file_id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> sendPhotoByFileId({
    required int chatId,
    required String fileId,
    String? caption,
  }) async {
    await _post('sendPhoto', {
      'chat_id': chatId,
      'photo': fileId,
      if (caption != null) 'caption': caption,
    });
  }

  @override
  Future<void> sendVideoByFileId({
    required int chatId,
    required String fileId,
    String? caption,
  }) async {
    await _post('sendVideo', {
      'chat_id': chatId,
      'video': fileId,
      if (caption != null) 'caption': caption,
    });
  }

  @override
  Future<void> sendDocument({
    required int chatId,
    required Uint8List fileBytes,
    required String fileName,
    String? caption,
  }) async {
    final uri = Uri.parse('$_baseUrl/sendDocument');
    final request = http.MultipartRequest('POST', uri);
    request.fields['chat_id'] = chatId.toString();
    if (caption != null) request.fields['caption'] = caption;
    request.files.add(http.MultipartFile.fromBytes('document', fileBytes, filename: fileName));
    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) throw Exception('Telegram API error: ${json['description']}');
  }

  @override
  Future<void> sendDocumentByFileId({
    required int chatId,
    required String fileId,
    String? fileName,
    String? caption,
  }) async {
    await _post('sendDocument', {
      'chat_id': chatId,
      'document': fileId,
      if (caption != null) 'caption': caption,
    });
  }

  @override
  Future<void> sendMediaByFileId({
    required int chatId,
    required String fileId,
    required String messageType,
    String? caption,
  }) async {
    final method = switch (messageType) {
      'photo' => 'sendPhoto',
      'video' => 'sendVideo',
      'audio' => 'sendAudio',
      'voice' => 'sendVoice',
      'video_note' => 'sendVideoNote',
      'sticker' => 'sendSticker',
      'animation' || 'gif' => 'sendAnimation',
      _ => 'sendDocument',
    };
    final field = switch (messageType) {
      'photo' => 'photo',
      'video' => 'video',
      'audio' => 'audio',
      'voice' => 'voice',
      'video_note' => 'video_note',
      'sticker' => 'sticker',
      'animation' || 'gif' => 'animation',
      _ => 'document',
    };
    await _post(method, {
      'chat_id': chatId,
      field: fileId,
      if (caption != null && messageType != 'sticker' && messageType != 'video_note')
        'caption': caption,
    });
  }

  @override
  Future<void> setMyCommands({required List<BotCommand> commands}) async {
    await _post('setMyCommands', {
      'commands': commands
          .map((c) => {'command': c.command, 'description': c.description})
          .toList(),
    });
  }

  @override
  Future<List<BotCommand>> getMyCommands() async {
    final json = await _post('getMyCommands', {});
    final results = json['result'] as List<dynamic>;
    return results
        .map(
          (c) => BotCommand(
            command: (c as Map<String, dynamic>)['command'] as String,
            description: c['description'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<void> setMyDescription({required String description}) async {
    await _post('setMyDescription', {'description': description});
  }

  @override
  Future<void> setMyShortDescription({required String shortDescription}) async {
    await _post('setMyShortDescription', {'short_description': shortDescription});
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    final json = await _post('getMe', {});
    return json['result'] as Map<String, dynamic>;
  }

  @override
  Future<void> deleteMessage({required int chatId, required int messageId}) async {
    await _post('deleteMessage', {'chat_id': chatId, 'message_id': messageId});
  }

  @override
  Future<void> sendChatAction({required int chatId, required String action}) async {
    await _post('sendChatAction', {'chat_id': chatId, 'action': action});
  }

  @override
  Future<String?> getFileUrl({required String fileId}) async {
    try {
      final json = await _post('getFile', {'file_id': fileId});
      final filePath = (json['result'] as Map<String, dynamic>)['file_path'] as String?;
      if (filePath == null) return null;
      return '$_fileBaseUrl/$filePath';
    } catch (_) {
      return null;
    }
  }

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
  Future<Conversation> createOrGetConversation({
    required int telegramUserId,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    final existing = await findByTelegramUserId(telegramUserId);
    if (existing != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (existing.status == ConversationStatus.finished) {
        // User wrote back after conversation was closed — re-open it
        await (_db.update(
          _db.conversationsTbl,
        )..where((t) => t.telegramUserId.equals(telegramUserId))).write(
          ConversationsTblCompanion(
            telegramUsername: Value(username),
            firstName: Value(firstName),
            lastName: Value(lastName),
            status: const Value('open'),
            assignedWorkerId: const Value(null),
            canUserFinish: const Value(false),
            unreadCount: const Value(1),
            updatedAt: Value(now),
          ),
        );
        return existing.copyWith(
          status: ConversationStatus.open,
          assignedWorkerId: () => null,
          canUserFinish: false,
          unreadCount: 1,
        );
      }
      await (_db.update(
        _db.conversationsTbl,
      )..where((t) => t.telegramUserId.equals(telegramUserId))).write(
        ConversationsTblCompanion(
          telegramUsername: Value(username),
          firstName: Value(firstName),
          lastName: Value(lastName),
          updatedAt: Value(now),
        ),
      );
      return existing;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.conversationsTbl)
        .insert(
          ConversationsTblCompanion.insert(
            telegramUserId: telegramUserId,
            telegramUsername: Value(username),
            firstName: Value(firstName),
            lastName: Value(lastName),
            status: const Value('open'),
            assignedWorkerId: const Value(null),
            canUserFinish: const Value(false),
            unreadCount: const Value(1),
            lastMessageAt: now,
            lastMessagePreview: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return Conversation(
      id: id,
      telegramUserId: telegramUserId,
      telegramUsername: username,
      firstName: firstName,
      lastName: lastName,
      status: ConversationStatus.open,
      assignedWorkerId: null,
      canUserFinish: false,
      unreadCount: 1,
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      lastMessagePreview: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  @override
  Future<Conversation?> findByTelegramUserId(int telegramUserId) async {
    final row = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.telegramUserId.equals(telegramUserId))).getSingleOrNull();
    if (row == null) return null;
    return _rowToConversation(row);
  }
}
