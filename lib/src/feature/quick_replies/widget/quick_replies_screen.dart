import 'package:flutter/material.dart';
import 'package:teledesk/src/common/widget/scaffold_padding.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/quick_replies/controller/quick_replies_controller.dart';
import 'package:teledesk/src/feature/quick_replies/data/quick_reply_repository.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

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

  void _showDialog({final QuickReply? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    final identity = AuthenticationScope.identityOf(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Quick Reply' : 'Edit Quick Reply'),
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
                onChanged: (_) => setDialogState(() {}),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Hello! How can I help you today?',
                ),
                onChanged: (_) => setDialogState(() {}),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      if (existing == null) {
                        _controller.create(
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          workerId: identity?.id ?? 0,
                        );
                      } else {
                        _controller.update(
                          existing.copyWith(
                            title: titleCtrl.text.trim(),
                            content: contentCtrl.text.trim(),
                          ),
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(QuickReply reply) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quick Reply'),
        content: Text('Delete "#${reply.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.delete(reply.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        onPressed: _showDialog,
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
                        onPressed: () => _showDialog(existing: reply),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(reply),
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
