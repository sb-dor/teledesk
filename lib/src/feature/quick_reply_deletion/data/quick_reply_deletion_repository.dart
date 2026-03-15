import 'package:teledesk/src/common/database/database.dart';

abstract interface class IQuickReplyDeletionRepository {
  Future<void> delete(int id);
}

final class QuickReplyDeletionRepositoryImpl implements IQuickReplyDeletionRepository {
  QuickReplyDeletionRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.quickRepliesTbl)..where((t) => t.id.equals(id))).go();
  }
}
