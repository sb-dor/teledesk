import 'package:flutter/material.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/common/widget/main_navigation.dart';
import 'package:teledesk/src/feature/chats/widget/chats_config_widget.dart';

/// {@template chats_screen}
/// ChatsScreen widget.
/// {@endtemplate}
class ChatsScreen extends StatelessWidget {
  /// {@macro chats_screen}
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) => MainNavigation(
        currentRoute: Routes.chats,
        child: const ChatsConfigWidget(),
      );
}
