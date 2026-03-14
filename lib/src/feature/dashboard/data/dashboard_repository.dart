import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';

abstract interface class IDashboardRepository {
  Future<Map<String, int>> getDashboardStats();

  Stream<Map<String, int>> watchDashboardStats();
}

final class DashboardRepositoryImpl implements IDashboardRepository {
  DashboardRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Stream<Map<String, int>> watchDashboardStats() {
    final todayStart =
        DateTime.now()
            .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
            .millisecondsSinceEpoch ~/
        1000;
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM conversations WHERE status = ?) AS open_count, '
          '(SELECT COUNT(*) FROM conversations WHERE status = ?) AS in_progress_count, '
          '(SELECT COUNT(*) FROM conversations WHERE status = ? AND updated_at >= ?) AS finished_today, '
          '(SELECT COUNT(*) FROM messages) AS total_messages',
          variables: [
            const Variable<String>('open'),
            const Variable<String>('in_progress'),
            const Variable<String>('finished'),
            Variable<int>(todayStart),
          ],
          readsFrom: {_db.conversationsTbl, _db.messagesTbl},
        )
        .watch()
        .map(
          (rows) => rows.isEmpty
              ? {'open': 0, 'inProgress': 0, 'finishedToday': 0, 'totalMessages': 0}
              : {
                  'open': rows.first.read<int>('open_count'),
                  'inProgress': rows.first.read<int>('in_progress_count'),
                  'finishedToday': rows.first.read<int>('finished_today'),
                  'totalMessages': rows.first.read<int>('total_messages'),
                },
        );
  }

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
