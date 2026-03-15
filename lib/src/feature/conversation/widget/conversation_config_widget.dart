import 'package:flutter/material.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/conversation/controller/conversation_controller.dart';
import 'package:teledesk/src/feature/conversation/data/conversation_repository.dart';
import 'package:teledesk/src/feature/conversation/widget/controllers/conversation_data_controller.dart';
import 'package:teledesk/src/feature/conversation/widget/desktop/conversation_desktop_widget.dart';
import 'package:teledesk/src/feature/conversation/widget/mobile/conversation_mobile_widget.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/quick_replies/controller/quick_replies_controller.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/workers/controller/workers_controller.dart';
import 'package:teledesk/src/feature/workers/data/worker_repository.dart';

class ConversationInhWidget extends InheritedWidget {
  const ConversationInhWidget({super.key, required this.state, required super.child});

  final ConversationConfigWidgetState state;

  static ConversationConfigWidgetState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<ConversationInhWidget>()?.widget;
    assert(widget != null, 'ConversationInhWidget not found');
    return (widget as ConversationInhWidget).state;
  }

  @override
  bool updateShouldNotify(ConversationInhWidget old) => false;
}

class ConversationConfigWidget extends StatefulWidget {
  const ConversationConfigWidget({super.key, required this.conversationId});

  final int conversationId;

  @override
  State<ConversationConfigWidget> createState() => ConversationConfigWidgetState();
}

class ConversationConfigWidgetState extends State<ConversationConfigWidget> {
  late final ConversationController conversationController;
  late final ConversationDataController conversationDataController;
  late final QuickRepliesController quickRepliesController;
  late final WorkersController workersController;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    final identity = AuthenticationScope.identityOf(context, listen: false);
    workersController = WorkersController(
      repository: WorkerRepositoryImpl(database: dependencies.database),
    )..load();
    quickRepliesController = QuickRepliesController(
      repository: QuickReplyRepositoryImpl(database: dependencies.database),
    )..load();
    conversationController = ConversationController(
      repository: ConversationRepositoryImpl(database: dependencies.database),
      telegram: dependencies.telegramRepository,
      conversationId: widget.conversationId,
      currentWorkerId: identity?.id ?? 0,
    )..initialize();
    conversationDataController = ConversationDataController();
  }

  @override
  void dispose() {
    conversationController.dispose();
    conversationDataController.dispose();
    quickRepliesController.dispose();
    workersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConversationInhWidget(
    state: this,
    child: context.screenSizeMaybeWhen(
      orElse: () => const ConversationDesktopWidget(),
      phone: () => const ConversationMobileWidget(),
    ),
  );
}
