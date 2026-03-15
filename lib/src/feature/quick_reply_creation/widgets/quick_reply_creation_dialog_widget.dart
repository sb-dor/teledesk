import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';
import 'package:teledesk/src/feature/quick_reply_creation/controller/quick_reply_creation_controller.dart';
import 'package:teledesk/src/feature/quick_reply_creation/widgets/quick_reply_creation_config_widget.dart';

class QuickReplyCreationDialogWidget extends StatefulWidget {
  const QuickReplyCreationDialogWidget({super.key, this.existing});

  final QuickReply? existing;

  @override
  State<QuickReplyCreationDialogWidget> createState() => _QuickReplyCreationDialogWidgetState();
}

class _QuickReplyCreationDialogWidgetState extends State<QuickReplyCreationDialogWidget> {
  late final _inhWidget = QuickReplyCreationConfigInhWidget.of(context);
  late final _quickReplyCreationController = _inhWidget.quickReplyCreationController;
  late final _identity = AuthenticationScope.identityOf(context, listen: false);

  late final titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final contentCtrl = TextEditingController(text: widget.existing?.content ?? '');

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return StateConsumer<QuickReplyCreationController, QuickReplyCreationState>(
      controller: _quickReplyCreationController,
      listener: (context, controller, oldState, newState) {
        if (newState is QuickReplyCreation$CompletedState) {
          Navigator.pop(context);
        }
      },
      builder: (context, state, child) {
        return PopScope(
          canPop: state is! QuickReplyCreation$InProgressState,
          child: AlertDialog(
            title: Text(isEdit ? 'Edit Quick Reply' : 'Add Quick Reply'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shortcut',
                    hintText: 'greeting',
                    prefixText: '# ',
                    helperText: 'Type # + shortcut in chat to use',
                  ),
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Hello! How can I help you today?',
                  ),
                  onChanged: (_) => setState(() {}),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty
                    ? null
                    : () {
                        _quickReplyCreationController.save(
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          workerId: _identity?.id,
                          existing: widget.existing,
                        );
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
