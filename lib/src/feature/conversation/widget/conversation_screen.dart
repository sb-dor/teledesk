import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/conversation/widget/conversation_config_widget.dart';

/// {@template conversation_screen}
/// ConversationScreen widget.
/// {@endtemplate}
class ConversationScreen extends StatelessWidget {
  /// {@macro conversation_screen}
  const ConversationScreen({required this.conversationId, super.key});

  final int conversationId;

  @override
  Widget build(BuildContext context) => ConversationConfigWidget(conversationId: conversationId);
}
