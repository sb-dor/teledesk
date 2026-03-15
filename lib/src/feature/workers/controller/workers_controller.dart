import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

part 'workers_controller.freezed.dart';

@freezed
sealed class WorkersState with _$WorkersState {
  const WorkersState._();

  const factory WorkersState.idle() = Workers$IdleState;

  const factory WorkersState.inProgress() = Workers$InProgressState;

  const factory WorkersState.error({final String? message}) = Workers$ErrorState;

  const factory WorkersState.completed(List<Worker> workers) = Workers$CompletedState;

  List<Worker> get workers => switch (this) {
    final Workers$CompletedState s => s.workers,
    _ => const [],
  };
}

final class WorkersController extends StateController<WorkersState>
    with SequentialControllerHandler {
  WorkersController({required IWorkerRepository repository})
    : _repository = repository,
      super(initialState: const WorkersState.idle());

  final IWorkerRepository _repository;

  void load() => handle(() async {
    setState(const WorkersState.inProgress());
    final workers = await _repository.getWorkers();
    setState(WorkersState.completed(workers));
  }, error: (e, st) async => setState(const WorkersState.error()));
}
