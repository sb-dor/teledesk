# TeleDesk

A Flutter-based Telegram bot admin panel for managing customer support conversations. Built with
clean architecture, Drift (SQLite), and long-polling for real-time message handling.

## Vibe Coded

This project was built through vibe coding — iterative, conversation-driven development using
[Claude Code](https://claude.ai/claude-code) by Anthropic. Architecture decisions, bug fixes,
and feature implementations were developed collaboratively between the developer and Claude.

## Features

- Real-time incoming messages via Telegram long-polling
- Open queue and per-worker conversation management
- Internal notes, quick replies, and file/media sharing
- Bot token management with live connect/disconnect
- Dashboard with live stats (open chats, in progress, finished today, total messages)
- Multi-worker support with role-based access (Admin / Worker)
- Dark and light theme support

## Getting Started

### Prerequisites

- Flutter SDK
- A Telegram bot token from [@BotFather](https://t.me/BotFather)

### Running the app

**Production:**

```bash
flutter run --dart-define-from-file=config/production.json
```

**Development:**

```bash
flutter run --dart-define-from-file=config/development.json
```

### Config files

| Key                | Description                                        |
|--------------------|----------------------------------------------------|
| `ENVIRONMENT`      | `production` or `development`                      |
| `DATABASE_NAME`    | SQLite database file name                          |
| `MAX_LAYOUT_WIDTH` | Breakpoint (px) between mobile and desktop layouts |
| `ALPHA` / `BETA`   | Feature flags                                      |

Config files are located in `config/production.json` and `config/development.json`.

## Architecture

Clean architecture with strict layer separation:

```
lib/
├── main.dart
└── src/
    ├── common/       # shared database, router, utilities, widgets
    └── feature/      # one folder per feature
        └── <feature>/
            ├── controller/   # business logic & state (StateController + freezed)
            ├── data/         # repository interfaces & implementations (Drift)
            ├── model/        # immutable domain models
            └── widget/       # UI (config widget, desktop/mobile layouts, data controllers)
```

Dependency direction within a feature: `widget → controller → data`. Widgets never access
repositories directly.

## Code Generation

After adding or modifying Freezed classes or other annotated code, regenerate files with:

```bash
dart run build_runner build && dart format lib/
```