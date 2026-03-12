import 'package:flutter/widgets.dart';
import 'package:teledesk/src/feature/authentication/controller/authentication_controller.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';

/// {@template authentication_scope}
/// AuthenticationScope widget.
/// {@endtemplate}
class AuthenticationScope extends StatefulWidget {
  /// {@macro authentication_scope}
  const AuthenticationScope({required this.child, super.key});

  final Widget child;

  static Identity? identityOf(BuildContext context, {bool listen = true}) =>
      _InheritedAuth.of(context, listen: listen).state.identity;

  static AuthenticationController controllerOf(BuildContext context) =>
      _InheritedAuth.of(context, listen: false).controller;

  static bool isAuthenticatedOf(BuildContext context, {bool listen = true}) =>
      _InheritedAuth.of(context, listen: listen).state.isAuthenticated;

  @override
  State<AuthenticationScope> createState() => _AuthenticationScopeState();
}

class _AuthenticationScopeState extends State<AuthenticationScope> {
  late final AuthenticationController controller;

  @override
  void initState() {
    super.initState();
    controller = Dependencies.of(context).authenticationController;
    controller
      ..addListener(_listener)
      // Check if first-time setup is needed
      ..checkSetup();
  }

  void _listener() {
    if (!mounted) return;
    setState(() {});
    // Start/stop polling based on auth state
    final pollingController = Dependencies.of(context).telegramPollingController;
    if (controller.state.isAuthenticated) {
      pollingController.startPolling();
    } else {
      pollingController.stopPolling();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _InheritedAuth(controller: controller, state: controller.state, child: widget.child);
}

class _InheritedAuth extends InheritedWidget {
  const _InheritedAuth({required this.controller, required this.state, required super.child});

  final AuthenticationController controller;
  final AuthenticationState state;

  static _InheritedAuth? maybeOf(BuildContext context, {bool listen = true}) => listen
      ? context.dependOnInheritedWidgetOfExactType<_InheritedAuth>()
      : context.getInheritedWidgetOfExactType<_InheritedAuth>();

  static _InheritedAuth of(BuildContext context, {bool listen = true}) =>
      maybeOf(context, listen: listen) ??
      (throw ArgumentError(
        'Out of scope, not found inherited widget a _InheritedAuth of the exact type',
        'out_of_scope',
      ));

  @override
  bool updateShouldNotify(_InheritedAuth old) => !identical(old.state, state);
}
