import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/authentication/data/authentication_repository.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/bot_settings/data/bot_settings_repository.dart';
import 'package:teledesk/src/feature/telegram/controller/telegram_polling_controller.dart';
import 'package:teledesk/src/feature/worker_creation/data/worker_creation_repository.dart';
import 'package:teledesk/src/feature/worker_status_manager/data/worker_status_manager_repository.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

part 'authentication_controller.freezed.dart';

@freezed
sealed class AuthenticationState with _$AuthenticationState {
  const AuthenticationState._();

  const factory AuthenticationState.idle() = Authentication$IdleState;

  const factory AuthenticationState.inProgress() = Authentication$InProgressState;

  const factory AuthenticationState.error(String? message) = Authentication$ErrorState;

  const factory AuthenticationState.authenticated(Identity identity) =
      Authentication$AuthenticatedState;

  const factory AuthenticationState.needsSetup() = Authentication$NeedsSetupState;

  String? get error => switch (this) {
    final Authentication$ErrorState s => s.message,
    _ => null,
  };

  /// Returns the authenticated identity (Admin or Worker), or null.
  Identity? get identity => switch (this) {
    final Authentication$AuthenticatedState s => s.identity,
    _ => null,
  };

  /// Returns the Worker identity if authenticated as a Worker, or null.
  Worker? get worker => switch (this) {
    final Authentication$AuthenticatedState s => switch (s.identity) {
      Worker() => s.identity as Worker,
      _ => null,
    },
    _ => null,
  };

  /// Returns the Admin identity if authenticated as an Admin, or null.
  Admin? get admin => switch (this) {
    final Authentication$AuthenticatedState s => switch (s.identity) {
      Admin() => s.identity as Admin,
      _ => null,
    },
    _ => null,
  };

  bool get isAuthenticated => this is Authentication$AuthenticatedState;
}

final class AuthenticationController extends StateController<AuthenticationState>
    with DroppableControllerHandler {
  AuthenticationController({
    required final IAuthenticationRepository authenticationRepository,
    required final IWorkerCreationRepository workerCreationRepository,
    required final IWorkerStatusManagerRepository workerStatusManagerRepository,
    required final IWorkerRepository workerRepository,
    required final IBotSettingsRepository botSettingsRepository,
    required final TelegramPollingController pollingController,
    super.initialState = const AuthenticationState.idle(),
  }) : _iAuthenticationRepository = authenticationRepository,
       _iWorkerRepository = workerRepository,
       _iWorkerCreationRepository = workerCreationRepository,
       _iWorkerStatusManagerRepository = workerStatusManagerRepository,
       _iBotSettingsRepository = botSettingsRepository,
       _pollingController = pollingController;

  final IAuthenticationRepository _iAuthenticationRepository;
  final IWorkerRepository _iWorkerRepository;
  final IWorkerCreationRepository _iWorkerCreationRepository;
  final IWorkerStatusManagerRepository _iWorkerStatusManagerRepository;
  final IBotSettingsRepository _iBotSettingsRepository;
  final TelegramPollingController _pollingController;

  /// Check if first-time setup is needed
  void checkSetup() => handle(() async {
    setState(const AuthenticationState.inProgress());
    final count = await _iWorkerRepository.countWorkers();
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
    final worker = await _iWorkerCreationRepository.createWorker(
      username: username,
      password: password,
      displayName: displayName,
      role: IdentityRole.admin,
      colorCode: '#6366F1',
    );
    await _iWorkerStatusManagerRepository.updateStatus(worker.id, IdentityStatus.online);
    // Store as Admin identity
    final admin = Admin(
      id: worker.id,
      username: worker.username,
      displayName: worker.displayName,
      colorCode: worker.colorCode,
      status: IdentityStatus.online,
      createdAt: worker.createdAt,
    );
    setState(AuthenticationState.authenticated(admin));
  }, error: (e, st) async => setState(AuthenticationState.error(e.toString())));

  /// Sign in with username and password
  void signIn({required String username, required String password}) => handle(() async {
    setState(const AuthenticationState.inProgress());
    final identity = await _iAuthenticationRepository.authenticate(username, password);
    if (identity == null) {
      setState(const AuthenticationState.error('Invalid username or password'));
      return;
    }
    await _iWorkerStatusManagerRepository.updateStatus(identity.id, IdentityStatus.online);
    setState(AuthenticationState.authenticated(identity));
  }, error: (e, st) async => setState(AuthenticationState.error(e.toString())));

  /// Sign out — clears all chats but keeps the bot token connected
  void signOut() => handle(() async {
    final identity = state.identity;
    if (identity != null) {
      await _iWorkerStatusManagerRepository.updateStatus(identity.id, IdentityStatus.offline);
    }
    await _iBotSettingsRepository.clearChatData();
    setState(const AuthenticationState.idle());
  });

  /// Sign out and fully disconnect the bot — clears chats, token, and stops polling
  void resetAndSignOut() => handle(() async {
    final identity = state.identity;
    if (identity != null) {
      await _iWorkerStatusManagerRepository.updateStatus(identity.id, IdentityStatus.offline);
    }
    _pollingController.stopPolling();
    await _iBotSettingsRepository.clearAllData();
    setState(const AuthenticationState.idle());
  });
}
