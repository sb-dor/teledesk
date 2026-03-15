import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/data/quick_reply_deletion_repository.dart';

part 'quick_reply_deletion_controller.freezed.dart';

@freezed
sealed class QuickReplyDeletionState with _$QuickReplyDeletionState {
  const factory QuickReplyDeletionState.initial() = QuickReplyDeletion$InitialState;

  const factory QuickReplyDeletionState.inProgress() = QuickReplyDeletion$InProgressState;

  const factory QuickReplyDeletionState.error({final String? message}) =
      QuickReplyDeletion$ErrorState;

  const factory QuickReplyDeletionState.completed() = QuickReplyDeletion$CompletedState;
}

class QuickReplyDeletionController extends StateController<QuickReplyDeletionState>
    with DroppableControllerHandler {
  QuickReplyDeletionController({
    required final IQuickReplyDeletionRepository iQuickReplyDeletionRepository,
    super.initialState = const QuickReplyDeletionState.initial(),
  }) : _iQuickReplyDeletionRepository = iQuickReplyDeletionRepository;

  final IQuickReplyDeletionRepository _iQuickReplyDeletionRepository;

  void delete(int id) => handle(() async {
    setState(const QuickReplyDeletionState.inProgress());
    await _iQuickReplyDeletionRepository.delete(id);
    setState(const QuickReplyDeletionState.completed());
  }, error: (e, st) async => setState(const QuickReplyDeletionState.error()));
}
