import 'dart:async';

import 'package:flutter/material.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/conversation/controller/conversation_controller.dart';
import 'package:teledesk/src/feature/conversation/widget/controllers/conversation_data_controller.dart';
import 'package:teledesk/src/feature/conversation/widget/desktop/conversation_desktop_widget.dart';
import 'package:teledesk/src/feature/conversation/widget/mobile/conversation_mobile_widget.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

class ConversationInhWidget extends InheritedWidget {
  const ConversationInhWidget({
    super.key,
    required this.state,
    required super.child,
  });

  final ConversationConfigWidgetState state;

  static ConversationConfigWidgetState of(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<ConversationInhWidget>()
        ?.widget;
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
  State<ConversationConfigWidget> createState() =>
      ConversationConfigWidgetState();
}

class ConversationConfigWidgetState extends State<ConversationConfigWidget> {
  late final ConversationController conversationController;
  late final ConversationDataController conversationDataController;
  late final IQuickReplyRepository quickReplyRepository;
  List<QuickReply> quickReplies = [];
  StreamSubscription<List<QuickReply>>? _quickRepliesSub;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    quickReplyRepository = deps.quickReplyRepository;
    conversationDataController = ConversationDataController();
    conversationController = ConversationController(
      repository: deps.conversationRepository,
      telegram: deps.telegramRepository,
      conversationId: widget.conversationId,
      currentWorkerId: AuthenticationScope.workerOf(context)?.id ?? 0,
    )..initialize();

    // Load quick replies
    _quickRepliesSub = quickReplyRepository.watchAll().listen((replies) {
      if (mounted) {
        setState(() => quickReplies = replies);
      }
    });
  }

  @override
  void dispose() {
    _quickRepliesSub?.cancel();
    conversationController.dispose();
    conversationDataController.dispose();
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
