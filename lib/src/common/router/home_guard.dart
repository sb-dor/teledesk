import 'dart:async';

import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/router/routes.dart';

/// Check routes always contain the dashboard route at the first position.
/// Only exception for not authenticated users.
class HomeGuard extends OctopusGuard {
  HomeGuard();

  static final String _dashboardName = Routes.dashboard.name;

  @override
  Future<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    // Home route should be the first route in the state
    // and should be only one in whole state.
    if (state.isEmpty) return _fix(state);
    final count = state.findAllByName(_dashboardName).length;
    if (count != 1) return _fix(state);
    if (state.children.first.name != _dashboardName) return _fix(state);
    return state;
  }

  /// Change the state of the nested navigation.
  OctopusState _fix(OctopusState$Mutable state) => state
    ..clear()
    ..putIfAbsent(_dashboardName, () => Routes.dashboard.node());
}
