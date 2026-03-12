import 'package:drift/drift.dart';

/// Bot settings table - key-value store for bot configuration cache
class BotSettingsTbl extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'bot_settings';
}
