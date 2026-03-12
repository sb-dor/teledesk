---
name: project_teledesk
description: TeleDesk - Telegram bot admin panel. Architecture, stack, feature status, and key decisions.
type: project
---

# TeleDesk Project

## Overview
Open-source Telegram bot admin panel for managing customer support chats. Admins/workers reply to Telegram users via a bot on behalf of the team. Built in Flutter (mobile/desktop/tablet responsive).

## Run command
```
flutter run --dart-define-from-file=config/app_config.json
```

## Package name
`teledesk` (renamed from `flutter_project`)

## Tech Stack
- Flutter + Material 3 (light-first, dark/light switchable)
- Drift (SQLite) for local DB — backend-ready interfaces
- `http` package for Telegram Bot API (direct calls, no extra telegram package API used)
- `control` package for StateController
- `freezed` for sealed states
- `octopus` for routing
- `file_picker`, `image_picker` for media sending
- `crypto` for password hashing (SHA-256)

## Database Tables
workers, conversations, messages, quick_replies, bot_settings (+ existing log tables)
Schema version: 2

## Key Architectural Decisions
- Workers have roles: admin (full access) or worker (own chats + open queue)
- Chat lifecycle: open → inProgress (locked to worker) → finished
- User can only finish conversation after admin/worker calls allowUserToFinish()
- Long-polling loop starts on login, stops on logout (TelegramPollingController)
- Auto-logout on app pause/detach (WidgetsBindingObserver in App widget)
- First launch: forced admin setup flow (needsSetup state)
- Config secrets: config/app_config.json (gitignored), loaded via --dart-define-from-file
- Internal notes: amber-colored messages visible only to workers

## Feature Status (as of March 2026)
✅ DB schema + Drift tables
✅ Worker auth (login, first-admin setup, auto-logout)
✅ Telegram long-polling engine
✅ Conversation repository (streams → reactive UI)
✅ Dashboard screen with stats
✅ Chats screen (desktop two-column, mobile single-column)
✅ Conversation screen (messages, send text/media/files, notes, transfer, finish)
✅ Bot settings screen (commands, welcome message, auto-reply)
✅ Workers management screen (add, change password, deactivate)
✅ Settings screen (theme toggle, profile, admin section)
✅ MainNavigation shell (rail on desktop/tablet, bottom nav on mobile)
✅ Quick replies (# shortcut in message input)
✅ Internal notes (amber bubbles, lock icon)
✅ Chat transfer between workers
✅ Light/Dark theme with SharedPreferences persistence

## Planned / Stubbed
- Working hours (stub for future)
- Broadcast messages (admin only)
- Desktop notifications (flutter_local_notifications added but not wired)
- Search across conversations (repository method exists, UI TBD)
- Backend export (all repos use interfaces — swap impl for REST)

## Routes
signin, signup, dashboard, chats, conversation (id arg), bot-settings, workers, settings, developer

## Key Files
- `config/app_config.json` — bot token + polling config (gitignored)
- `lib/src/common/constant/config.dart` — Config.telegramBotToken, pollingTimeoutSeconds
- `lib/src/feature/telegram/data/telegram_repository.dart` — all Bot API calls
- `lib/src/feature/telegram/controller/telegram_polling_controller.dart` — polling loop
- `lib/src/feature/initialization/data/initialize_dependencies.dart` — DI setup
- `lib/src/feature/settings/widget/settings_scope.dart` — theme management
- `lib/src/common/widget/main_navigation.dart` — responsive nav shell
