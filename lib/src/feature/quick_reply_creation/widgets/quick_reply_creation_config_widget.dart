import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/initialization/widget/dependencies_scope.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';
import 'package:teledesk/src/feature/quick_reply_creation/controller/quick_reply_creation_controller.dart';
import 'package:teledesk/src/feature/quick_reply_creation/data/quick_reply_creation_repository.dart';
import 'package:teledesk/src/feature/quick_reply_creation/widgets/quick_reply_creation_dialog_widget.dart';

class QuickReplyCreationConfigInhWidget extends InheritedWidget {
  const QuickReplyCreationConfigInhWidget({super.key, required this.state, required super.child});

  static QuickReplyCreationConfigWidgetState of(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<QuickReplyCreationConfigInhWidget>()
        ?.widget;
    assert(widget != null, 'No QuickReplyCreationConfigInhWidget found in context');
    return (widget as QuickReplyCreationConfigInhWidget).state;
  }

  final QuickReplyCreationConfigWidgetState state;

  @override
  bool updateShouldNotify(QuickReplyCreationConfigInhWidget old) {
    return false;
  }
}

class QuickReplyCreationConfigWidget extends StatefulWidget {
  const QuickReplyCreationConfigWidget({super.key, required this.builder});

  static Future<void> showCreationDialog(BuildContext context, {QuickReply? existing}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => QuickReplyCreationConfigWidget(
        builder: (_) => QuickReplyCreationDialogWidget(existing: existing),
      ),
    );
  }

  final WidgetBuilder builder;

  @override
  State<QuickReplyCreationConfigWidget> createState() => QuickReplyCreationConfigWidgetState();
}

class QuickReplyCreationConfigWidgetState extends State<QuickReplyCreationConfigWidget> {
  late final QuickReplyCreationController quickReplyCreationController;

  @override
  void initState() {
    super.initState();
    final dependencies = DependenciesScope.of(context);
    quickReplyCreationController = QuickReplyCreationController(
      iQuickReplyCreationRepository: QuickReplyCreationRepositoryImpl(
        database: dependencies.database,
      ),
    );
  }

  @override
  void dispose() {
    quickReplyCreationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuickReplyCreationConfigInhWidget(state: this, child: widget.builder(context));
  }
}
