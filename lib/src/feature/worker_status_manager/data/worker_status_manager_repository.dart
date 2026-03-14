import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';

abstract interface class IWorkerStatusManagerRepository {
  Future<bool> updateStatus(int workerId, IdentityStatus status);
}

final class WorkerStatusManagerRepositoryImpl implements IWorkerStatusManagerRepository {
  WorkerStatusManagerRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Future<bool> updateStatus(int workerId, IdentityStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final statusStr = switch (status) {
      IdentityStatus.online => 'online',
      IdentityStatus.away => 'away',
      IdentityStatus.busy => 'busy',
      IdentityStatus.offline => 'offline',
    };
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(status: Value(statusStr), updatedAt: Value(now)),
    );
    return true;
  }
}

final class FakeWorkerStatusManagerRepository implements IWorkerStatusManagerRepository {
  @override
  Future<bool> updateStatus(int workerId, IdentityStatus status) => Future.value(true);
}
