import 'dart:async';

import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/dashboard/data/dashboard_repository.dart';

part 'dashboard_controller.freezed.dart';

@freezed
sealed class DashboardState with _$DashboardState {
  const DashboardState._();

  const factory DashboardState.idle() = Dashboard$IdleState;

  const factory DashboardState.inProgress() = Dashboard$InProgressState;

  const factory DashboardState.error({final String? message}) = Dashboard$ErrorState;

  const factory DashboardState.completed(final Map<String, int> stats) = Dashboard$CompletedState;

  bool get isInProgress => this is Dashboard$InProgressState;

  Map<String, int> get stats => switch (this) {
    final Dashboard$CompletedState state => state.stats,
    _ => <String, int>{},
  };
}

class DashboardController extends StateController<DashboardState> with SequentialControllerHandler {
  DashboardController({
    required IDashboardRepository dashboardRepository,
    super.initialState = const DashboardState.idle(),
  }) : _iDashboardRepository = dashboardRepository;

  final IDashboardRepository _iDashboardRepository;
  StreamSubscription<Map<String, int>>? _statsSub;

  void initialize() {
    setState(const DashboardState.inProgress());
    _statsSub = _iDashboardRepository.watchDashboardStats().listen(
      (stats) => setState(DashboardState.completed(stats)),
      onError: (_) => setState(const DashboardState.error()),
    );
  }

  void load() => handle(() async {
    setState(const DashboardState.inProgress());
    final stats = await _iDashboardRepository.getDashboardStats();
    setState(DashboardState.completed(stats));
  }, error: (error, stackTrace) async => setState(const DashboardState.error()));

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }
}
