import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/worker_creation/data/worker_creation_repository.dart';

part 'worker_creation_controller.freezed.dart';

@freezed
sealed class WorkerCreationState with _$WorkerCreationState {
  const factory WorkerCreationState.idle() = WorkerCreation$IdleState;

  const factory WorkerCreationState.inProgress() = WorkerCreation$InProgressState;

  const factory WorkerCreationState.error({final String? message}) = WorkerCreation$ErrorState;

  const factory WorkerCreationState.completed(final Worker worker) = WorkerCreation$CompletedState;
}

class WorkerCreationController extends StateController<WorkerCreationState>
    with DroppableControllerHandler {
  WorkerCreationController({
    required IWorkerCreationRepository workerCreationRepository,
    super.initialState = const WorkerCreationState.idle(),
  }) : _iWorkerCreationRepository = workerCreationRepository;

  final IWorkerCreationRepository _iWorkerCreationRepository;

  void addWorker({
    required String username,
    required String password,
    required String displayName,
    required IdentityRole role,
    required String colorCode,
  }) => handle(() async {
    setState(const WorkerCreationState.inProgress());
    final worker = await _iWorkerCreationRepository.createWorker(
      username: username,
      password: password,
      displayName: displayName,
      role: role,
      colorCode: colorCode,
    );
    setState(WorkerCreationState.completed(worker));
  }, error: (e, st) async => setState(const WorkerCreationState.error()));
}
