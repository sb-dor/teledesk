import 'package:flutter/material.dart';
import 'package:teledesk/src/common/widget/scaffold_padding.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
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
  final TextEditingController _tokenCtrl = TextEditingController();
  final TextEditingController _welcomeCtrl = TextEditingController();
  final TextEditingController _autoReplyCtrl = TextEditingController();
  late final Dependencies _dependencies;
  bool _tokenVisible = false;
  bool _welcomeEdited = false;
  bool _autoReplyEdited = false;

  @override
  void initState() {
    super.initState();
    _dependencies = Dependencies.of(context);
    _controller = BotSettingsController(
      repository: _dependencies.botSettingsRepository,
      pollingController: _dependencies.telegramPollingController,
    )..load();
    _controller.addListener(_onStateChanged);
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    final token = await _dependencies.botSettingsRepository.getStoredBotToken();
    if (mounted && token != null) setState(() => _tokenCtrl.text = token);
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
          const SnackBar(content: Text('Saved successfully'), behavior: SnackBarBehavior.floating),
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
    _controller..removeListener(_onStateChanged)
    ..dispose();
    _tokenCtrl.dispose();
    _welcomeCtrl.dispose();
    _autoReplyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Admin-only screen
    final identity = AuthenticationScope.identityOf(context);
    if (identity?.identityRole != IdentityRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bot Settings'),
          leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Admin access required', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text(
                'Only administrators can manage bot settings.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = _controller.state;
    final isLoading = state is BotSettings$LoadingState;
    final isSaving = state is BotSettings$SavingState;

    var commands = <BotCommand>[];
    String? botUsername;
    if (state is BotSettings$IdleState) {
      commands = state.commands;
      botUsername = state.botUsername;
    }

    final tokenIsSet = botUsername != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Settings'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: ScaffoldPadding.of(context),
              children: [
                // ── Bot Token section (always first) ──────────────────────
                _SectionHeader(
                  title: 'Bot Token',
                  subtitle: tokenIsSet
                      ? 'Connected as @$botUsername'
                      : 'Enter your Telegram bot token to enable all features',
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (tokenIsSet)
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '@$botUsername',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Bot connected successfully',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        TextField(
                          controller: _tokenCtrl,
                          obscureText: !_tokenVisible,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '123456789:ABCdefGHIjklMNOpqrSTUvwxyz',
                            label: const Text('Bot Token'),
                            helperText: 'Get your token from @BotFather on Telegram',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _tokenVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.link_rounded, size: 18),
                            label: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Connect Bot'),
                            onPressed: isSaving || _tokenCtrl.text.trim().isEmpty
                                ? null
                                : () => _controller.saveBotToken(_tokenCtrl.text.trim()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Error banner ────────────────────────────────────────────
                if (state is BotSettings$ErrorState) ...[
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
                  const SizedBox(height: 16),
                ],

                // ── Gate: rest only available once token is set ────────────
                if (!tokenIsSet) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Connect your bot token above to access commands, messages, and other settings.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Commands section
                  const _SectionHeader(
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
                              final newList = [...commands]..removeAt(entry.key);
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
                            child: Icon(Icons.add_rounded, color: colorScheme.primary, size: 20),
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
                  const _SectionHeader(
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
                              hintText: 'Enter welcome message shown to users...',
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
                                  : () => _controller.saveWelcomeMessage(_welcomeCtrl.text),
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
                  const _SectionHeader(
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
                              hintText: 'Enter auto-reply message for busy times...',
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
                                  : () => _controller.saveAutoReply(_autoReplyCtrl.text),
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
                ],

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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (cmdCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              onSave(
                BotCommand(
                  command: cmdCtrl.text.trim().toLowerCase(),
                  description: descCtrl.text.trim(),
                ),
              );
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
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.command, required this.onEdit, required this.onDelete});

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
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
