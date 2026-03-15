import 'dart:async';
import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/conversation/data/conversation_repository.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';
import 'package:teledesk/src/feature/telegram/model/telegram_update.dart';

part 'telegram_polling_controller.freezed.dart';

@freezed
sealed class TelegramPollingState with _$TelegramPollingState {
  const TelegramPollingState._();

  const factory TelegramPollingState.idle() = TelegramPolling$IdleState;
  const factory TelegramPollingState.polling() = TelegramPolling$PollingState;
  const factory TelegramPollingState.error(String message) = TelegramPolling$ErrorState;

  bool get isPolling => this is TelegramPolling$PollingState;
}

/// Manages long-polling loop and processes incoming Telegram updates.
/// Saves messages to DB. UI reacts via Drift streams.
final class TelegramPollingController extends StateController<TelegramPollingState> {
  TelegramPollingController({
    required ITelegramRepository telegramRepository,
    required IConversationRepository conversationRepository,
    required int pollingTimeoutSeconds,
  }) : _telegram = telegramRepository,
       _conversations = conversationRepository,
       _pollingTimeout = pollingTimeoutSeconds,
       super(initialState: const TelegramPollingState.idle());

  final ITelegramRepository _telegram;
  final IConversationRepository _conversations;
  final int _pollingTimeout;

  int _lastUpdateId = 0;
  bool _isPolling = false;

  bool get isPolling => _isPolling;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    setState(const TelegramPollingState.polling());
    _poll();
  }

  void stopPolling() {
    _isPolling = false;
    setState(const TelegramPollingState.idle());
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
      } catch (e) {
        if (!_isPolling) break;
        setState(TelegramPollingState.error(e.toString()));
        await Future<void>.delayed(const Duration(seconds: 2));
        if (_isPolling) setState(const TelegramPollingState.polling());
      }
    }
  }

  Future<void> _processUpdate(TelegramUpdate update) async {
    final message = update.message;
    if (message == null) return;

    final from = message.from;
    if (from.isBot) return;

    // Create or find conversation (re-opens if finished)
    final conversation = await _telegram.createOrGetConversation(
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
      final current = await _telegram.findByTelegramUserId(from.id);
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
    await _telegram.saveIncomingMessage(
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
    await _conversations.updateLastMessage(conversation.id, text ?? '[$messageType]', message.date);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
