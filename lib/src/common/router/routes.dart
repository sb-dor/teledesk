import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/feature/authentication/widget/signin_screen.dart';
import 'package:teledesk/src/feature/authentication/widget/signup_screen.dart';
import 'package:teledesk/src/feature/bot_settings/widget/bot_settings_screen.dart';
import 'package:teledesk/src/feature/chats/widget/chats_config_widget.dart';
import 'package:teledesk/src/feature/conversation/widget/conversation_screen.dart';
import 'package:teledesk/src/feature/dashboard/widget/dashboard_screen.dart';
import 'package:teledesk/src/feature/developer/widget/developer_screen.dart';
import 'package:teledesk/src/feature/settings/widget/settings_screen.dart';
import 'package:teledesk/src/feature/workers/widget/workers_screen.dart';

enum Routes with OctopusRoute {
  signin('signin', title: 'Sign In'),
  signup('signup', title: 'Sign Up'),
  dashboard('dashboard', title: 'Dashboard'),
  chats('chats', title: 'Chats'),
  conversation('conversation', title: 'Conversation'),
  botSettings('bot-settings', title: 'Bot Settings'),
  workers('workers', title: 'Workers'),
  settings('settings', title: 'Settings'),
  developer('developer', title: 'Developer');

  const Routes(this.name, {this.title});

  @override
  final String name;

  @override
  final String? title;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) => switch (this) {
    Routes.signin => const SignInScreen(),
    Routes.signup => const SignUpScreen(),
    Routes.dashboard => const DashboardScreen(),
    Routes.chats => const ChatsConfigWidget(),
    Routes.conversation => ConversationScreen(
      conversationId: int.tryParse(node.arguments['id'] ?? '') ?? 0,
    ),
    Routes.botSettings => const BotSettingsScreen(),
    Routes.workers => const WorkersScreen(),
    Routes.settings => const SettingsScreen(),
    Routes.developer => const DeveloperScreen(),
  };
}
