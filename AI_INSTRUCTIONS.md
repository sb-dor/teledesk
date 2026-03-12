# Flutter POS System Architecture Analysis

## Overview

This document analyzes the clean architecture implementation in the AveraPOS cloud Flutter application, focusing on the example feature as an example. The application follows a well-structured clean architecture pattern with clear separation of concerns.

## Clean Architecture Layers

### 1. Data Layer (`data/`)

The data layer handles data operations and implements repositories that interact with external sources.

#### Example: `example_repository.dart`

```dart
// Interface definition
abstract interface class IExampleRepository {
  Future<List<Example>> example({...});
}

// Implementation
final class ExampleRepositoryImpl implements IExampleRepository {
  ExampleRepositoryImpl({required final ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<Example>> example({...}) async {
    // API call implementation
    final response = await _apiClient.get(endpoint, queryParameters: queryParameters);
    // Data transformation logic
  }
}
```

**Key Patterns:**

- Abstract interfaces for testability
- Dependency injection through constructor
- API client abstraction
- Data transformation using converters

### 2. Model Layer (`models/`)

Models represent business entities and are immutable.

#### Example: `example.dart` (optional)

```dart
@immutable
class Example {
  const Example({
    required this.id,
    this.exampleId,
    this.example,
    // ... other properties
  });

  // Properties
  final int id;
  final int? exampleId;
  // ... other fields

  // Copy with method for immutability
 Example copyWith({...}) {
    return Example(
      id: id ?? this.id,
      // ... other fields
    );
  }
}
```

**Key Patterns:**

- Immutable design with `@immutable` annotation
- `copyWith` method for functional updates

### 3. Controller Layer (`controller/`)

Controllers manage state and business logic using reactive programming patterns.

#### Example: `example_controller.dart` (required)

```dart
@freezed
sealed class ExampleState with _$ExampleState {
  const factory ExampleState.initial() = Example$InitialState;

  const factory ExampleState.inProgress() = Example$InProgressState;

  const factory ExampleState.error() = Example$ErrorState;

  const factory ExampleState.completed({...}) =
      Example$CompletedState;
}

final class ExampleController extends StateController<ExampleState>
    with SequentialControllerHandler {
  ExampleController({
    required final IExampleRepository exampleRepository,
    super.initialState = const ExampleState.initial(),
  }) : _iExampleRepository = exampleRepository;

  final IExampleRepository _iExampleRepository;

  void load({...}) => handle(() async {
    setState(const ExampleState.inProgress());

    final example = await _iExampleRepository.example({...});

    setState(
      ExampleState.completed(),
    );
  }, error: (error, stackTrace) async => setState(const ExampleState.error()));
}
```

**Key Patterns:**

- Freezed for immutable state management
- Dependency injection through constructor
- Sequential handling to prevent race conditions
- State management with loading/error/completed states

### 4. Widgets Layer (`widgets/`)

The presentation layer handles UI rendering and user interaction.

#### Example: `example_config_widget.dart`

```dart
/// Inherited widgets that provides access to ExampleConfigWidgetState throughout the widgets tree.
class ExampleConfigInhWidget extends InheritedWidget {
  const ExampleConfigInhWidget({super.key, required this.state, required super.child});

  static ExampleConfigWidgetState of(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<ExampleConfigInhWidget>()
        ?.widget;
    assert(widget != null, 'ExampleConfigInhWidget was not found in element tree');
    return (widget as ExampleConfigInhWidget).state;
  }

  final ExampleConfigWidgetState state;

  @override
  bool updateShouldNotify(ExampleConfigInhWidget old) {
    return false;
  }
}

class ExampleConfigWidget extends StatefulWidget {
  const ExampleConfigWidget();
  // Implementation details

  @override
  State<ExampleConfigWidget> createState() => ExampleConfigWidgetState();
}

class ExampleConfigWidgetState extends State<ExampleConfigWidget> {
  // Controller initialization and lifecycle management
  late final ExampleController exampleController;

  @override
  void initState() {
    super.initState();
    final dependencies = DependenciesScope.of(context);
    _authenticationController = dependencies.authenticationController;
    _authenticationListener();
    _authenticationController.addListener(_authenticationListener);
  }

  @override
  void dispose() {
    _authenticationController.removeListener(_authenticationListener);
    exampleController.dispose();
    super.dispose();
  }

  void _authenticationListener() {
    // Initialize controller based on authentication state
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicatorWidget())
        : ExampleConfigInhWidget(
            state: this,
            child: context.screenSizeMaybeWhen(
              orElse: () => const ExampleDesktopWidget(),
              phone: () => const ExampleMobileWidget(),
            ),
          );
  }
}
```

**Key Patterns:**

- InheritedWidget for dependency propagation
- Proper lifecycle management with disposal
- Responsive UI based on screen size
- Authentication-aware initialization

#### Example: `example_data_controller.dart` (UI State Management)

