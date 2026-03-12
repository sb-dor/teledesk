import 'dart:async';

import 'package:control/control.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:l/l.dart';
import 'package:platform_info/platform_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teledesk/src/common/constant/config.dart';
import 'package:teledesk/src/common/constant/pubspec.yaml.g.dart';
import 'package:teledesk/src/common/controller/controller_observer.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/database/tables/log_table.dart';
import 'package:teledesk/src/common/model/app_metadata.dart';
import 'package:teledesk/src/common/util/crypto_util.dart';
import 'package:teledesk/src/common/util/log_buffer.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
import 'package:teledesk/src/feature/authentication/controller/authentication_controller.dart';
import 'package:teledesk/src/feature/authentication/data/authentication_repository.dart';
import 'package:teledesk/src/feature/bot_settings/data/bot_settings_repository.dart';
import 'package:teledesk/src/feature/chats/data/conversation_repository.dart';
import 'package:teledesk/src/feature/initialization/data/platform/platform_initialization.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/message/data/message_repository.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/telegram/controller/telegram_polling_controller.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

/// Initializes the app and returns a [Dependencies] object
Future<Dependencies> $initializeDependencies({
  void Function(int progress, String message)? onProgress,
}) async {
  final dependencies = Dependencies();
  final totalSteps = _initializationSteps.length;
  var currentStep = 0;
  for (final step in _initializationSteps.entries) {
    try {
      currentStep++;
      final percent = (currentStep * 100 ~/ totalSteps).clamp(0, 100);
      onProgress?.call(percent, step.key);
      l.v6('Initialization | $currentStep/$totalSteps ($percent%) | "${step.key}"');
      await step.value(dependencies);
    } on Object catch (error, stackTrace) {
      l.e('Initialization failed at step "${step.key}": $error', stackTrace);
      Error.throwWithStackTrace('Initialization failed at step "${step.key}": $error', stackTrace);
    }
  }
  return dependencies;
}

typedef _InitializationStep = FutureOr<void> Function(Dependencies dependencies);

