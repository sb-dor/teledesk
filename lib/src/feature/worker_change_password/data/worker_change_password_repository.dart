import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/util/crypto_util.dart';

abstract interface class IWorkerChangePasswordRepository {
  Future<bool> updatePassword(int workerId, String newPassword);
}

final class WorkerChangePasswordRepositoryImpl implements IWorkerChangePasswordRepository {
  WorkerChangePasswordRepositoryImpl({
    required final AppDatabase database,
    required final CryptoUtil cryptoUtil,
  }) : _db = database,
       _cryptoUtil = cryptoUtil;

  final AppDatabase _db;
  final CryptoUtil _cryptoUtil;

  @override
  Future<bool> updatePassword(int workerId, String newPassword) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.workersTbl)..where((t) => t.id.equals(workerId))).write(
      WorkersTblCompanion(
        passwordHash: Value(_cryptoUtil.hashPassword(newPassword)),
        updatedAt: Value(now),
      ),
    );
    return true;
  }
}
