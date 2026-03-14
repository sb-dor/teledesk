import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';

abstract interface class IDashboardRepository {
  Future<Map<String, int>> getDashboardStats();
}

final class DashboardRepositoryImpl implements IDashboardRepository {
  DashboardRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Future<Map<String, int>> getDashboardStats() async {
    final open = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.status.equals('open'))).get();
    final inProgress = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.status.equals('in_progress'))).get();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/ 1000;
    final finished =
        await (_db.select(_db.conversationsTbl)
              ..where((t) => t.status.equals('finished'))
              ..where((t) => t.updatedAt.isBiggerOrEqualValue(todayStart)))
            .get();
    final totalMessages = await _db.messagesTbl.count().getSingle();
    return {
      'open': open.length,
      'inProgress': inProgress.length,
      'finishedToday': finished.length,
      'totalMessages': totalMessages,
    };
  }
}