final Map<String, _InitializationStep> _initializationSteps = <String, _InitializationStep>{
  'Platform pre-initialization': (_) => $platformInitialization(),
  'Creating app metadata': (dependencies) => dependencies.metadata = AppMetadata(
    isWeb: platform.js,
    isRelease: platform.buildMode.release,
    appName: Pubspec.name,
    appVersion: Pubspec.version.representation,
    appVersionMajor: Pubspec.version.major,
    appVersionMinor: Pubspec.version.minor,
    appVersionPatch: Pubspec.version.patch,
    appBuildTimestamp: Pubspec.version.build.isNotEmpty
        ? (int.tryParse(Pubspec.version.build.firstOrNull ?? '-1') ?? -1)
        : -1,
    operatingSystem: platform.operatingSystem.name,
    processorsCount: platform.numberOfProcessors,
    appLaunchedTimestamp: DateTime.now(),
    locale: platform.locale,
    deviceVersion: platform.version,
    deviceScreenSize: ScreenUtil.screenSize().representation,
  ),
  'Observer state management': (_) => Controller.observer = const ControllerObserver(),
  'Initialize shared preferences': (dependencies) async =>
      dependencies.sharedPreferences = await SharedPreferences.getInstance(),
  'Connect to database': (dependencies) => dependencies.database = Config.inMemoryDatabase
      ? AppDatabase.defaults(name: 'memory')
      : AppDatabase.defaults(name: 'teledesk_db'),
  'Initialize Telegram repository': (dependencies) =>
      dependencies.telegramRepository = TelegramRepositoryImpl(botToken: Config.telegramBotToken),
  'Initialize Worker repository': (dependencies) => dependencies.workerRepository =
      WorkerRepositoryImpl(database: dependencies.database, cryptoUtil: CryptoUtil()),
  'Initialize Conversation repository': (dependencies) => dependencies.conversationRepository =
      ConversationRepositoryImpl(database: dependencies.database),
  'Initialize Message repository': (dependencies) =>
      dependencies.messageRepository = MessageRepositoryImpl(database: dependencies.database),
  'Initialize QuickReply repository': (dependencies) =>
      dependencies.quickReplyRepository = QuickReplyRepositoryImpl(database: dependencies.database),
  'Initialize BotSettings repository': (dependencies) =>
      dependencies.botSettingsRepository = BotSettingsRepositoryImpl(
        database: dependencies.database,
        telegramRepository: dependencies.telegramRepository,
      ),
  'Initialize Telegram polling controller': (dependencies) =>
      dependencies.telegramPollingController = TelegramPollingController(
        telegramRepository: dependencies.telegramRepository,
        conversationRepository: dependencies.conversationRepository,
        messageRepository: dependencies.messageRepository,
        pollingTimeoutSeconds: Config.pollingTimeoutSeconds,
      ),
  'Prepare authentication controller': (dependencies) =>
      dependencies.authenticationController = AuthenticationController(
        workerRepository: dependencies.workerRepository,
        authenticationRepository: AuthenticationRepositoryImpl(
          appDatabase: dependencies.database,
          cryptoUtil: CryptoUtil(),
        ),
      ),

  // The 'Shrink database' step will only be included in non-release builds.
  if (!kReleaseMode)
    'Shrink database': (dependencies) async {
      await dependencies.database.customStatement('VACUUM;');
      await dependencies.database.transaction(() async {
        final log =
            await (dependencies.database.select<LogTbl, Log>(dependencies.database.logTbl)
                  ..orderBy([
                    (tbl) => drift.OrderingTerm(expression: tbl.id, mode: drift.OrderingMode.desc),
                  ])
                  ..limit(1, offset: 1000))
                .getSingleOrNull();
        if (log != null) {
          await (dependencies.database.delete(
            dependencies.database.logTbl,
          )..where((tbl) => tbl.time.isSmallerOrEqualValue(log.time))).go();
        }
      });
    },

  if (!kReleaseMode)
    'Collect logs': (dependencies) async {
      await (dependencies.database.select<LogTbl, Log>(dependencies.database.logTbl)
            ..orderBy([
              (tbl) => drift.OrderingTerm(
                expression: tbl.time as drift.Expression<Object>,
                mode: drift.OrderingMode.desc,
              ),
            ])
            ..limit(LogBuffer.bufferLimit))
          .get()
          .then<List<LogMessage>>(
            (logs) => logs
                .map<LogMessage>(
                  (l) => l.stack != null
                      ? LogMessageError(
                          timestamp: DateTime.fromMillisecondsSinceEpoch(l.time * 1000),
                          level: LogLevel.fromValue(l.level),
                          message: l.message,
                          stackTrace: StackTrace.fromString(l.stack!),
                        )
                      : LogMessageVerbose(
                          timestamp: DateTime.fromMillisecondsSinceEpoch(l.time * 1000),
                          level: LogLevel.fromValue(l.level),
                          message: l.message,
                        ),
                )
                .toList(growable: false),
          )
          .then<void>(LogBuffer.instance.addAll);
      l
          .bufferTime(const Duration(seconds: 1))
          .where((logs) => logs.isNotEmpty)
          .listen(LogBuffer.instance.addAll, cancelOnError: false);
      l
          .map<LogTblCompanion>(
            (log) => LogTblCompanion.insert(
              level: log.level.level,
              message: log.message.toString(),
              time: drift.Value<int>(log.timestamp.millisecondsSinceEpoch ~/ 1000),
              stack: drift.Value<String?>(switch (log) {
                LogMessageError l => l.stackTrace.toString(),
                _ => null,
              }),
            ),
          )
          .bufferTime(const Duration(seconds: 5))
          .where((logs) => logs.isNotEmpty)
          .listen(
            (logs) => dependencies.database
                .batch((batch) => batch.insertAll(dependencies.database.logTbl, logs))
                .ignore(),
            cancelOnError: false,
          );
    },
};
