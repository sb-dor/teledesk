import 'package:flutter/foundation.dart';

@immutable
class BotCommand {
  const BotCommand({required this.command, required this.description});

  final String command;
  final String description;

  BotCommand copyWith({String? command, String? description}) =>
      BotCommand(command: command ?? this.command, description: description ?? this.description);
}
