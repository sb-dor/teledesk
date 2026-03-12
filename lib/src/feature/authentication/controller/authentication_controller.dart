import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/authentication/data/worker_repository.dart';
import 'package:teledesk/src/feature/authentication/model/worker.dart';

part 'authentication_controller.freezed.dart';

@freezed
sealed class AuthenticationState with _$AuthenticationState {
  const AuthenticationState._();

  const factory AuthenticationState.idle() = Authentication$IdleState;
  const factory AuthenticationState.inProgress() = Authentication$InProgressState;
  const factory AuthenticationState.error(String? message) = Authentication$ErrorState;
  const factory AuthenticationState.authenticated(Worker worker) =
      Authentication$AuthenticatedState;
  const factory AuthenticationState.needsSetup() = Authentication$NeedsSetupState;

  String? get error => switch (this) {
    final Authentication$ErrorState s => s.message,
    _ => null,
  };

  Worker? get worker => switch (this) {
    final Authentication$AuthenticatedState s => s.worker,
    _ => null,
  };

  bool get isAuthenticated => this is Authentication$AuthenticatedState;
}

final class AuthenticationController extends StateController<AuthenticationState>
    with DroppableControllerHandler {
  AuthenticationController({
    required IWorkerRepository workerRepository,
    super.initialState = const AuthenticationState.idle(),
  }) : _repository = workerRepository;

  final IWorkerRepository _repository;

  /// Check if first-time setup is needed
  void checkSetup() => handle(() async {
    setState(const AuthenticationState.inProgress());
    final count = await _repository.countWorkers();
    if (count == 0) {
      setState(const AuthenticationState.needsSetup());
    } else {
      setState(const AuthenticationState.idle());
    }
  });

  /// Create the first admin account
  void createFirstAdmin({
    required String username,
    required String password,
    required String displayName,
  }) => handle(() async {
    setState(const AuthenticationState.inProgress());
    final worker = await _repository.createWorker(
      username: username,
      password: password,
      displayName: displayName,
      role: WorkerRole.admin,
      colorCode: '#6366F1',
    );
    await _repository.updateStatus(worker.id, WorkerStatus.online);
    setState(AuthenticationState.authenticated(worker.copyWith(status: WorkerStatus.online)));
  }, error: (e, st) async => setState(AuthenticationState.error(e.toString())));

  /// Sign in with username and password
  void signIn({required String username, required String password}) => handle(() async {
    setState(const AuthenticationState.inProgress());
    final worker = await _repository.authenticate(username, password);
    if (worker == null) {
      setState(const AuthenticationState.error('Invalid username or password'));
      return;
    }
    await _repository.updateStatus(worker.id, WorkerStatus.online);
    setState(AuthenticationState.authenticated(worker.copyWith(status: WorkerStatus.online)));
  }, error: (e, st) async => setState(AuthenticationState.error(e.toString())));

  /// Sign out
  void signOut() => handle(() async {
    final worker = state.worker;
    if (worker != null) {
      await _repository.updateStatus(worker.id, WorkerStatus.offline);
    }
    setState(const AuthenticationState.idle());
  });

  /// Add a worker (admin only)
  void addWorker({
    required String username,
    required String password,
    required String displayName,
    required WorkerRole role,
    required String colorCode,
  }) => handle(() async {
    await _repository.createWorker(
      username: username,
      password: password,
      displayName: displayName,
      role: role,
      colorCode: colorCode,
    );
  }, error: (e, st) async => setState(AuthenticationState.error(e.toString())));
}
