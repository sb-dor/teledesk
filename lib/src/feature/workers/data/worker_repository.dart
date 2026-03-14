import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';

abstract interface class IWorkerRepository {
  Future<List<Worker>> getWorkers();

  Future<int> countWorkers();
}

final class WorkerRepositoryImpl implements IWorkerRepository {
  WorkerRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Worker _rowToWorker(WorkersTblData row) => Worker(
    id: row.id,
    username: row.username,
    displayName: row.displayName,
    colorCode: row.colorCode,
    status: switch (row.status) {
      'online' => IdentityStatus.online,
      'away' => IdentityStatus.away,
      'busy' => IdentityStatus.busy,
      _ => IdentityStatus.offline,
    },
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000),
  );

  @override
  Future<List<Worker>> getWorkers() async {
    final rows = await (_db.select(_db.workersTbl)..where((t) => t.isActive.equals(true))).get();
    return rows.map(_rowToWorker).toList();
  }

  @override
  Future<int> countWorkers() async {
    final count = await _db.workersTbl.count().getSingle();
    return count;
  }
}

final class FakeWorderRepoImpl implements IWorkerRepository {
  @override
  Future<int> countWorkers() => Future.value(1);

  @override
  Future<List<Worker>> getWorkers() => Future.value(List.empty());
}
