import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/feature/authentication/controller/authentication_controller.dart';
import 'package:teledesk/src/feature/authentication/data/authentication_repository.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/initialization/widget/app.dart';
import 'package:teledesk/src/feature/initialization/widget/dependencies_scope.dart';
import 'package:teledesk/src/feature/settings/widget/settings_scope.dart';
import 'package:teledesk/src/feature/worker_creation/data/worker_creation_repository.dart';
import 'package:teledesk/src/feature/worker_status_manager/data/worker_status_manager_repository.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

void main() => group('Widget', () {
  testWidgets('Dependencies_are_injected', (tester) async {
    await tester.pumpWidget(FakeDependencies().inject(child: Container()));
    expect(find.byType(Container), findsOneWidget);
    expect(find.byType(DependenciesScope), findsOneWidget);
    final context = tester.element(find.byType(Container));
    expect(
      Dependencies.of(context),
      allOf(isNotNull, isA<Dependencies>(), isA<FakeDependencies>()),
    );
  });

  testWidgets('App', (tester) async {
    final dependencies = FakeDependencies()
      ..authenticationController = AuthenticationController(
        workerRepository: FakeWorderRepoImpl(),
        authenticationRepository: AuthenticationRepositoryFake(),
        workerCreationRepository: FakeWorkerCreationRepositoryImpl(),
        workerStatusManagerRepository: FakeWorkerStatusManagerRepository(),
      );
    await tester.pumpWidget(
      dependencies.inject(
        child: const SettingsScope(child: NoAnimationScope(noAnimation: true, child: App())),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(DependenciesScope), findsOneWidget);
  });
});
