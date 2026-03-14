import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';

abstract interface class IWorkerDeactivationRepository {
  Future<bool> deactivateWorker(int workerId);
}

final class WorkerDeactivationRepositoryImpl implements IWorkerDeactivationRepository {
  WorkerDeactivationRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Future<bool> deactivateWorker(int workerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(isActive: const Value(false), updatedAt: Value(now)),
    );
    return true;
  }
}
