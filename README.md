# TeleDesk

A modern, open-source Telegram bot admin panel built with Flutter. Manage customer support conversations across your team — on desktop, tablet, and mobile.

Users chat with your Telegram bot; your team replies from TeleDesk using the bot's identity.

---

## Features

- **Multi-worker support** — Admin and worker roles with separate logins
- **Chat queue** — Open conversations visible to all workers; claimed chats locked to the assigned worker
- **Rich messaging** — Send text, images, videos, GIFs, documents, audio, stickers, and any file type
- **Quick replies** — Type `#` to search saved reply templates
- **Internal notes** — Leave notes on conversations visible only to your team
- **Chat transfer** — Reassign any conversation to another worker
- **Bot configuration** — Set commands (`/start`, `/help`, custom), welcome message, auto-reply, and description — all from within the app
- **Dashboard** — Live stats: open chats, in-progress, finished today, total messages
- **Worker management** — Add, edit, deactivate workers; change passwords
- **Light / Dark theme** — Switchable from Settings
- **Responsive UI** — Desktop two-panel layout, tablet adapted, mobile push navigation
- **Auto-logout** — Signs out automatically when the app is closed or backgrounded
- **Backend-ready** — All data access is abstracted behind interfaces for easy backend swap

---

## Getting Started

### 1. Create a Telegram Bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy your bot token (looks like `123456:ABC-DEF...`)

### 2. Configure the App

Create a `config/app_config.json` file in the project root:

```json
{
  "TELEGRAM_BOT_TOKEN": "YOUR_BOT_TOKEN_HERE",
  "POLLING_TIMEOUT_SECONDS": 30,
  "POLLING_INTERVAL_MS": 500
}
```

> **Never commit this file.** It is already in `.gitignore`.

### 3. Run the App

```bash
flutter run --dart-define-from-file=config/app_config.json
```

### 4. First Launch

On first launch you will be prompted to create an admin account. This account is stored locally in the SQLite database.

---

## Project Structure

```
lib/
├── src/
│   ├── common/
│   │   ├── constant/       # Config, app constants
│   │   ├── database/       # Drift DB + all tables
│   │   ├── router/         # Octopus routes + guards
│   │   ├── util/           # Screen utils, crypto, extensions
│   │   └── widget/         # Shared widgets (MainNavigation, etc.)
│   └── feature/
│       ├── authentication/ # Worker login, auth scope
│       ├── bot_settings/   # Bot commands, welcome msg, auto-reply
│       ├── chats/          # Conversation list feature
│       ├── conversation/   # Single chat view + message input
│       ├── dashboard/      # Stats dashboard
│       ├── quick_replies/  # Saved reply templates
│       ├── settings/       # App settings + theme
│       ├── telegram/       # Bot API client + polling loop
│       └── workers/        # Worker management
config/
└── app_config.json         # Your secrets (gitignored)
```

---

## Architecture

- **State management:** [`control`](https://pub.dev/packages/control) — `StateController` with `freezed` sealed states
- **Database:** [`drift`](https://pub.dev/packages/drift) — SQLite with reactive streams; all repos use interfaces for backend portability
- **Routing:** [`octopus`](https://pub.dev/packages/octopus) — declarative routing with auth guards
- **Telegram:** Direct HTTP calls to the [Telegram Bot API](https://core.telegram.org/bots/api) using `http`; long-polling for real-time updates
- **Responsive:** `screenSizeMaybeWhen` for phone/tablet/desktop breakpoints
- **Dependency injection:** InheritedWidget pattern via `DependenciesScope`

---

## Chat Lifecycle

```
User sends message → Conversation created (status: open)
        ↓
Worker opens chat → Locked to that worker (status: inProgress)
        ↓
Worker replies via TeleDesk (messages sent through bot)
        ↓
Admin/worker clicks "Allow User to Finish" → User can type /cancel
        ─── OR ───
Admin/worker clicks "Finish Chat" → Conversation closed
```

---

## Bot Commands

Configure bot commands from **Settings → Bot Settings**. Default suggested commands:

| Command | Description |
|---|---|
| `/start` | Start a conversation with support |
| `/help` | Get help and information |
| `/status` | Check your conversation status |
| `/cancel` | Close the conversation (only if allowed by agent) |

---

## Exporting to a Backend

All data repositories implement interfaces (`IWorkerRepository`, `IConversationRepository`, etc.). To replace local SQLite with a REST backend:

1. Implement the interface with your HTTP client
2. Swap the implementation in `initialize_dependencies.dart`

No UI changes required.

---

## Contributing

This project is open-source. Contributions are welcome.

1. Fork the repository
2. Create your feature branch
3. Add your `config/app_config.json` with your own bot token
4. Open a pull request

---

## License

MIT
