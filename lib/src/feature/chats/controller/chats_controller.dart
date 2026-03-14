import 'dart:async';
import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/chats/data/chats_repository.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';

part 'chats_controller.freezed.dart';

@freezed
sealed class ChatsState with _$ChatsState {
  const factory ChatsState.idle({
    @Default([]) List<Conversation> openConversations,
    @Default([]) List<Conversation> myConversations,
  }) = Chats$IdleState;

  const factory ChatsState.loading() = Chats$LoadingState;

  const factory ChatsState.error(String message) = Chats$ErrorState;
}

final class ChatsController extends StateController<ChatsState> with SequentialControllerHandler {
  ChatsController({required IChatsRepository repository, required int workerId})
    : _repository = repository,
      _workerId = workerId,
      super(initialState: const ChatsState.loading());

  final IChatsRepository _repository;
  final int _workerId;
  StreamSubscription<List<Conversation>>? _openSub;
  StreamSubscription<List<Conversation>>? _mineSub;
  List<Conversation> _open = [];
  List<Conversation> _mine = [];

  void initialize() {
    _openSub = _repository.watchOpenConversations().listen((open) {
      _open = open;
      _emit();
    });
    _mineSub = _repository.watchWorkerConversations(_workerId).listen((mine) {
      _mine = mine;
      _emit();
    });
  }

  void _emit() {
    setState(ChatsState.idle(openConversations: _open, myConversations: _mine));
  }

  @override
  void dispose() {
    _openSub?.cancel();
    _mineSub?.cancel();
    super.dispose();
  }
}
