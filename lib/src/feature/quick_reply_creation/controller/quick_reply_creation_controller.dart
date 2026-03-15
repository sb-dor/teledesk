import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';
import 'package:teledesk/src/feature/quick_reply_creation/data/quick_reply_creation_repository.dart';

part 'quick_reply_creation_controller.freezed.dart';

@freezed
sealed class QuickReplyCreationState with _$QuickReplyCreationState {
  const factory QuickReplyCreationState.initial() = QuickReplyCreation$InitialState;

  const factory QuickReplyCreationState.inProgress() = QuickReplyCreation$InProgressState;

  const factory QuickReplyCreationState.error({final String? message}) =
      QuickReplyCreation$ErrorState;

  const factory QuickReplyCreationState.completed(final QuickReply quickReply) =
      QuickReplyCreation$CompletedState;
}

class QuickReplyCreationController extends StateController<QuickReplyCreationState>
    with DroppableControllerHandler {
  QuickReplyCreationController({
    required final IQuickReplyCreationRepository iQuickReplyCreationRepository,
    super.initialState = const QuickReplyCreationState.initial(),
  }) : _iQuickReplyCreationRepository = iQuickReplyCreationRepository;

  final IQuickReplyCreationRepository _iQuickReplyCreationRepository;

  void save({
    required String title,
    required String content,
    int? workerId,
    QuickReply? existing,
  }) => handle(() async {
    setState(const QuickReplyCreationState.inProgress());
    final quickReply = await _iQuickReplyCreationRepository.save(
      title: title,
      content: content,
      workerId: workerId,
      existing: existing,
    );
    setState(QuickReplyCreationState.completed(quickReply));
  }, error: (e, st) async => setState(const QuickReplyCreationState.error()));
}
