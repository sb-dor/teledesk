import 'package:meta/meta.dart';

enum IdentityRole { admin, worker }

enum IdentityStatus { online, away, busy, offline }

@immutable
sealed class Identity {
  const Identity();

  int get id;

  String get fullName;

  IdentityRole get identityRole;
}

class Admin extends Identity {
  const Admin({
    required this.id,
    required this.username,
    required this.displayName,
    required this.colorCode,
    required this.status,
    required this.isActive,
    required this.createdAt,
  });

  @override
  final int id;
  final String username;
  final String displayName;
  final String colorCode;
  final IdentityStatus status;
  final bool isActive;
  final DateTime createdAt;

  @override
  String get fullName => username;

  @override
  IdentityRole get identityRole => IdentityRole.admin;
}

class Worker extends Identity {
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

  @override
  final int id;
  final String username;
  final String displayName;
  final IdentityRole role;
  final String colorCode;
  final IdentityStatus status;
  final bool isActive;
  final DateTime createdAt;

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
    IdentityRole? role,
    String? colorCode,
    IdentityStatus? status,
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

  @override
  String get fullName => username;

  @override
  IdentityRole get identityRole => IdentityRole.worker;
}
