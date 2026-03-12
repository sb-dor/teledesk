import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:teledesk/src/common/database/tables/bot_settings_table.dart';
import 'package:teledesk/src/common/database/tables/conversations_table.dart';
import 'package:teledesk/src/common/database/tables/log_table.dart';
import 'package:teledesk/src/common/database/tables/messages_table.dart';
import 'package:teledesk/src/common/database/tables/quick_replies_table.dart';
import 'package:teledesk/src/common/database/tables/workers_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    LogTbl,
    LogPrefixTbl,
    WorkersTbl,
    ConversationsTbl,
    MessagesTbl,
    QuickRepliesTbl,
    BotSettingsTbl,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults({required String name})
    : super(
        driftDatabase(
          name: name,
          native: const DriftNativeOptions(shareAcrossIsolates: true),
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(workersTbl);
        await m.createTable(conversationsTbl);
        await m.createTable(messagesTbl);
        await m.createTable(quickRepliesTbl);
        await m.createTable(botSettingsTbl);
      }
    },
  );
}
