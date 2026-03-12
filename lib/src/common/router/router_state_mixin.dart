import 'package:flutter/widgets.dart' show State, StatefulWidget, ValueNotifier;
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/router/authentication_guard.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';

mixin RouterStateMixin<T extends StatefulWidget> on State<T> {
  late final Octopus router;
  late final ValueNotifier<List<({Object error, StackTrace stackTrace})>> errorsObserver;

  @override
  void initState() {
    final dependencies = Dependencies.of(context);

    errorsObserver = ValueNotifier<List<({Object error, StackTrace stackTrace})>>(
      <({Object error, StackTrace stackTrace})>[],
    );

    router = Octopus(
      routes: Routes.values,
      defaultRoute: Routes.dashboard,
      guards: <IOctopusGuard>[
        AuthenticationGuard(
          getController: () => dependencies.authenticationController,
          authRoutes: <String>{Routes.signin.name, Routes.signup.name},
          signInNavigation: OctopusState.single(Routes.signin.node()),
          signUpNavigation: OctopusState.single(Routes.signup.node()),
          homeNavigation: OctopusState.single(Routes.dashboard.node()),
          refresh: dependencies.authenticationController,
        ),
      ],
      onError: (error, stackTrace) =>
          errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ...errorsObserver.value,
          ],
    );
    super.initState();
  }
}
