import 'dart:async';
import 'dart:typed_data';
import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/chats/model/chat_message.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';
import 'package:teledesk/src/feature/conversation/data/conversation_repository.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

part 'conversation_controller.freezed.dart';

@freezed
sealed class ConversationState with _$ConversationState {
  const factory ConversationState.idle(Conversation conversation, List<ChatMessage> messages) =
      Conversation$IdleState;

  const factory ConversationState.loading() = Conversation$LoadingState;

  const factory ConversationState.sending() = Conversation$SendingState;

  const factory ConversationState.error(String message, Conversation? conversation) =
      Conversation$ErrorState;
}

final class ConversationController extends StateController<ConversationState>
    with SequentialControllerHandler {
  ConversationController({
    required IConversationRepository repository,
    required ITelegramRepository telegram,
    required IWorkerRepository workerRepository,
    required int conversationId,
    required int currentWorkerId,
  }) : _repository = repository,
       _telegram = telegram,
       _workerRepository = workerRepository,
       _conversationId = conversationId,
       _workerId = currentWorkerId,
       super(initialState: const ConversationState.loading());

  final IConversationRepository _repository;
  final ITelegramRepository _telegram;
  final IWorkerRepository _workerRepository;
  final int _conversationId;
  final int _workerId;

  StreamSubscription<Conversation?>? _conversationSub;
  StreamSubscription<List<ChatMessage>>? _chatMessagesSub;

  List<Worker> _workers = [];
  bool _isSending = false;

  List<Worker> get workers => _workers;
  bool get isSending => _isSending;

  void initialize() => handle(() async {
    _workers = await _workerRepository.getWorkers();
    notifyListeners();

    final conv = await _repository.watchConversation(_conversationId).first;
    if (conv != null) {
      setState(ConversationState.idle(conv, List.empty()));
      if (conv.status == ConversationStatus.open) {
        await _repository.assignConversation(_conversationId, _workerId);
        await _repository.markMessagesRead(_conversationId);
      } else if (conv.status == ConversationStatus.inProgress &&
          conv.assignedWorkerId == _workerId) {
        await _repository.markMessagesRead(_conversationId);
      }
    }

    _conversationSub = _repository.watchConversation(_conversationId).listen((updated) {
      if (updated != null) {
        final current = state;
        if (current is Conversation$IdleState) {
          setState(ConversationState.idle(updated, current.messages));
        }
      }
    });

    _chatMessagesSub = _repository.watchMessages(_conversationId).listen((messages) {
      final current = state;
      if (current is Conversation$IdleState) {
        setState(ConversationState.idle(current.conversation, messages));
      }
    });

  });

  Future<String?> getPhotoUrl(String fileId) => _telegram.getFileUrl(fileId: fileId);

  void sendText(String text) => handle(
    () async {
      final current = state;
      if (current is! Conversation$IdleState) return;
      final conv = current.conversation;
      _isSending = true;
      notifyListeners();
      await _telegram.sendMessage(chatId: conv.telegramUserId, text: text);
      await _repository.saveOutgoingMessage(
        conversationId: _conversationId,
        messageType: 'text',
        text: text,
        sentByWorkerId: _workerId,
        sentAt: DateTime.now(),
      );
      await _repository.updateLastMessage(
        _conversationId,
        text,
        DateTime.now(),
        incrementUnread: false,
      );
      _isSending = false;
      notifyListeners();
    },
    error: (e, st) async {
      _isSending = false;
      final current = state;
      if (current is Conversation$IdleState) {
        setState(ConversationState.error(e.toString(), current.conversation));
        setState(ConversationState.idle(current.conversation, current.messages));
      }
    },
  );

  void sendPhoto(Uint8List bytes, String fileName, {String? caption}) => handle(
    () async {
      final current = state;
      if (current is! Conversation$IdleState) return;
      final conv = current.conversation;
      _isSending = true;
      notifyListeners();
      final fileId = await _telegram.sendPhoto(
        chatId: conv.telegramUserId,
        photoBytes: bytes,
        fileName: fileName,
        caption: caption,
      );
      await _repository.saveOutgoingMessage(
        conversationId: _conversationId,
        messageType: 'photo',
        text: caption,
        fileId: fileId,
        fileName: fileName,
        sentByWorkerId: _workerId,
        sentAt: DateTime.now(),
      );
      _isSending = false;
      notifyListeners();
    },
    error: (e, st) async {
      _isSending = false;
      notifyListeners();
    },
  );

  void sendDocument(Uint8List bytes, String fileName, {String? caption}) => handle(
    () async {
      final current = state;
      if (current is! Conversation$IdleState) return;
      final conv = current.conversation;
      _isSending = true;
      notifyListeners();
      await _telegram.sendDocument(
        chatId: conv.telegramUserId,
        fileBytes: bytes,
        fileName: fileName,
        caption: caption,
      );
      await _repository.saveOutgoingMessage(
        conversationId: _conversationId,
        messageType: 'document',
        text: caption,
        fileName: fileName,
        sentByWorkerId: _workerId,
        sentAt: DateTime.now(),
      );
      _isSending = false;
      notifyListeners();
    },
    error: (e, st) async {
      _isSending = false;
      notifyListeners();
    },
  );

  void addNote(String text) => handle(() async {
    await _repository.saveNote(
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
    _chatMessagesSub?.cancel();
    super.dispose();
  }
}
