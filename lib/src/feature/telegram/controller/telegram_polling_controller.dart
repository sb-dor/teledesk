import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:teledesk/src/feature/chats/data/conversation_repository.dart';
import 'package:teledesk/src/feature/message/data/message_repository.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';
import 'package:teledesk/src/feature/telegram/model/telegram_update.dart';

/// Manages long-polling loop and processes incoming Telegram updates.
/// Saves messages to DB. UI reacts via Drift streams.
final class TelegramPollingController with ChangeNotifier {
  TelegramPollingController({
    required ITelegramRepository telegramRepository,
    required IConversationRepository conversationRepository,
    required IMessageRepository messageRepository,
    required int pollingTimeoutSeconds,
  }) : _telegram = telegramRepository,
       _conversations = conversationRepository,
       _messages = messageRepository,
       _pollingTimeout = pollingTimeoutSeconds;

  final ITelegramRepository _telegram;
  final IConversationRepository _conversations;
  final IMessageRepository _messages;
  final int _pollingTimeout;

  int _lastUpdateId = 0;
  bool _isPolling = false;

  bool get isPolling => _isPolling;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    notifyListeners();
    _poll();
  }

  void stopPolling() {
    _isPolling = false;
    notifyListeners();
  }

  Future<void> _poll() async {
    while (_isPolling) {
      try {
        final updates = await _telegram.getUpdates(
          offset: _lastUpdateId + 1,
          timeoutSeconds: _pollingTimeout,
        );
        if (!_isPolling) break;
        for (final update in updates) {
          if (update.updateId > _lastUpdateId) {
            _lastUpdateId = update.updateId;
          }
          await _processUpdate(update);
        }
      } catch (_) {
        if (!_isPolling) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _processUpdate(TelegramUpdate update) async {
    final message = update.message;
    if (message == null) return;

    final from = message.from;
    if (from.isBot) return;

    // Create or find conversation (re-opens if finished)
    final conversation = await _conversations.createOrGetConversation(
      telegramUserId: from.id,
      username: from.username,
      firstName: from.firstName,
      lastName: from.lastName,
    );

    final messageType = message.messageType;
    final text = message.displayText;
    final fileId = message.fileId;

    // Handle /cancel command (only if canUserFinish is true)
    if (text == '/cancel') {
      final current = await _conversations.findByTelegramUserId(from.id);
      if (current != null && current.canUserFinish) {
        await _conversations.finishConversation(current.id);
        await _telegram.sendMessage(
          chatId: from.id,
          text: 'Your conversation has been closed. Thank you!',
        );
        return;
      }
    }

    // Save the incoming message to DB
    await _messages.saveIncomingMessage(
      conversationId: conversation.id,
      telegramMessageId: message.messageId,
      messageType: messageType,
      text: text,
      fileId: fileId,
      fileName: message.document?.fileName ?? message.audio?.fileName,
      fileMimeType:
          message.document?.mimeType ?? message.video?.mimeType ?? message.audio?.mimeType,
      fileSize: message.document?.fileSize ?? message.video?.fileSize,
      sentAt: message.date,
    );

    // Update conversation last message
    await _messages.updateLastMessage(conversation.id, text ?? '[$messageType]', message.date);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
