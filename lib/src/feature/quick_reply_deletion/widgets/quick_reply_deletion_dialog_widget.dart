import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/controller/quick_reply_deletion_controller.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/widgets/quick_reply_deletion_config_widget.dart';

class QuickReplyDeletionDialogWidget extends StatefulWidget {
  const QuickReplyDeletionDialogWidget({super.key});

  @override
  State<QuickReplyDeletionDialogWidget> createState() => _QuickReplyDeletionDialogWidgetState();
}

class _QuickReplyDeletionDialogWidgetState extends State<QuickReplyDeletionDialogWidget> {
  late final _inhWidget = QuickReplyDeletionConfigInhWidget.of(context);
  late final _controller = _inhWidget.quickReplyDeletionController;
  late final _onSuccessfullyDelete = _inhWidget.onSuccessfullyDelete;
  late final _reply = _inhWidget.reply;

  @override
  Widget build(BuildContext context) {
    return StateConsumer<QuickReplyDeletionController, QuickReplyDeletionState>(
      controller: _controller,
      listener: (context, controller, oldState, newState) {
        if (newState is QuickReplyDeletion$CompletedState) {
          Navigator.pop(context);
          _onSuccessfullyDelete?.call();
        }
      },
      builder: (context, state, child) {
        return PopScope(
          canPop: state is! QuickReplyDeletion$InProgressState,
          child: AlertDialog(
            title: const Text('Delete Quick Reply'),
            content: Text('Delete "#${_reply.title}"? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: state is QuickReplyDeletion$InProgressState
                    ? null
                    : () => _controller.delete(_reply.id),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }
}
