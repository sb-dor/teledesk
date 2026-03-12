import 'dart:async';

import 'package:octopus/octopus.dart';
import 'package:teledesk/src/feature/authentication/controller/authentication_controller.dart';

/// A router guard that checks authentication state and routes accordingly.
/// - needsSetup  -> signup screen
/// - idle/error  -> signin screen
/// - authenticated -> dashboard
class AuthenticationGuard extends OctopusGuard {
  AuthenticationGuard({
    required AuthenticationController Function() getController,
    required Set<String> authRoutes,
    required OctopusState signInNavigation,
    required OctopusState signUpNavigation,
    required OctopusState homeNavigation,
    OctopusState? lastNavigation,
    super.refresh,
  }) : _getController = getController,
       _authRoutes = authRoutes,
       _signInNavigation = signInNavigation,
       _signUpNavigation = signUpNavigation,
       _lastNavigation = lastNavigation ?? homeNavigation;

  final AuthenticationController Function() _getController;
  final Set<String> _authRoutes;
  final OctopusState _signInNavigation;
  final OctopusState _signUpNavigation;
  OctopusState _lastNavigation;

  @override
  Future<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    final controller = _getController();
    final authState = controller.state;

    final isAuthNav = state.children.any((child) => _authRoutes.contains(child.name));

    if (authState is Authentication$AuthenticatedState) {
      // Authenticated: redirect away from auth screens
      if (isAuthNav) {
        state.removeWhere((child) => _authRoutes.contains(child.name));
        return state.isEmpty ? _lastNavigation : state;
      }
      _lastNavigation = state;
      return super.call(history, state, context);
    } else if (authState is Authentication$NeedsSetupState) {
      // First time setup
      return _signUpNavigation;
    } else {
      // Not authenticated (idle, error, inProgress)
      if (isAuthNav) {
        // Already on an auth screen — allow it
        state.removeWhere((child) => !_authRoutes.contains(child.name));
        return state.isEmpty ? _signInNavigation : state;
      }
      return _signInNavigation;
    }
  }
}
