import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/bot_settings/model/bot_command.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';

abstract interface class IBotSettingsRepository {
  Future<List<BotCommand>> getCommands();

  Future<void> setCommands(List<BotCommand> commands);

  Future<String?> getSetting(String key);

  Future<void> saveSetting(String key, String value);

  Future<Map<String, dynamic>> getBotInfo();

  Future<void> setDescription(String description);

  Future<void> setShortDescription(String shortDescription);

  Future<void> setWelcomeMessage(String message);

  Future<String?> getWelcomeMessage();

  Future<void> setAutoReplyMessage(String message);

  Future<String?> getAutoReplyMessage();

  Future<String?> getStoredBotToken();

  Future<Map<String, dynamic>> saveBotToken(String token);
}

final class BotSettingsRepositoryImpl implements IBotSettingsRepository {
  BotSettingsRepositoryImpl({
    required AppDatabase database,
    required ITelegramRepository telegramRepository,
  }) : _db = database,
       _telegram = telegramRepository;

  final AppDatabase _db;
  final ITelegramRepository _telegram;

  @override
  Future<List<BotCommand>> getCommands() async {
    try {
      final commands = await _telegram.getMyCommands();
      return commands;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> setCommands(List<BotCommand> commands) async {
    await _telegram.setMyCommands(commands: commands);
  }

  @override
  Future<String?> getSetting(String key) async {
    final row = await (_db.select(
      _db.botSettingsTbl,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db
        .into(_db.botSettingsTbl)
        .insertOnConflictUpdate(
          BotSettingsTblCompanion.insert(key: key, value: value, updatedAt: now),
        );
  }

  @override
  Future<Map<String, dynamic>> getBotInfo() async {
    return _telegram.getMe();
  }

  @override
  Future<void> setDescription(String description) async {
    await _telegram.setMyDescription(description: description);
    await saveSetting('description', description);
  }

  @override
  Future<void> setShortDescription(String shortDescription) async {
    await _telegram.setMyShortDescription(shortDescription: shortDescription);
    await saveSetting('short_description', shortDescription);
  }

  @override
  Future<void> setWelcomeMessage(String message) async {
    await saveSetting('welcome_message', message);
  }

  @override
  Future<String?> getWelcomeMessage() => getSetting('welcome_message');

  @override
  Future<void> setAutoReplyMessage(String message) async {
    await saveSetting('auto_reply', message);
  }

  @override
  Future<String?> getAutoReplyMessage() => getSetting('auto_reply');

  @override
  Future<String?> getStoredBotToken() => getSetting('bot_token');

  @override
  Future<Map<String, dynamic>> saveBotToken(String token) async {
    // Validate by calling getMe before saving
    _telegram.updateToken(token);
    final info = await _telegram.getMe(); // throws if invalid
    await saveSetting('bot_token', token);
    return info;
  }
}
