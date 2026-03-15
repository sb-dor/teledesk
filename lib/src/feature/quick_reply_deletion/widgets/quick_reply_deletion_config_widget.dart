import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/initialization/widget/dependencies_scope.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/controller/quick_reply_deletion_controller.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/data/quick_reply_deletion_repository.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/widgets/quick_reply_deletion_dialog_widget.dart';

class QuickReplyDeletionConfigInhWidget extends InheritedWidget {
  const QuickReplyDeletionConfigInhWidget({super.key, required this.state, required super.child});

  static QuickReplyDeletionConfigWidgetState of(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<QuickReplyDeletionConfigInhWidget>()
        ?.widget;
    assert(widget != null, 'No QuickReplyDeletionConfigInhWidget found in context');
    return (widget as QuickReplyDeletionConfigInhWidget).state;
  }

  final QuickReplyDeletionConfigWidgetState state;

  @override
  bool updateShouldNotify(QuickReplyDeletionConfigInhWidget old) => false;
}

class QuickReplyDeletionConfigWidget extends StatefulWidget {
  const QuickReplyDeletionConfigWidget({
    super.key,
    required this.builder,
    required this.reply,
    this.onSuccessfullyDelete,
  });

  static Future<void> showDeletionDialog(
    BuildContext context,
    final QuickReply reply, {
    final void Function()? onSuccessfullyDelete,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => QuickReplyDeletionConfigWidget(
        onSuccessfullyDelete: onSuccessfullyDelete,
        reply: reply,
        builder: (_) => const QuickReplyDeletionDialogWidget(),
      ),
    );
  }

  final WidgetBuilder builder;
  final QuickReply reply;
  final void Function()? onSuccessfullyDelete;

  @override
  State<QuickReplyDeletionConfigWidget> createState() => QuickReplyDeletionConfigWidgetState();
}

class QuickReplyDeletionConfigWidgetState extends State<QuickReplyDeletionConfigWidget> {
  late final QuickReplyDeletionController quickReplyDeletionController;
  late final onSuccessfullyDelete = widget.onSuccessfullyDelete;
  late final reply = widget.reply;

  @override
  void initState() {
    super.initState();
    final dependencies = DependenciesScope.of(context);
    quickReplyDeletionController = QuickReplyDeletionController(
      iQuickReplyDeletionRepository: QuickReplyDeletionRepositoryImpl(
        database: dependencies.database,
      ),
    );
  }

  @override
  void dispose() {
    quickReplyDeletionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuickReplyDeletionConfigInhWidget(state: this, child: widget.builder(context));
  }
}
