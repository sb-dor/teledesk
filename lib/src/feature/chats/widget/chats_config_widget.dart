import 'package:flutter/material.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
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
  ChatsController? _chatsController;
  ChatsDataController? _chatsDataController;
  bool _initialized = false;

  ChatsController get chatsController => _chatsController!;

  ChatsDataController get chatsDataController => _chatsDataController!;

  @override
  void initState() {
    super.initState();
    _chatsDataController = ChatsDataController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final dependencies = Dependencies.of(context);
    final worker = AuthenticationScope.identityOf(context);
    _chatsController = ChatsController(
      repository: ChatsRepositoryImpl(database: dependencies.database),
      workerId: worker?.id ?? 0,
    )..initialize();
  }

  @override
  void dispose() {
    chatsController.dispose();
    chatsDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChatsInhWidget(
    state: this,
    child: context.screenSizeMaybeWhen(
      orElse: () => const ChatsDesktopWidget(),
      phone: () => const ChatsMobileWidget(),
    ),
  );
}
