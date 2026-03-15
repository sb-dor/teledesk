import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

abstract interface class IQuickReplyCreationRepository {
  Future<QuickReply> save({
    required String title,
    required String content,
    int? workerId,
    QuickReply? existing,
  });
}

final class QuickReplyCreationRepositoryImpl implements IQuickReplyCreationRepository {
  QuickReplyCreationRepositoryImpl({required final AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Future<QuickReply> save({
    required String title,
    required String content,
    int? workerId,
    QuickReply? existing,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (existing != null) {
      await (_db.update(_db.quickRepliesTbl)..where((t) => t.id.equals(existing.id))).write(
        QuickRepliesTblCompanion(
          title: Value(title),
          content: Value(content),
          updatedAt: Value(now),
        ),
      );
      return existing.copyWith(title: title, content: content);
    }

    final id = await _db
        .into(_db.quickRepliesTbl)
        .insert(
          QuickRepliesTblCompanion.insert(
            title: title,
            content: content,
            createdByWorkerId: Value(workerId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return QuickReply(
      id: id,
      title: title,
      content: content,
      createdByWorkerId: workerId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }
}
