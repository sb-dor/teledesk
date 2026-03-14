import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/worker_change_password/data/worker_change_password_repository.dart';

part 'worker_change_password_controller.freezed.dart';

@freezed
sealed class WorkerChangePasswordState with _$WorkerChangePasswordState {
  const factory WorkerChangePasswordState.idle() = WorkerChangePassword$IdleState;

  const factory WorkerChangePasswordState.inProgress() = WorkerChangePassword$InProgressState;

  const factory WorkerChangePasswordState.error({final String? message}) =
      WorkerChangePassword$ErrorState;

  const factory WorkerChangePasswordState.completed() = WorkerChangePassword$CompletedState;
}

class WorkerChangePasswordController extends StateController<WorkerChangePasswordState>
    with DroppableControllerHandler {
  WorkerChangePasswordController({
    required IWorkerChangePasswordRepository workerChangePasswordRepository,
    required super.initialState,
  }) : _iWorkerChangePasswordRepository = workerChangePasswordRepository;

  final IWorkerChangePasswordRepository _iWorkerChangePasswordRepository;

  void changePassword(int workerId, String newPassword) => handle(() async {
    setState(const WorkerChangePasswordState.inProgress());

    final save = await _iWorkerChangePasswordRepository.updatePassword(workerId, newPassword);

    if (save) {
      setState(const WorkerChangePasswordState.completed());
    } else {
      setState(const WorkerChangePasswordState.idle());
    }
  }, error: (error, stackTrace) async => setState(const WorkerChangePasswordState.error()));
}
