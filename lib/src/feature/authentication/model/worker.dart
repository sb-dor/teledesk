import 'package:flutter/foundation.dart';

enum WorkerRole { admin, worker }

enum WorkerStatus { online, away, busy, offline }

@immutable
class Worker {
  const Worker({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.colorCode,
    required this.status,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String displayName;
  final WorkerRole role;
  final String colorCode;
  final WorkerStatus status;
  final bool isActive;
  final DateTime createdAt;

  bool get isAdmin => role == WorkerRole.admin;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  Worker copyWith({
    int? id,
    String? username,
    String? displayName,
    WorkerRole? role,
    String? colorCode,
    WorkerStatus? status,
    bool? isActive,
    DateTime? createdAt,
  }) => Worker(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    colorCode: colorCode ?? this.colorCode,
    status: status ?? this.status,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}
