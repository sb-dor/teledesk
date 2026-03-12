import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

abstract interface class IQuickReplyRepository {
  Stream<List<QuickReply>> watchAll();
  Future<QuickReply> create({required String title, required String content, int? workerId});
  Future<void> update(QuickReply reply);
  Future<void> delete(int id);
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
  Stream<List<QuickReply>> watchAll() =>
      (_db.select(_db.quickRepliesTbl)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch().map(
        (rows) => rows.map(_rowToQuickReply).toList(),
      );

  @override
  Future<QuickReply> create({required String title, required String content, int? workerId}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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

  @override
  Future<void> update(QuickReply reply) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.quickRepliesTbl)..where((t) => t.id.equals(reply.id))).write(
      QuickRepliesTblCompanion(
        title: Value(reply.title),
        content: Value(reply.content),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.quickRepliesTbl)..where((t) => t.id.equals(id))).go();
  }
}
