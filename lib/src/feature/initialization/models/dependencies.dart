import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/model/app_metadata.dart';
import 'package:teledesk/src/feature/authentication/controller/authentication_controller.dart';
import 'package:teledesk/src/feature/bot_settings/data/bot_settings_repository.dart';
import 'package:teledesk/src/feature/chats/data/conversation_repository.dart';
import 'package:teledesk/src/feature/initialization/widget/dependencies_scope.dart';
import 'package:teledesk/src/feature/message/data/message_repository.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/telegram/controller/telegram_polling_controller.dart';
import 'package:teledesk/src/feature/telegram/data/telegram_repository.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

/// {@template dependencies}
/// Application dependencies.
/// {@endtemplate}
class Dependencies {
  /// {@macro dependencies}
  Dependencies();

  /// The state from the closest instance of this class.
  ///
  /// {@macro dependencies}
  factory Dependencies.of(BuildContext context) => DependenciesScope.of(context);

  /// Inject dependencies to the widget tree.
  Widget inject({required Widget child, Key? key}) =>
      DependenciesScope(dependencies: this, key: key, child: child);

  /// App metadata
  late final AppMetadata metadata;

  /// Shared preferences
  late final SharedPreferences sharedPreferences;

  /// Database
  late final AppDatabase database;

  /// Telegram repository
  late final ITelegramRepository telegramRepository;

  /// Worker repository
  late final IWorkerRepository workerRepository;

  /// Conversation repository
  late final IConversationRepository conversationRepository;

  /// Message repository
  late final IMessageRepository messageRepository;

  /// Quick reply repository
  late final IQuickReplyRepository quickReplyRepository;

  /// Bot settings repository
  late final IBotSettingsRepository botSettingsRepository;

  /// Authentication controller
  late final AuthenticationController authenticationController;

  /// Telegram polling controller
  late final TelegramPollingController telegramPollingController;

  @override
  String toString() => 'Dependencies{}';
}

/// Fake Dependencies
@visibleForTesting
class FakeDependencies extends Dependencies {
  FakeDependencies();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
