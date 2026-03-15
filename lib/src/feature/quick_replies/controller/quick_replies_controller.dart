import 'dart:async';

import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

part 'quick_replies_controller.freezed.dart';

@freezed
sealed class QuickRepliesState with _$QuickRepliesState {
  const QuickRepliesState._();

  const factory QuickRepliesState.loading() = QuickReplies$LoadingState;

  const factory QuickRepliesState.idle(List<QuickReply> replies) = QuickReplies$IdleState;

  const factory QuickRepliesState.error(String message) = QuickReplies$ErrorState;

  List<QuickReply> get replies => switch (this) {
    final QuickReplies$IdleState s => s.replies,
    _ => const [],
  };
}

final class QuickRepliesController extends StateController<QuickRepliesState>
    with SequentialControllerHandler {
  QuickRepliesController({required IQuickReplyRepository repository})
    : _repository = repository,
      super(initialState: const QuickRepliesState.loading());

  final IQuickReplyRepository _repository;
  StreamSubscription<List<QuickReply>>? _sub;

  void initialize() {
    _sub = _repository.watchAll().listen(
      (replies) => setState(QuickRepliesState.idle(replies)),
      onError: (e) => setState(QuickRepliesState.error(e.toString())),
    );
  }

  void update(QuickReply reply) => handle(
    () async => _repository.update(reply),
    error: (e, st) async => setState(QuickRepliesState.error(e.toString())),
  );

  void delete(int id) => handle(
    () async => _repository.delete(id),
    error: (e, st) async => setState(QuickRepliesState.error(e.toString())),
  );

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