```dart
class ExampleDataController with ChangeNotifier {
  ///
  ///
  /// not optional - it's just for an example
  String? _from;

  String? _to;

  String? get from => _from;

  String? get to => _to;

  final List<Example> _selectedExamples = [];

  List<Example> get selectedExamples => _selectedExamples;

  void addExample(final Example example) {
    _selectedExamples.add(example);
    notifyListeners()
  }
}
```

**Key Patterns:**

- Uses `ChangeNotifier` mixin for UI state management
- Different from `example_controller.dart` which manages asynchronous operations and application state
- `example_data_controller.dart` specifically manages UI-related state
- Provides getter methods for accessing state values
- Uses `notifyListeners()` to trigger UI updates when state changes
- Includes proper lifecycle management with disposal considerations
- Do not use other state solutions like these packages: Provider, Riverpod, Mobx, Getx, BloC for UI state management for widgets folder

## Dependency Injection Patterns

### Global Dependency Injection

The application uses a global dependency injection system through `DependenciesScope`:

#### `Dependencies` Class

```dart
class Dependencies {
  late final AppMetadata metadata;
  late final SharedPreferences sharedPreferences;
  late final AppDatabase database;
  late final ApiClient apiClient;
  late final InternetConnectionController internetConnectionController;
  // ... other dependencies

  Widget inject({required Widget child, Key? key}) =>
      DependenciesScope(dependencies: this, key: key, child: child);
}
```

#### `DependenciesScope` Widget

```dart
class DependenciesScope extends InheritedWidget {
  const DependenciesScope({required this.dependencies, required super.child, super.key});

  final Dependencies dependencies;

  static Dependencies of(BuildContext context) =>
      maybeOf(context) ?? _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(covariant DependenciesScope oldWidget) => false;
}
```

### Feature-Level Dependency Injection

Features use their own configuration widgets to initialize and provide controllers:

#### `example_config_widget.dart` (Dependency Initialization)

```dart
void _authenticationListener() {
  final authenticationState = _authenticationController.state;
  if (authenticationState is Authentication$AuthenticatedState && isLoading) {
    /// initializations for Authanticated state
  }
}
```

## Interface Usage and DI Concepts

### Interface-Based Design

The application extensively uses interfaces for loose coupling:

```dart
// Repository interfaces
abstract interface class IExampleRepository {...}
abstract interface class IProductsRepository {...}
abstract interface class IExampleBalanceRepository {...}

// Controller interfaces (when applicable)
```

### Constructor-Based Dependency Injection

Dependencies are injected through constructors:

```dart
// Repository implementation receives API client
ExampleRepositoryImpl({required final ApiClient apiClient}) : _apiClient = apiClient;

// Controller receives repository interface
ExampleController({
  required final IExampleRepository exampleRepository,
  // ...
})

// Widget receives dependencies through scope
dependencies = DependenciesScope.of(context);
```

## Scope Management with Inherited Widgets

### InheritedWidget Pattern

The application uses InheritedWidget for efficient state propagation:

```dart
// Custom InheritedWidget for feature-specific state
class ExampleConfigInhWidget extends InheritedWidget {
  const ExampleConfigInhWidget({super.key, required this.state, required super.child});

  static ExampleConfigWidgetState of(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<ExampleConfigInhWidget>()
        ?.widget;
    assert(widget != null, 'ExampleConfigInhWidget was not found in element tree');
    return (widget as ExampleConfigInhWidget).state;
  }

  final ExampleConfigWidgetState state;

  @override
  bool updateShouldNotify(ExampleConfigInhWidget old) {
    return false; // Prevent unnecessary rebuilds
 }
}
```

### Global Scope with DependenciesScope

Global dependencies are provided through the DependenciesScope:

```dart
// In main app setup
dependencies.inject(child: MaterialApp(...))

// In widgets accessing dependencies
final deps = DependenciesScope.of(context);
```

## Feature Structure Analysis: Example

### Directory Structure

```
example/
├── controller/
│   └── example_controller.dart
├── data/
│   └── example_repository.dart
├── models/
│   ├── example.dart
│   ├── example_other_1.dart
│   ├── example_other_2.dart
│   ├── example_other_3.dart
│   └── ...
└── widgets/
    ├── controllers/
    │   └── example_data_controller.dart
    ├── desktop/example_desktop_widget.dart
    ├── mobile/example_mobile_widget.dart
    ├── tablet/example_tablet_widget.dart
    └── example_config_widget.dart
```

### Layer Integration

1. **UI Layer**: `example_config_widget.dart` initializes and manages feature controllers
2. **Presentation Layer**: `example_data_controller.dart` manages UI state
3. \*\*Business Logic Layer: `example_controller.dart` handles business logic and state
4. **Data Layer**: `example_repository.dart` handles data operations
5. **Model Layer**: `example.dart` represents domain entities

## Best Practices Observed

### 1. Separation of Concerns

- Each layer has a clear responsibility
- Models handle data representation
- Controllers manage business logic and state
- Repositories handle data operations
- Widgets handle presentation

### 2. Testability

