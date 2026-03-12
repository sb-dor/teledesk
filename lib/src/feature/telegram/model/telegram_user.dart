import 'package:flutter/foundation.dart';

@immutable
class TelegramUser {
  const TelegramUser({
    required this.id,
    required this.isBot,
    required this.firstName,
    this.lastName,
    this.username,
  });

  factory TelegramUser.fromJson(Map<String, dynamic> json) => TelegramUser(
    id: json['id'] as int,
    isBot: json['is_bot'] as bool? ?? false,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String?,
    username: json['username'] as String?,
  );

  final int id;
  final bool isBot;
  final String firstName;
  final String? lastName;
  final String? username;

  String get displayName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'User #$id';
  }
}
