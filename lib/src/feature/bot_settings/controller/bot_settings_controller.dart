import 'package:control/control.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teledesk/src/feature/bot_settings/data/bot_settings_repository.dart';
import 'package:teledesk/src/feature/bot_settings/model/bot_command.dart';
import 'package:teledesk/src/feature/telegram/controller/telegram_polling_controller.dart';

part 'bot_settings_controller.freezed.dart';

@freezed
sealed class BotSettingsState with _$BotSettingsState {
  const factory BotSettingsState.idle({
    @Default([]) List<BotCommand> commands,
    String? welcomeMessage,
    String? autoReply,
    String? description,
    String? botUsername,
  }) = BotSettings$IdleState;

  const factory BotSettingsState.loading() = BotSettings$LoadingState;

  const factory BotSettingsState.saving() = BotSettings$SavingState;

  const factory BotSettingsState.error(String message) = BotSettings$ErrorState;

  const factory BotSettingsState.saved() = BotSettings$SavedState;
}

final class BotSettingsController extends StateController<BotSettingsState>
    with SequentialControllerHandler {
  BotSettingsController({
    required IBotSettingsRepository repository,
    required TelegramPollingController pollingController,
  }) : _repository = repository,
       _pollingController = pollingController,
       super(initialState: const BotSettingsState.loading());

  final IBotSettingsRepository _repository;
  final TelegramPollingController _pollingController;

  void load() => handle(() async {
    setState(const BotSettingsState.loading());
    final commands = await _repository.getCommands();
    final welcomeMessage = await _repository.getWelcomeMessage();
    final autoReply = await _repository.getAutoReplyMessage();
    final description = await _repository.getSetting('description');
    Map<String, dynamic>? botInfo;
    try {
      botInfo = await _repository.getBotInfo();
    } catch (_) {}
    setState(
      BotSettingsState.idle(
        commands: commands,
        welcomeMessage: welcomeMessage,
        autoReply: autoReply,
        description: description,
        botUsername: botInfo?['username'] as String?,
      ),
    );
  }, error: (e, st) async => setState(BotSettingsState.error(e.toString())));

  void saveCommands(List<BotCommand> commands) => handle(() async {
    setState(const BotSettingsState.saving());
    await _repository.setCommands(commands);
    final current = state;
    if (current is BotSettings$IdleState) {
      setState(current.copyWith(commands: commands));
    }
    setState(const BotSettingsState.saved());
  }, error: (e, st) async => setState(BotSettingsState.error(e.toString())));

  void saveWelcomeMessage(String message) => handle(() async {
    setState(const BotSettingsState.saving());
    await _repository.setWelcomeMessage(message);
    setState(const BotSettingsState.saved());
  }, error: (e, st) async => setState(BotSettingsState.error(e.toString())));

  void saveAutoReply(String message) => handle(() async {
    setState(const BotSettingsState.saving());
    await _repository.setAutoReplyMessage(message);
    setState(const BotSettingsState.saved());
  }, error: (e, st) async => setState(BotSettingsState.error(e.toString())));

  void saveDescription(String desc, String shortDesc) => handle(() async {
    setState(const BotSettingsState.saving());
    await _repository.setDescription(desc);
    await _repository.setShortDescription(shortDesc);
    setState(const BotSettingsState.saved());
  }, error: (e, st) async => setState(BotSettingsState.error(e.toString())));

  void saveBotToken(String token) => handle(
    () async {
      setState(const BotSettingsState.saving());
      final info = await _repository.saveBotToken(token);
      setState(BotSettingsState.idle(botUsername: info['username'] as String?));
      _pollingController.startPolling();
      load();
    },
    error: (e, st) async {
      _pollingController.stopPolling();
      setState(BotSettingsState.error(e.toString()));
    },
  );
}