- Interface-based design enables mocking
- Constructor injection enables easy testing
- Immutable models reduce side effects

### 3. Maintainability

- Consistent naming conventions
- Clear directory structure
- Proper separation of business logic from UI

### 4. Performance

- Efficient InheritedWidget usage
- Proper disposal of resources
- Lazy loading where appropriate

## Additional Development Notes

### Generated Files

When working with this architecture, be aware of generated Dart files that should be ignored in version control and manual editing:

- Files ending with `.freezed.dart` (generated by the `freezed` package)
- Files ending with `.g.dart` (generated by various packages like `json_annotation`, `injectable`, etc.)
- Any other files with the `.g.dart` suffix
- Other generated files following the pattern `[filename].generated.dart`

These files should be added to your `.gitignore` file and should never be manually modified, as they are automatically regenerated by build runners.

### Build Runner Command

After creating a new feature or making changes that require code generation (such as adding new Freezed classes, JSON serialization annotations, or other annotated classes), run these following commands to generate the required files:

```bash
dart run build_runner build && dart format lib/
```

This command will generate all necessary files based on annotations in your code, such as Freezed classes, JSON serializers, and other generated code.

### Model CopyWith Pattern

For models that use the `copyWith` method, they must use the `ValueGetter` function from the foundation package for optional parameters. This ensures proper null-safety and functional updates:

```dart
Example copyWith({
  int? id,
  ValueGetter<double?>? parameter_1,
  ValueGetter<double?>? parameter_2,
  ValueGetter<double?>? invoicesQty,
  ValueGetter<double?>? returnsTotal,
  ValueGetter<double?>? returnsQty,
  ValueGetter<double?>? paymentsTotal,
  ValueGetter<double?>? paymentsQty,
  ValueGetter<double?>? grandTotal,
  // ... other parameters
}) {
  return Example(
    id: id ?? this.id,
    parameter_1: parameter_1 != null ? parameter_1() : this.parameter_1,
    parameter_2: parameter_2 != null ? parameter_2() : this.parameter_2,
    invoicesQty: invoicesQty != null ? invoicesQty() : this.invoicesQty,
    returnsTotal: returnsTotal != null ? returnsTotal() : this.returnsTotal,
    returnsQty: returnsQty != null ? returnsQty() : this.returnsQty,
    paymentsTotal: paymentsTotal != null ? paymentsTotal() : this.paymentsTotal,
    paymentsQty: paymentsQty != null ? paymentsQty() : this.paymentsQty,
    grandTotal: grandTotal != null ? grandTotal() : this.grandTotal,
    // ... assign other parameters
  );
}
```

### Accessing Dependencies Through Inherited Widgets

To access dependencies that were initialized inside the `ExampleConfigWidget`, use the `ExampleConfigInhWidget.of(context)` pattern. For example, if you have an `ExampleMobileWidget` that needs to access the `ExampleDataController` initialized in the `ExampleConfigWidget`:

```dart
class ExampleMobileWidget extends StatefulWidget {
  const ExampleMobileWidget({super.key});

  @override
  State<ExampleMobileWidget> createState() =>
      _ExampleMobileWidgetState();
}

class _ExampleMobileWidgetState
    extends State<ExampleMobileWidget> {
  late final _exampleInhWidget = ExampleConfigInhWidget.of(
    context,
  );

  late final _exampleDataController =
      _exampleInhWidget.exampleDataController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _exampleDataController,
      builder: (context, child) {
        // Build UI based on the controller's state
        return Container(
          // Your widget implementation
        );
      },
    );
  }
}
```

### Modern Dart Constructor Syntax

Use the modern Dart syntax for calling the parent constructor in the super parameter. Instead of the old approach of extending child constructors with explicit `super()` calls, you can now use the `super()` named parameter directly:

```dart
// Modern approach
const ExampleMobileWidget({super.key});

// Rather than the older approach which required more verbose syntax
```

### Using ListenableBuilder for ChangeNotifier

When listening to an `ExampleDataController` (which extends `ChangeNotifier`), use `ListenableBuilder` instead of `ValueListenableBuilder`. `ListenableBuilder` is designed for objects that extend `Listenable` (like `ChangeNotifier`), while `ValueListenableBuilder` is specifically for `ValueNotifier`:

```dart
// Correct approach for ChangeNotifier
ListenableBuilder(
  listenable: exampleDataController,
  builder: (context, child) {
    // Return your widget here
    return YourWidget();
  },
)

// Rather than ValueListenableBuilder which is for ValueNotifier
```

## Conclusion

The AveraPOS Flutter application demonstrates a well-implemented clean architecture with:

- Clear separation of concerns across data, domain, and presentation layers
- Comprehensive dependency injection using both global and feature-level approaches
- Effective use of InheritedWidget for state management and dependency propagation
- Consistent patterns across all features
- Proper lifecycle management and resource disposal

The example feature serves as an excellent example of how the architecture principles are applied consistently throughout the application, maintaining scalability and maintainability while following Flutter best practices.