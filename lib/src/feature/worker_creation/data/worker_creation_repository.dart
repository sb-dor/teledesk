import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/util/crypto_util.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';

abstract interface class IWorkerCreationRepository {
  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required IdentityRole role,
    required String colorCode,
  });
}

final class WorkerCreationRepositoryImpl implements IWorkerCreationRepository {
  WorkerCreationRepositoryImpl({
    required final AppDatabase database,
    required final CryptoUtil cryptoUtil,
  }) : _db = database,
       _cryptoUtil = cryptoUtil;

  final AppDatabase _db;
  final CryptoUtil _cryptoUtil;

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
      colorCode: colorCode,
      status: IdentityStatus.offline,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }
}

final class FakeWorkerCreationRepositoryImpl implements IWorkerCreationRepository {
  @override
  Future<Worker> createWorker({
    required String username,
    required String password,
    required String displayName,
    required IdentityRole role,
    required String colorCode,
  }) => Future.value(Worker(id: 1, username: username));
}
