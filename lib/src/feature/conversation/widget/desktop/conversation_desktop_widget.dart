import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/chats/model/chat_message.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';
import 'package:teledesk/src/feature/conversation/controller/conversation_controller.dart';
import 'package:teledesk/src/feature/conversation/widget/conversation_config_widget.dart';
import 'package:teledesk/src/feature/conversation/widget/controllers/conversation_data_controller.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/authentication/data/worker_repository.dart';
import 'package:teledesk/src/feature/authentication/model/worker.dart';

class ConversationDesktopWidget extends StatefulWidget {
  const ConversationDesktopWidget({super.key});

  @override
  State<ConversationDesktopWidget> createState() =>
      _ConversationDesktopWidgetState();
}

class _ConversationDesktopWidgetState
    extends State<ConversationDesktopWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Worker> _allWorkers = [];
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final deps = Dependencies.of(context);
    try {
      final workers = await deps.workerRepository.getWorkers();
      if (mounted) setState(() => _allWorkers = workers);
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(ConversationConfigWidgetState scope) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final dataCtrl = scope.conversationDataController;
    if (dataCtrl.isNoteMode) {
      scope.conversationController.addNote(text);
    } else {
      scope.conversationController.sendText(text);
    }
    _textController.clear();
    dataCtrl.clearMessage();
    _focusNode.requestFocus();
  }

  Future<void> _pickAndSendFile(ConversationConfigWidgetState scope) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final isImage = file.extension != null &&
        ['jpg', 'jpeg', 'png', 'gif', 'webp']
            .contains(file.extension!.toLowerCase());
    if (isImage) {
      scope.conversationController.sendPhoto(
        file.bytes!,
        file.name,
      );
    } else {
      scope.conversationController.sendDocument(
        file.bytes!,
        file.name,
      );
    }
  }

  void _showTransferDialog(
    BuildContext context,
    ConversationConfigWidgetState scope,
    int currentWorkerId,
  ) {
    final otherWorkers =
        _allWorkers.where((w) => w.id != currentWorkerId).toList();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Conversation'),
        content: SizedBox(
          width: 300,
          child: otherWorkers.isEmpty
              ? const Text('No other workers available.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherWorkers.length,
                  itemBuilder: (_, i) {
                    final w = otherWorkers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _hexColor(w.colorCode),
                        child: Text(
                          w.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(w.displayName),
                      subtitle: Text(w.role.name),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        scope.conversationController.transferTo(w.id);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.indigo;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ConversationInhWidget.of(context);
    final ctrl = scope.conversationController;
    final dataCtrl = scope.conversationDataController;
    final currentWorker = AuthenticationScope.workerOf(context);
    final deps = Dependencies.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, dataCtrl]),
      builder: (context, _) {
        final state = ctrl.state;
        final isSending = state is Conversation$SendingState;

        Conversation? conversation;
        if (state is Conversation$IdleState) {
          conversation = state.conversation;
        } else if (state is Conversation$ErrorState) {
          conversation = state.conversation;
        }

        return Scaffold(
          appBar: AppBar(
            leading: Navigator.canPop(context)
                ? BackButton(onPressed: () => Navigator.of(context).maybePop())
                : null,
            title: conversation != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        _statusLabel(conversation.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _statusColor(conversation.status),
                        ),
                      ),
                    ],
                  )
                : const Text('Conversation'),
            actions: [
              if (isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (conversation != null &&
                  conversation.status != ConversationStatus.finished)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    switch (value) {
                      case 'transfer':
                        _showTransferDialog(
                          context,
                          scope,
                          currentWorker?.id ?? 0,
                        );
                      case 'allow_finish':
                        ctrl.allowUserToFinish();
                      case 'finish':
                        _confirmFinish(context, ctrl);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'transfer',
                      child: ListTile(
                        leading: Icon(Icons.swap_horiz_rounded),
                        title: Text('Transfer'),
                        dense: true,
                      ),
                    ),
                    if (!conversation!.canUserFinish)
                      const PopupMenuItem(
                        value: 'allow_finish',
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline_rounded),
                          title: Text('Allow User to Finish'),
                          dense: true,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'finish',
                      child: ListTile(
                        leading: Icon(Icons.done_all_rounded),
                        title: Text('Finish Chat'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Error banner
              if (state is Conversation$ErrorState)
                Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Message list
              Expanded(
                child: state is Conversation$LoadingState
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<ChatMessage>>(
                        stream: deps.conversationRepository
                            .watchMessages(scope.widget.conversationId),
                        builder: (ctx, snapshot) {
                          final messages = snapshot.data ?? [];
                          if (messages.isNotEmpty) {
                            _scrollToBottom();
                          }
                          return _MessageList(
                            messages: messages,
                            scrollController: _scrollController,
                            currentWorkerId: currentWorker?.id ?? 0,
                            allWorkers: _allWorkers,
                          );
                        },
                      ),
              ),

              // Quick replies popup
              if (dataCtrl.showQuickReplies)
                _QuickRepliesPanel(
                  replies: dataCtrl.filteredReplies,
                  onSelect: (reply) {
                    dataCtrl.selectQuickReply(reply);
                    _textController.text = reply.content;
                    _textController.selection = TextSelection.collapsed(
                      offset: reply.content.length,
                    );
                  },
                ),

              // Input bar
              _MessageInputBar(
                textController: _textController,
                focusNode: _focusNode,
                isNoteMode: dataCtrl.isNoteMode,
                isSending: isSending,
                isFinished: conversation?.status == ConversationStatus.finished,
                onTextChanged: (text) {
                  dataCtrl.setMessageText(text, scope.quickReplies);
                  // Send typing action debounced
                  _typingTimer?.cancel();
                  if (text.isNotEmpty && !dataCtrl.isNoteMode) {
                    _typingTimer = Timer(
                      const Duration(milliseconds: 500),
                      ctrl.sendTypingAction,
                    );
                  }
                },
                onSend: () => _sendMessage(scope),
                onAttach: () => _pickAndSendFile(scope),
                onToggleNote: dataCtrl.toggleNoteMode,
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmFinish(
      BuildContext context, ConversationController ctrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Conversation'),
        content: const Text(
            'Are you sure you want to close this conversation? The user will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ctrl.finishConversation();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ConversationStatus status) => switch (status) {
        ConversationStatus.open => 'Open',
        ConversationStatus.inProgress => 'In Progress',
        ConversationStatus.finishRequested => 'Finish Requested',
        ConversationStatus.finished => 'Closed',
      };

  Color _statusColor(ConversationStatus status) => switch (status) {
        ConversationStatus.open => Colors.blue,
        ConversationStatus.inProgress => Colors.orange,
        ConversationStatus.finishRequested => Colors.purple,
        ConversationStatus.finished => Colors.grey,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Message List
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
    required this.currentWorkerId,
    required this.allWorkers,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final int currentWorkerId;
  final List<Worker> allWorkers;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        final showDate = i == 0 ||
            !_isSameDay(messages[i - 1].sentAt, msg.sentAt);
        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.sentAt),
            _MessageBubble(
              message: msg,
              allWorkers: allWorkers,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final label = isToday ? 'Today' : DateFormat.MMMEd().format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.allWorkers,
  });

  final ChatMessage message;
  final List<Worker> allWorkers;

  String _workerName(int? workerId) {
    if (workerId == null) return 'Worker';
    final w = allWorkers.where((w) => w.id == workerId).firstOrNull;
    return w?.displayName ?? 'Worker #$workerId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Internal note
    if (message.isNote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Internal Note',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${_workerName(message.sentByWorkerId)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.Hm().format(message.sentAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.text ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isFromBot = message.isFromBot;
    final alignment =
        isFromBot ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAlignment =
        isFromBot ? MainAxisAlignment.end : MainAxisAlignment.start;

    final bubbleColor = isFromBot
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final textColor =
        isFromBot ? colorScheme.onPrimary : colorScheme.onSurface;
    final timeColor = isFromBot
        ? colorScheme.onPrimary.withOpacity(0.7)
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: mainAlignment,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isFromBot) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isFromBot ? 16 : 4),
                        bottomRight: Radius.circular(isFromBot ? 4 : 16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isFromBot)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _workerName(message.sentByWorkerId),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                          ),
                        _MessageContent(message: message, textColor: textColor),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat.Hm().format(message.sentAt),
                          style: TextStyle(fontSize: 10, color: timeColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isFromBot) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.textColor});

  final ChatMessage message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.photo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.photo_rounded, size: 40, color: Colors.grey),
              ),
            ),
            if (message.text != null && message.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.text!,
                  style: TextStyle(color: textColor),
                ),
              ),
          ],
        );
      case MessageType.video:
        return _MediaTile(
          icon: Icons.videocam_rounded,
          label: message.fileName ?? 'Video',
          textColor: textColor,
          caption: message.text,
        );
      case MessageType.gif:
        return _MediaTile(
          icon: Icons.gif_rounded,
          label: 'GIF',
          textColor: textColor,
          caption: message.text,
        );
      case MessageType.sticker:
        return _MediaTile(
          icon: Icons.emoji_emotions_rounded,
          label: 'Sticker',
          textColor: textColor,
          caption: null,
        );
      case MessageType.document:
        return _MediaTile(
          icon: Icons.insert_drive_file_rounded,
          label: message.fileName ?? 'Document',
          textColor: textColor,
          caption: message.text,
        );
      case MessageType.voice:
        return _MediaTile(
          icon: Icons.mic_rounded,
          label: 'Voice message',
          textColor: textColor,
          caption: null,
        );
      case MessageType.videoNote:
        return _MediaTile(
          icon: Icons.videocam_rounded,
          label: 'Video note',
          textColor: textColor,
          caption: null,
        );
      case MessageType.audio:
        return _MediaTile(
          icon: Icons.music_note_rounded,
          label: message.fileName ?? 'Audio',
          textColor: textColor,
          caption: message.text,
        );
      case MessageType.note:
        return Text(message.text ?? '', style: TextStyle(color: textColor));
      case MessageType.text:
        if (message.text == null || message.text!.isEmpty) {
          return Text('(empty)', style: TextStyle(color: textColor));
        }
        return Text(message.text!, style: TextStyle(color: textColor));
    }
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor.withOpacity(0.8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (caption != null && caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(caption!, style: TextStyle(color: textColor)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Replies Panel
// ─────────────────────────────────────────────────────────────────────────────

class _QuickRepliesPanel extends StatelessWidget {
  const _QuickRepliesPanel({required this.replies, required this.onSelect});

  final List replies;
  final Function(dynamic) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: replies.length,
        itemBuilder: (ctx, i) {
          final reply = replies[i];
          return ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#${reply.title}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              reply.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            onTap: () => onSelect(reply),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Input Bar
// ─────────────────────────────────────────────────────────────────────────────

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.textController,
    required this.focusNode,
    required this.isNoteMode,
    required this.isSending,
    required this.isFinished,
    required this.onTextChanged,
    required this.onSend,
    required this.onAttach,
    required this.onToggleNote,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isNoteMode;
  final bool isSending;
  final bool isFinished;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onToggleNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = isNoteMode
        ? const Color(0xFFFFF8E1)
        : colorScheme.surfaceContainerLow;

    if (isFinished) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: colorScheme.surfaceContainerLow,
        child: Center(
          child: Text(
            'This conversation is closed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNoteMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Internal Note — not visible to user',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: isSending ? null : onAttach,
                  tooltip: 'Attach file',
                ),
                // Note toggle
                IconButton(
                  icon: Icon(
                    isNoteMode ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: isNoteMode ? Colors.amber : null,
                  ),
                  onPressed: onToggleNote,
                  tooltip: isNoteMode ? 'Exit note mode' : 'Add internal note',
                ),
                const SizedBox(width: 4),
                // Text field
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isNoteMode
                          ? 'Write an internal note...'
                          : 'Type a message... (# for quick replies)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isNoteMode
                          ? Colors.amber.shade50
                          : colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: onTextChanged,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 4),
                // Send button
                _SendButton(
                  onSend: onSend,
                  isSending: isSending,
                  textController: textController,
                  isNoteMode: isNoteMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.onSend,
    required this.isSending,
    required this.textController,
    required this.isNoteMode,
  });

  final VoidCallback onSend;
  final bool isSending;
  final TextEditingController textController;
  final bool isNoteMode;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    widget.textController.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        widget.textController.text.trim().isNotEmpty && !widget.isSending;
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilledButton(
        onPressed: canSend ? widget.onSend : null,
        style: FilledButton.styleFrom(
          backgroundColor: widget.isNoteMode
              ? Colors.amber
              : colorScheme.primary,
          foregroundColor: widget.isNoteMode ? Colors.black87 : null,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
          minimumSize: const Size(44, 44),
        ),
        child: widget.isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                widget.isNoteMode
                    ? Icons.save_rounded
                    : Icons.send_rounded,
                size: 18,
              ),
      ),
    );
  }
}
