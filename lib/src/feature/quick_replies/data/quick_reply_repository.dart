import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

abstract interface class IQuickReplyRepository {
  Future<List<QuickReply>> getAll();
}

final class QuickReplyRepositoryImpl implements IQuickReplyRepository {
  QuickReplyRepositoryImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  QuickReply _rowToQuickReply(QuickRepliesTblData row) => QuickReply(
    id: row.id,
    title: row.title,
    content: row.content,
    createdByWorkerId: row.createdByWorkerId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000),
  );

  @override
  Future<List<QuickReply>> getAll() =>
      (_db.select(_db.quickRepliesTbl)..orderBy([(t) => OrderingTerm.asc(t.title)])).get().then(
        (rows) => rows.map(_rowToQuickReply).toList(),
      );
}
