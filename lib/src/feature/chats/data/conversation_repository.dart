import 'package:drift/drift.dart';
import 'package:teledesk/src/common/database/database.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';

abstract interface class IConversationRepository {
  Stream<List<Conversation>> watchConversations();
  Stream<List<Conversation>> watchOpenConversations();
  Stream<List<Conversation>> watchWorkerConversations(int workerId);
  Future<Conversation?> findByTelegramUserId(int telegramUserId);
  Future<Conversation> createOrGetConversation({
    required int telegramUserId,
    String? username,
    String? firstName,
    String? lastName,
  });
  Future<void> assignConversation(int conversationId, int workerId);
  Future<void> transferConversation(int conversationId, int newWorkerId);
  Future<void> allowUserToFinish(int conversationId);
  Future<void> finishConversation(int conversationId);
  Future<Map<String, int>> getDashboardStats();
  Future<List<Conversation>> searchConversations(String query);
}

final class ConversationRepositoryImpl implements IConversationRepository {
  ConversationRepositoryImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Conversation _rowToConversation(ConversationsTblData row) => Conversation(
    id: row.id,
    telegramUserId: row.telegramUserId,
    telegramUsername: row.telegramUsername,
    firstName: row.firstName,
    lastName: row.lastName,
    status: switch (row.status) {
      'in_progress' => ConversationStatus.inProgress,
      'finish_requested' => ConversationStatus.finishRequested,
      'finished' => ConversationStatus.finished,
      _ => ConversationStatus.open,
    },
    assignedWorkerId: row.assignedWorkerId,
    canUserFinish: row.canUserFinish,
    unreadCount: row.unreadCount,
    lastMessageAt: DateTime.fromMillisecondsSinceEpoch(row.lastMessageAt * 1000),
    lastMessagePreview: row.lastMessagePreview,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000),
  );

  @override
  Stream<List<Conversation>> watchConversations() =>
      (_db.select(_db.conversationsTbl)
            ..where((t) => t.status.isNotValue('finished'))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch()
          .map((rows) => rows.map(_rowToConversation).toList());

  @override
  Stream<List<Conversation>> watchOpenConversations() =>
      (_db.select(_db.conversationsTbl)
            ..where((t) => t.status.equals('open'))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch()
          .map((rows) => rows.map(_rowToConversation).toList());

  @override
  Stream<List<Conversation>> watchWorkerConversations(int workerId) =>
      (_db.select(_db.conversationsTbl)
            ..where((t) => t.assignedWorkerId.equals(workerId))
            ..where((t) => t.status.isNotValue('finished'))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch()
          .map((rows) => rows.map(_rowToConversation).toList());

  @override
  Future<Conversation?> findByTelegramUserId(int telegramUserId) async {
    final row = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.telegramUserId.equals(telegramUserId))).getSingleOrNull();
    if (row == null) return null;
    return _rowToConversation(row);
  }

  @override
  Future<Conversation> createOrGetConversation({
    required int telegramUserId,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    final existing = await findByTelegramUserId(telegramUserId);
    if (existing != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (existing.status == ConversationStatus.finished) {
        // User wrote back after conversation was closed — re-open it
        await (_db.update(
          _db.conversationsTbl,
        )..where((t) => t.telegramUserId.equals(telegramUserId))).write(
          ConversationsTblCompanion(
            telegramUsername: Value(username),
            firstName: Value(firstName),
            lastName: Value(lastName),
            status: const Value('open'),
            assignedWorkerId: const Value(null),
            canUserFinish: const Value(false),
            unreadCount: const Value(1),
            updatedAt: Value(now),
          ),
        );
        return existing.copyWith(
          status: ConversationStatus.open,
          assignedWorkerId: () => null,
          canUserFinish: false,
          unreadCount: 1,
        );
      }
      await (_db.update(
        _db.conversationsTbl,
      )..where((t) => t.telegramUserId.equals(telegramUserId))).write(
        ConversationsTblCompanion(
          telegramUsername: Value(username),
          firstName: Value(firstName),
          lastName: Value(lastName),
          updatedAt: Value(now),
        ),
      );
      return existing;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = await _db
        .into(_db.conversationsTbl)
        .insert(
          ConversationsTblCompanion.insert(
            telegramUserId: telegramUserId,
            telegramUsername: Value(username),
            firstName: Value(firstName),
            lastName: Value(lastName),
            status: const Value('open'),
            assignedWorkerId: const Value(null),
            canUserFinish: const Value(false),
            unreadCount: const Value(1),
            lastMessageAt: now,
            lastMessagePreview: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return Conversation(
      id: id,
      telegramUserId: telegramUserId,
      telegramUsername: username,
      firstName: firstName,
      lastName: lastName,
      status: ConversationStatus.open,
      assignedWorkerId: null,
      canUserFinish: false,
      unreadCount: 1,
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      lastMessagePreview: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  @override
  Future<void> assignConversation(int conversationId, int workerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(
        status: const Value('in_progress'),
        assignedWorkerId: Value(workerId),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> transferConversation(int conversationId, int newWorkerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(assignedWorkerId: Value(newWorkerId), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> allowUserToFinish(int conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(canUserFinish: const Value(true), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> finishConversation(int conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (_db.update(_db.conversationsTbl)..where((t) => t.id.equals(conversationId))).write(
      ConversationsTblCompanion(status: const Value('finished'), updatedAt: Value(now)),
    );
  }

  @override
  Future<Map<String, int>> getDashboardStats() async {
    final open = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.status.equals('open'))).get();
    final inProgress = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.status.equals('in_progress'))).get();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/ 1000;
    final finished =
        await (_db.select(_db.conversationsTbl)
              ..where((t) => t.status.equals('finished'))
              ..where((t) => t.updatedAt.isBiggerOrEqualValue(todayStart)))
            .get();
    final totalMessages = await _db.messagesTbl.count().getSingle();
    return {
      'open': open.length,
      'inProgress': inProgress.length,
      'finishedToday': finished.length,
      'totalMessages': totalMessages,
    };
  }

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final q = '%$query%';
    final rows = await (_db.select(
      _db.conversationsTbl,
    )..where((t) => t.firstName.like(q) | t.lastName.like(q) | t.telegramUsername.like(q))).get();
    return rows.map(_rowToConversation).toList();
  }
}
