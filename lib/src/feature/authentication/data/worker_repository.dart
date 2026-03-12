import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/util/crypto_util.dart';
import 'package:teledesk/src/feature/authentication/model/worker.dart';

abstract interface class IWorkerRepository {
  Future<List<Worker>> getWorkers();

  Future<Worker?> findByUsername(String username);

  Future<Worker?> authenticate(String username, String password);

  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required WorkerRole role,
    required String colorCode,
  });

  Future<void> updateWorker(Worker worker);

  Future<void> updatePassword(int workerId, String newPassword);

  Future<void> deactivateWorker(int workerId);

  Future<int> countWorkers();

  Future<void> updateStatus(int workerId, WorkerStatus status);
}

final class WorkerRepositoryImpl implements IWorkerRepository {
  WorkerRepositoryImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Worker _rowToWorker(WorkersTblData row) => Worker(
    id: row.id,
    username: row.username,
    displayName: row.displayName,
    role: row.role == 'admin' ? WorkerRole.admin : WorkerRole.worker,
    colorCode: row.colorCode,
    status: switch (row.status) {
      'online' => WorkerStatus.online,
      'away' => WorkerStatus.away,
      'busy' => WorkerStatus.busy,
      _ => WorkerStatus.offline,
    },
    isActive: row.isActive,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000),
  );

  @override
  Future<List<Worker>> getWorkers() async {
    final rows = await (_db.select(_db.workersTbl)..where((t) => t.isActive.equals(true))).get();
    return rows.map(_rowToWorker).toList();
  }

  @override
  Future<Worker?> findByUsername(String username) async {
    final row =
        await (_db.select(_db.workersTbl)
              ..where((t) => t.username.equals(username))
              ..where((t) => t.isActive.equals(true)))
            .getSingleOrNull();
    if (row == null) return null;
    return _rowToWorker(row);
  }

  @override
  Future<Worker?> authenticate(String username, String password) async {
    final row =
        await (_db.select(_db.workersTbl)
              ..where((t) => t.username.equals(username))
              ..where((t) => t.isActive.equals(true)))
            .getSingleOrNull();
    if (row == null) return null;
    if (!CryptoUtil.verifyPassword(password, row.passwordHash)) return null;
    return _rowToWorker(row);
  }

  @override
  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required WorkerRole role,
    required String colorCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.workersTbl)
        .insert(
          WorkersTblCompanion.insert(
            username: username,
            passwordHash: CryptoUtil.hashPassword(password),
            displayName: displayName,
            role: Value(role == WorkerRole.admin ? 'admin' : 'worker'),
            colorCode: Value(colorCode),
            status: const Value('offline'),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return Worker(
      id: id,
      username: username,
      displayName: displayName,
      role: role,
      colorCode: colorCode,
      status: WorkerStatus.offline,
      isActive: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  @override
  Future<void> updateWorker(Worker worker) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(worker.id))).write(
      WorkersTblCompanion(
        displayName: Value(worker.displayName),
        role: Value(worker.role == WorkerRole.admin ? 'admin' : 'worker'),
        colorCode: Value(worker.colorCode),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> updatePassword(int workerId, String newPassword) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(
        passwordHash: Value(CryptoUtil.hashPassword(newPassword)),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deactivateWorker(int workerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(isActive: const Value(false), updatedAt: Value(now)),
    );
  }

  @override
  Future<int> countWorkers() async {
    final count = await _db.workersTbl.count().getSingle();
    return count;
  }

  @override
  Future<void> updateStatus(int workerId, WorkerStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final statusStr = switch (status) {
      WorkerStatus.online => 'online',
      WorkerStatus.away => 'away',
      WorkerStatus.busy => 'busy',
      WorkerStatus.offline => 'offline',
    };
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(status: Value(statusStr), updatedAt: Value(now)),
    );
  }
}

final class FakeWorderRepoImpl implements IWorkerRepository {
  @override
  Future<Worker?> authenticate(String username, String password) => Future.value(null);

  @override
  Future<int> countWorkers() => Future.value(1);

  @override
  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required WorkerRole role,
    required String colorCode,
  }) => Future.value(
    Worker(
      id: 1,
      username: username,
      displayName: displayName,
      role: role,
      colorCode: colorCode,
      status: WorkerStatus.away,
      isActive: false,
      createdAt: DateTime.now(),
    ),
  );

  @override
  Future<void> deactivateWorker(int workerId) => Future.value();

  @override
  Future<Worker?> findByUsername(String username) => Future.value(null);

  @override
  Future<List<Worker>> getWorkers() => Future.value(List.empty());

  @override
  Future<void> updatePassword(int workerId, String newPassword) => Future.value(null);

  @override
  Future<void> updateStatus(int workerId, WorkerStatus status) => Future.value(null);

  @override
  Future<void> updateWorker(Worker worker) => Future.value(null);
}
