import 'dart:async';
import 'dart:typed_data';
import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/chats/data/conversation_repository.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';
import 'package:teledesk/src/feature/message/data/message_repository.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';

part 'conversation_controller.freezed.dart';

@freezed
sealed class ConversationState with _$ConversationState {
  const factory ConversationState.idle(Conversation conversation) = Conversation$IdleState;
  const factory ConversationState.loading() = Conversation$LoadingState;
  const factory ConversationState.sending() = Conversation$SendingState;
  const factory ConversationState.error(String message, Conversation? conversation) =
      Conversation$ErrorState;
}

final class ConversationController extends StateController<ConversationState>
    with SequentialControllerHandler {
  ConversationController({
    required IConversationRepository repository,
    required IMessageRepository messageRepository,
    required ITelegramRepository telegram,
    required int conversationId,
    required int currentWorkerId,
  }) : _repository = repository,
       _messages = messageRepository,
       _telegram = telegram,
       _conversationId = conversationId,
       _workerId = currentWorkerId,
       super(initialState: const ConversationState.loading());

  final IConversationRepository _repository;
  final IMessageRepository _messages;
  final ITelegramRepository _telegram;
  final int _conversationId;
  final int _workerId;
  StreamSubscription<List<Conversation>>? _conversationSub;

  void initialize() => handle(() async {
    // Initial load
    final conversations = await _repository.watchConversations().first;
    final conv = conversations.where((c) => c.id == _conversationId).firstOrNull;
    if (conv != null) {
      setState(ConversationState.idle(conv));
      // Auto-assign if open
      if (conv.status == ConversationStatus.open) {
        await _repository.assignConversation(_conversationId, _workerId);
        await _messages.markMessagesRead(_conversationId);
      } else if (conv.status == ConversationStatus.inProgress &&
          conv.assignedWorkerId == _workerId) {
        await _messages.markMessagesRead(_conversationId);
      }
    }

    // Watch for live changes
    _conversationSub = _repository.watchConversations().listen((conversations) {
      final updated = conversations.where((c) => c.id == _conversationId).firstOrNull;
      if (updated != null) {
        final current = state;
        if (current is! Conversation$SendingState) {
          setState(ConversationState.idle(updated));
        }
      }
    });
  });

  void sendText(String text) => handle(
    () async {
      final current = state;
      if (current is! Conversation$IdleState) return;
      final conv = current.conversation;
      setState(const ConversationState.sending());
      await _telegram.sendMessage(chatId: conv.telegramUserId, text: text);
      await _messages.saveOutgoingMessage(
        conversationId: _conversationId,
        messageType: 'text',
        text: text,
        sentByWorkerId: _workerId,
        sentAt: DateTime.now(),
      );
      await _messages.updateLastMessage(_conversationId, text, DateTime.now());
      setState(ConversationState.idle(conv));
    },
    error: (e, st) async {
      final conv = (state as Conversation$IdleState?)?.conversation;
      setState(ConversationState.error(e.toString(), conv));
      if (conv != null) setState(ConversationState.idle(conv));
    },
  );

  void sendPhoto(Uint8List bytes, String fileName, {String? caption}) => handle(
    () async {
      final current = state;
      if (current is! Conversation$IdleState) return;
      final conv = current.conversation;
      setState(const ConversationState.sending());
      final fileId = await _telegram.sendPhoto(
        chatId: conv.telegramUserId,
        photoBytes: bytes,
        fileName: fileName,
        caption: caption,
      );
      await _messages.saveOutgoingMessage(
        conversationId: _conversationId,
        messageType: 'photo',
        text: caption,
        fileId: fileId,
        fileName: fileName,
        sentByWorkerId: _workerId,
        sentAt: DateTime.now(),
      );
      setState(ConversationState.idle(conv));
    },
    error: (e, st) async {
      final conv = (state as Conversation$IdleState?)?.conversation;
      if (conv != null) setState(ConversationState.idle(conv));
    },
  );

  void sendDocument(Uint8List bytes, String fileName, {String? caption}) => handle(
    () async {
      final current = state;
      if (current is! Conversation$IdleState) return;
      final conv = current.conversation;
      setState(const ConversationState.sending());
      await _telegram.sendDocument(
        chatId: conv.telegramUserId,
        fileBytes: bytes,
        fileName: fileName,
        caption: caption,
      );
      await _messages.saveOutgoingMessage(
        conversationId: _conversationId,
        messageType: 'document',
        text: caption,
        fileName: fileName,
        sentByWorkerId: _workerId,
        sentAt: DateTime.now(),
      );
      setState(ConversationState.idle(conv));
    },
    error: (e, st) async {
      final conv = (state as Conversation$IdleState?)?.conversation;
      if (conv != null) setState(ConversationState.idle(conv));
    },
  );

  void addNote(String text) => handle(() async {
    await _messages.saveNote(
      conversationId: _conversationId,
      text: text,
      sentByWorkerId: _workerId,
    );
  });

  void allowUserToFinish() => handle(() async {
    final current = state;
    if (current is! Conversation$IdleState) return;
    await _repository.allowUserToFinish(_conversationId);
    await _telegram.sendMessage(
      chatId: current.conversation.telegramUserId,
      text: 'You can now close this conversation by typing /cancel',
    );
  });

  void finishConversation() => handle(() async {
    final conv = (state as Conversation$IdleState?)?.conversation;
    if (conv == null) return;
    await _repository.finishConversation(_conversationId);
    await _telegram.sendMessage(
      chatId: conv.telegramUserId,
      text: 'This conversation has been closed. Thank you for contacting us!',
    );
  });

  void transferTo(int newWorkerId) => handle(() async {
    await _repository.transferConversation(_conversationId, newWorkerId);
  });

  void sendTypingAction() => handle(() async {
    final conv = (state as Conversation$IdleState?)?.conversation;
    if (conv == null) return;
    await _telegram.sendChatAction(chatId: conv.telegramUserId, action: 'typing');
  });

  @override
  void dispose() {
    _conversationSub?.cancel();
    super.dispose();
  }
}
