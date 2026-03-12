import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/bot_settings/controller/bot_settings_controller.dart';
import 'package:teledesk/src/feature/bot_settings/model/bot_command.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';

/// {@template bot_settings_screen}
/// BotSettingsScreen widget.
/// {@endtemplate}
class BotSettingsScreen extends StatefulWidget {
  /// {@macro bot_settings_screen}
  const BotSettingsScreen({super.key});

  @override
  State<BotSettingsScreen> createState() => _BotSettingsScreenState();
}

class _BotSettingsScreenState extends State<BotSettingsScreen> {
  late final BotSettingsController _controller;
  final TextEditingController _welcomeCtrl = TextEditingController();
  final TextEditingController _autoReplyCtrl = TextEditingController();
  bool _welcomeEdited = false;
  bool _autoReplyEdited = false;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    _controller = BotSettingsController(repository: deps.botSettingsRepository)
      ..load();
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    final state = _controller.state;
    if (state is BotSettings$IdleState) {
      if (!_welcomeEdited && state.welcomeMessage != null) {
        _welcomeCtrl.text = state.welcomeMessage!;
      }
      if (!_autoReplyEdited && state.autoReply != null) {
        _autoReplyCtrl.text = state.autoReply!;
      }
      if (mounted) setState(() {});
    } else if (state is BotSettings$SavedState) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }
      _controller.load();
    } else {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _welcomeCtrl.dispose();
    _autoReplyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = _controller.state;
    final isLoading = state is BotSettings$LoadingState;
    final isSaving = state is BotSettings$SavingState;

    List<BotCommand> commands = [];
    String? botUsername;
    if (state is BotSettings$IdleState) {
      commands = state.commands;
      botUsername = state.botUsername;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Settings'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Bot info
                if (botUsername != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.smart_toy_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected Bot',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@$botUsername',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Commands section
                _SectionHeader(
                  title: 'Bot Commands',
                  subtitle: 'Commands visible to users in Telegram',
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ...commands.asMap().entries.map(
                            (entry) => _CommandTile(
                              command: entry.value,
                              onEdit: () => _showCommandDialog(
                                context,
                                command: entry.value,
                                onSave: (updated) {
                                  final newList = [...commands];
                                  newList[entry.key] = updated;
                                  _controller.saveCommands(newList);
                                },
                              ),
                              onDelete: () {
                                final newList = [...commands]
                                  ..removeAt(entry.key);
                                _controller.saveCommands(newList);
                              },
                            ),
                          ),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: const Text('Add Command'),
                        onTap: () => _showCommandDialog(
                          context,
                          onSave: (newCmd) {
                            _controller.saveCommands([...commands, newCmd]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Welcome message
                _SectionHeader(
                  title: 'Welcome Message',
                  subtitle: 'Sent when a user starts a conversation',
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _welcomeCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Enter welcome message shown to users...',
                            label: Text('Welcome Message'),
                          ),
                          onChanged: (_) => _welcomeEdited = true,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () => _controller
                                    .saveWelcomeMessage(_welcomeCtrl.text),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-reply message
                _SectionHeader(
                  title: 'Auto-Reply Message',
                  subtitle: 'Sent automatically when all workers are busy',
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _autoReplyCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Enter auto-reply message for busy times...',
                            label: Text('Auto-Reply Message'),
                          ),
                          onChanged: (_) => _autoReplyEdited = true,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () => _controller
                                    .saveAutoReply(_autoReplyCtrl.text),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Error display
                if (state is BotSettings$ErrorState)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.message,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _showCommandDialog(
    BuildContext context, {
    BotCommand? command,
    required void Function(BotCommand) onSave,
  }) {
    final cmdCtrl = TextEditingController(text: command?.command ?? '');
    final descCtrl = TextEditingController(text: command?.description ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(command == null ? 'Add Command' : 'Edit Command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cmdCtrl,
              decoration: const InputDecoration(
                labelText: 'Command (without /)',
                hintText: 'start',
                prefixText: '/',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Start the bot',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (cmdCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              onSave(BotCommand(
                command: cmdCtrl.text.trim().toLowerCase(),
                description: descCtrl.text.trim(),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.command,
    required this.onEdit,
    required this.onDelete,
  });

  final BotCommand command;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '/${command.command}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        command.description.isEmpty ? '(no description)' : command.description,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: theme.colorScheme.error,
            ),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
