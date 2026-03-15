import 'package:flutter/material.dart';
import 'package:teledesk/src/common/widget/scaffold_padding.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/quick_replies/controller/quick_replies_controller.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';
import 'package:teledesk/src/feature/quick_reply_creation/widgets/quick_reply_creation_config_widget.dart';
import 'package:teledesk/src/feature/quick_reply_creation/widgets/quick_reply_creation_dialog_widget.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/widgets/quick_reply_deletion_config_widget.dart';
import 'package:teledesk/src/feature/quick_reply_deletion/widgets/quick_reply_deletion_dialog_widget.dart';

class QuickRepliesScreen extends StatefulWidget {
  const QuickRepliesScreen({super.key});

  @override
  State<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends State<QuickRepliesScreen> {
  late final QuickRepliesController _controller;

  @override
  void initState() {
    super.initState();
    final db = Dependencies.of(context).database;
    _controller = QuickRepliesController(repository: QuickReplyRepositoryImpl(database: db))
      ..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Replies'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickReplyCreationConfigWidget.showCreationDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reply'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;

          if (state is QuickReplies$LoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuickReplies$ErrorState) {
            return Center(
              child: Text(state.message, style: TextStyle(color: colorScheme.error)),
            );
          }

          final replies = state.replies;

          if (replies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quickreply_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quick replies yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add Reply" to create your first one.\nType # in a chat to use them.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: ScaffoldPadding.of(context),
            itemCount: replies.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final reply = replies[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${reply.title}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    reply.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: () => QuickReplyCreationConfigWidget.showCreationDialog(
                          context,
                          existing: reply,
                        ),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        onPressed: () =>
                            QuickReplyDeletionConfigWidget.showDeletionDialog(context, reply),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
