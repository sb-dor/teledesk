import 'package:flutter/foundation.dart';

@immutable
class QuickReply {
  const QuickReply({
    required this.id,
    required this.title,
    required this.content,
    this.createdByWorkerId,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String content;
  final int? createdByWorkerId;
  final DateTime createdAt;

  QuickReply copyWith({
    int? id,
    String? title,
    String? content,
    ValueGetter<int?>? createdByWorkerId,
    DateTime? createdAt,
  }) => QuickReply(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdByWorkerId: createdByWorkerId != null ? createdByWorkerId() : this.createdByWorkerId,
    createdAt: createdAt ?? this.createdAt,
  );
}
