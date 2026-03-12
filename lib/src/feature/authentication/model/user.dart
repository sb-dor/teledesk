import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({required this.id, this.name, this.email});

  factory User.fromMap(Map<String, Object?> map) =>
      User(id: map['id'] as int, name: map['name'] as String, email: map['email'] as String);

  factory User.defaultUser() =>
      const User(id: -2142, name: 'Riley Vaughan', email: 'riley.vaughan@testc12.com');

  final int id;
  final String? name;
  final String? email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;

  @override
  String toString() => 'User{id: $id, name: $name, email: $email}';

  User copyWith({int? id, String? name, String? email}) =>
      User(id: id ?? this.id, name: name ?? this.name, email: email ?? this.email);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email};
}
