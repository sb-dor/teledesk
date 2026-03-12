import 'dart:async';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/common/util/crypto_util.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';

abstract interface class IAuthenticationRepository {
  Future<Identity?> authenticate(String username, String password);
}

class AuthenticationRepositoryImpl implements IAuthenticationRepository {
  AuthenticationRepositoryImpl({
    required final AppDatabase appDatabase,
    required final CryptoUtil cryptoUtil,
  }) : _appDatabase = appDatabase,
       _cryptoUtil = cryptoUtil;

  final AppDatabase _appDatabase;
  final CryptoUtil _cryptoUtil;

  @override
  Future<Identity?> authenticate(String username, String password) async {
    final row =
        await (_appDatabase.select(_appDatabase.workersTbl)
              ..where((t) => t.username.equals(username))
              ..where((t) => t.isActive.equals(true)))
            .getSingleOrNull();
    if (row == null) return null;

    if (!_cryptoUtil.verifyPassword(password, row.passwordHash)) return null;

    final status = switch (row.status) {
      'online' => IdentityStatus.online,
      'away' => IdentityStatus.away,
      'busy' => IdentityStatus.busy,
      _ => IdentityStatus.offline,
    };
    final createdAt = DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000);

    if (row.role == 'admin') {
      return Admin(
        id: row.id,
        username: row.username,
        displayName: row.displayName,
        colorCode: row.colorCode,
        status: status,
        createdAt: createdAt,
      );
    }

    return Worker(
      id: row.id,
      username: row.username,
      displayName: row.displayName,
      colorCode: row.colorCode,
      status: status,
      createdAt: createdAt,
    );
  }
}

class AuthenticationRepositoryFake implements IAuthenticationRepository {
  @override
  Future<Identity?> authenticate(String username, String password) => Future.value();
}
