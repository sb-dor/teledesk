import 'package:flutter/foundation.dart';

enum IdentityRole { admin, worker }

enum IdentityStatus { online, away, busy, offline }

@immutable
sealed class Identity {
  const Identity();

  int get id;

  String get username;

  String? get displayName;

  String? get colorCode;

  IdentityStatus? get status;

  DateTime? get createdAt;

  IdentityRole get identityRole;

  String get initials {
    final name = displayName ?? username;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class Admin extends Identity {
  const Admin({
    required this.id,
    required this.username,
    this.displayName,
    this.colorCode,
    this.status,
    this.createdAt,
  });

  @override
  final int id;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final String? colorCode;
  @override
  final IdentityStatus? status;
  @override
  final DateTime? createdAt;

  @override
  IdentityRole get identityRole => IdentityRole.admin;

  Admin copyWith({
    int? id,
    String? username,
    ValueGetter<String?>? displayName,
    ValueGetter<String?>? colorCode,
    ValueGetter<IdentityStatus?>? status,
    ValueGetter<DateTime?>? createdAt,
  }) => Admin(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName != null ? displayName() : this.displayName,
    colorCode: colorCode != null ? colorCode() : this.colorCode,
    status: status != null ? status() : this.status,
    createdAt: createdAt != null ? createdAt() : this.createdAt,
  );
}

class Worker extends Identity {
  const Worker({
    required this.id,
    required this.username,
    this.displayName,
    this.colorCode,
    this.status,
    this.createdAt,
  });

  @override
  final int id;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final String? colorCode;
  @override
  final IdentityStatus? status;
  @override
  final DateTime? createdAt;

  @override
  IdentityRole get identityRole => IdentityRole.admin;

  Worker copyWith({
    int? id,
    String? username,
    ValueGetter<String?>? displayName,
    ValueGetter<String?>? colorCode,
    ValueGetter<IdentityStatus?>? status,
    ValueGetter<DateTime?>? createdAt,
  }) => Worker(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName != null ? displayName() : this.displayName,
    colorCode: colorCode != null ? colorCode() : this.colorCode,
    status: status != null ? status() : this.status,
    createdAt: createdAt != null ? createdAt() : this.createdAt,
  );
}
