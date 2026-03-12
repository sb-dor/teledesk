import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/util/crypto_util.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';

abstract interface class IWorkerRepository {
  Future<List<Worker>> getWorkers();

  Future<int> countWorkers();

  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required IdentityRole role,
    required String colorCode,
  });

  Future<void> updatePassword(int workerId, String newPassword);

  Future<void> deactivateWorker(int workerId);

  Future<void> updateStatus(int workerId, IdentityStatus status);
}

final class WorkerRepositoryImpl implements IWorkerRepository {
  WorkerRepositoryImpl({required final AppDatabase database, required final CryptoUtil cryptoUtil})
    : _db = database,
      _cryptoUtil = cryptoUtil;

  final AppDatabase _db;
  final CryptoUtil _cryptoUtil;

  Worker _rowToWorker(WorkersTblData row) => Worker(
    id: row.id,
    username: row.username,
    displayName: row.displayName,
    role: row.role == 'admin' ? IdentityRole.admin : IdentityRole.worker,
    colorCode: row.colorCode,
    status: switch (row.status) {
      'online' => IdentityStatus.online,
      'away' => IdentityStatus.away,
      'busy' => IdentityStatus.busy,
      _ => IdentityStatus.offline,
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
  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required IdentityRole role,
    required String colorCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.workersTbl)
        .insert(
          WorkersTblCompanion.insert(
            username: username,
            passwordHash: _cryptoUtil.hashPassword(password),
            displayName: displayName,
            role: Value(role == IdentityRole.admin ? 'admin' : 'worker'),
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
      status: IdentityStatus.offline,
      isActive: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  @override
  Future<void> updatePassword(int workerId, String newPassword) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(
        passwordHash: Value(_cryptoUtil.hashPassword(newPassword)),
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
  Future<void> updateStatus(int workerId, IdentityStatus status) async {
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
  }
}

final class FakeWorderRepoImpl implements IWorkerRepository {
  @override
  Future<int> countWorkers() => Future.value(1);

  @override
  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required IdentityRole role,
    required String colorCode,
  }) => Future.value(
    Worker(
      id: 1,
      username: username,
      displayName: displayName,
      role: role,
      colorCode: colorCode,
      status: IdentityStatus.away,
      isActive: false,
      createdAt: DateTime.now(),
    ),
  );

  @override
  Future<void> deactivateWorker(int workerId) => Future.value();

  @override
  Future<List<Worker>> getWorkers() => Future.value(List.empty());

  @override
  Future<void> updatePassword(int workerId, String newPassword) => Future.value(null);

  @override
  Future<void> updateStatus(int workerId, IdentityStatus status) => Future.value(null);
}
