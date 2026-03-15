# Contributing to TeleDesk

Thank you for your interest in contributing! Before you start, please read through this guide.

## How This Project Was Built

TeleDesk was developed through **vibe coding** — an iterative, conversation-driven approach using
[Claude Code](https://claude.ai/claude-code) by Anthropic. The architecture, features, and bug
fixes were shaped collaboratively between the developer and Claude in an ongoing dialogue rather
than written entirely by hand.

If you contribute, you are welcome to use AI assistance in the same spirit — just make sure the
code you submit is correct, tested, and follows the conventions below.

## Architecture Rules

Read `AI_INSTRUCTIONS.md` for the full architecture reference. The short version:

- **Layer order**: `widget → controller → data`. Widgets never touch repositories directly.
- **`lib/` structure**: `main.dart` + `src/common/` + `src/feature/`. Do not restructure this.
- **One feature per folder** inside `src/feature/`. Each feature contains `controller/`, `data/`,
  `model/`, and `widget/` sub-folders.
- **State management**: use `StateController` + `freezed` for business logic, `ChangeNotifier`
  for UI-only state inside `widget/controllers/`. No Provider, Riverpod, MobX, GetX, or BLoC.
- **Repositories**: always define an abstract interface (`IXxxRepository`) and a concrete `impl`.

## Code Generation

Any change to a `@freezed` class or other annotated code requires regenerating files:

```bash
dart run build_runner build && dart format lib/
```

Never manually edit `*.freezed.dart` or `*.g.dart` files.

## Pull Requests

1. Fork the repo and create a branch from `main`.
2. Keep changes focused — one concern per PR.
3. Run the app and verify your change works before opening a PR.
4. Describe what you changed and why in the PR description.

## Reporting Issues

Open a GitHub issue with a clear description of the bug or feature request, including steps to
reproduce if applicable.
