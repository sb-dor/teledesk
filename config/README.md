# Config

This folder contains environment-specific configuration.

## Setup

1. Copy `app_config.json` and fill in your values:
   - `TELEGRAM_BOT_TOKEN`: Your Telegram Bot API token from @BotFather

2. Run the app with:
   ```
   flutter run --dart-define-from-file=config/app_config.json
   ```

## Security
Never commit `app_config.json` to version control. Add it to .gitignore.
