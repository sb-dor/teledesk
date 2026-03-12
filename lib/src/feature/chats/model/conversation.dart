import 'package:flutter/foundation.dart';

enum ConversationStatus { open, inProgress, finishRequested, finished }

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.telegramUserId,
    this.telegramUsername,
    this.firstName,
    this.lastName,
    required this.status,
    this.assignedWorkerId,
    required this.canUserFinish,
    required this.unreadCount,
    required this.lastMessageAt,
    this.lastMessagePreview,
    required this.createdAt,
  });

  final int id;
  final int telegramUserId;
  final String? telegramUsername;
  final String? firstName;
  final String? lastName;
  final ConversationStatus status;
  final int? assignedWorkerId;
  final bool canUserFinish;
  final int unreadCount;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final DateTime createdAt;

  String get displayName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    if (telegramUsername != null) return '@$telegramUsername';
    return 'User #$telegramUserId';
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (name.startsWith('@')) return name.substring(1, 2).toUpperCase();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get hasUnread => unreadCount > 0;

  Conversation copyWith({
    int? id,
    int? telegramUserId,
    ValueGetter<String?>? telegramUsername,
    ValueGetter<String?>? firstName,
    ValueGetter<String?>? lastName,
    ConversationStatus? status,
    ValueGetter<int?>? assignedWorkerId,
    bool? canUserFinish,
    int? unreadCount,
    DateTime? lastMessageAt,
    ValueGetter<String?>? lastMessagePreview,
    DateTime? createdAt,
  }) => Conversation(
    id: id ?? this.id,
    telegramUserId: telegramUserId ?? this.telegramUserId,
    telegramUsername: telegramUsername != null ? telegramUsername() : this.telegramUsername,
    firstName: firstName != null ? firstName() : this.firstName,
    lastName: lastName != null ? lastName() : this.lastName,
    status: status ?? this.status,
    assignedWorkerId: assignedWorkerId != null ? assignedWorkerId() : this.assignedWorkerId,
    canUserFinish: canUserFinish ?? this.canUserFinish,
    unreadCount: unreadCount ?? this.unreadCount,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastMessagePreview: lastMessagePreview != null ? lastMessagePreview() : this.lastMessagePreview,
    createdAt: createdAt ?? this.createdAt,
  );
}
