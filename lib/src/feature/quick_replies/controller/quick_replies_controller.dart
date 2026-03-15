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

  void load() => handle(() async {
    setState(const QuickRepliesState.loading());
    final replies = await _repository.getAll();
    setState(QuickRepliesState.idle(replies));
  }, error: (e, st) async => setState(QuickRepliesState.error(e.toString())));
}
