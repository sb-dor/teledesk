import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/worker_deactivation/data/worker_deactivation_repository.dart';

part 'worker_deactivation_controller.freezed.dart';

@freezed
sealed class WorkerDeactivationState with _$WorkerDeactivationState {
  const factory WorkerDeactivationState.idle() = WorkerDeactivation$IdleState;

  const factory WorkerDeactivationState.inProgress() = WorkerDeactivation$InProgressState;

  const factory WorkerDeactivationState.error({final String? message}) =
      WorkerDeactivation$ErrorState;

  const factory WorkerDeactivationState.completed() = WorkerDeactivation$CompletedState;
}

class WorkerDeactivationController extends StateController with DroppableControllerHandler {
  WorkerDeactivationController({
    required final IWorkerDeactivationRepository workerDeactivationRepository,
    super.initialState = const WorkerDeactivationState.idle(),
  }) : _iWorkerDeactivationRepository = workerDeactivationRepository;

  final IWorkerDeactivationRepository _iWorkerDeactivationRepository;

  void deactivate(int workerId) => handle(() async {
    setState(const WorkerDeactivationState.inProgress());
    final deactivate = await _iWorkerDeactivationRepository.deactivateWorker(workerId);
    if (deactivate) {
      setState(const WorkerDeactivationState.completed());
    } else {
      setState(const WorkerDeactivationState.error());
    }
  }, error: (e, st) async => setState(const WorkerDeactivationState.error()));
}
