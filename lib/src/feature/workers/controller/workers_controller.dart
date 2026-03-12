import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/authentication/data/worker_repository.dart';
import 'package:teledesk/src/feature/authentication/model/worker.dart';

part 'workers_controller.freezed.dart';

@freezed
sealed class WorkersState with _$WorkersState {
  const factory WorkersState.idle(List<Worker> workers) = Workers$IdleState;
  const factory WorkersState.loading() = Workers$LoadingState;
  const factory WorkersState.error(String message) = Workers$ErrorState;
}

final class WorkersController extends StateController<WorkersState>
    with SequentialControllerHandler {
  WorkersController({required IWorkerRepository repository})
      : _repository = repository,
        super(initialState: const WorkersState.loading());

  final IWorkerRepository _repository;

  void load() => handle(
        () async {
          setState(const WorkersState.loading());
          final workers = await _repository.getWorkers();
          setState(WorkersState.idle(workers));
        },
        error: (e, st) async =>
            setState(WorkersState.error(e.toString())),
      );

  void addWorker({
    required String username,
    required String password,
    required String displayName,
    required WorkerRole role,
    required String colorCode,
  }) =>
      handle(
        () async {
          await _repository.createWorker(
            username: username,
            password: password,
            displayName: displayName,
            role: role,
            colorCode: colorCode,
          );
          load();
        },
        error: (e, st) async =>
            setState(WorkersState.error(e.toString())),
      );

  void changePassword(int workerId, String newPassword) => handle(
        () async {
          await _repository.updatePassword(workerId, newPassword);
        },
      );

  void deactivate(int workerId) => handle(
        () async {
          await _repository.deactivateWorker(workerId);
          load();
        },
        error: (e, st) async =>
            setState(WorkersState.error(e.toString())),
      );
}
