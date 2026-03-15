import 'package:flutter/material.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
import 'package:teledesk/src/common/widget/main_navigation.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/chats/controller/chats_controller.dart';
import 'package:teledesk/src/feature/chats/data/chats_repository.dart';
import 'package:teledesk/src/feature/chats/widget/controllers/chats_data_controller.dart';
import 'package:teledesk/src/feature/chats/widget/desktop/chats_desktop_widget.dart';
import 'package:teledesk/src/feature/chats/widget/mobile/chats_mobile_widget.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';

class ChatsInhWidget extends InheritedWidget {
  const ChatsInhWidget({super.key, required this.state, required super.child});

  final ChatsConfigWidgetState state;

  static ChatsConfigWidgetState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<ChatsInhWidget>()?.widget;
    assert(widget != null, 'ChatsInhWidget not found');
    return (widget as ChatsInhWidget).state;
  }

  @override
  bool updateShouldNotify(ChatsInhWidget old) => false;
}

class ChatsConfigWidget extends StatefulWidget {
  const ChatsConfigWidget({super.key});

  @override
  State<ChatsConfigWidget> createState() => ChatsConfigWidgetState();
}

class ChatsConfigWidgetState extends State<ChatsConfigWidget> {
  late ChatsController chatsController;
  late ChatsDataController chatsDataController;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    final worker = AuthenticationScope.identityOf(context, listen: false);
    chatsController = ChatsController(
      repository: ChatsRepositoryImpl(database: dependencies.database),
      workerId: worker?.id ?? 0,
    )..initialize();
    chatsDataController = ChatsDataController();
  }

  @override
  void dispose() {
    chatsController.dispose();
    chatsDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainNavigation(
    currentRoute: Routes.chats,
    child: ChatsInhWidget(
      state: this,
      child: context.screenSizeMaybeWhen(
        orElse: () => const ChatsDesktopWidget(),
        phone: () => const ChatsMobileWidget(),
      ),
    ),
  );
}
