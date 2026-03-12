import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/feature/chats/controller/chats_controller.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';
import 'package:teledesk/src/feature/chats/widget/chats_config_widget.dart';
import 'package:teledesk/src/feature/chats/widget/controllers/chats_data_controller.dart';

class ChatsDesktopWidget extends StatefulWidget {
  const ChatsDesktopWidget({super.key});

  @override
  State<ChatsDesktopWidget> createState() => _ChatsDesktopWidgetState();
}

class _ChatsDesktopWidgetState extends State<ChatsDesktopWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToConversation(BuildContext context, int conversationId) {
    Octopus.of(context).setState(
      (state) =>
          state
            ..add(
              Routes.conversation.node()..arguments['id'] = conversationId.toString(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = ChatsInhWidget.of(context);
    final dataController = scope.chatsDataController;
    final chatsController = scope.chatsController;

    return ListenableBuilder(
      listenable: Listenable.merge([dataController, chatsController]),
      builder: (context, _) {
        final chatsState = chatsController.state;
        final tab = dataController.selectedTab;
        final isSearching = dataController.isSearching;

        List<Conversation> conversations;
        if (isSearching) {
          conversations = dataController.searchResults;
        } else if (chatsState is Chats$IdleState) {
          conversations = tab == ChatsTab.open
              ? chatsState.openConversations
              : chatsState.myConversations;
        } else {
          conversations = [];
        }

        final openCount = chatsState is Chats$IdleState
            ? chatsState.openConversations.length
            : 0;
        final mineCount = chatsState is Chats$IdleState
            ? chatsState.myConversations.length
            : 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chats'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48 + 8),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: isSearching
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  dataController.clearSearch();
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      onChanged: (q) async {
                        dataController.setSearchQuery(q);
                        if (q.isNotEmpty) {
                          final results =
                              await scope.conversationRepository.searchConversations(q);
                          dataController.setSearchResults(results);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              // Tabs
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'Open Queue',
                        count: openCount,
                        selected: tab == ChatsTab.open,
                        onTap: () => dataController.selectTab(ChatsTab.open),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'Mine',
                        count: mineCount,
                        selected: tab == ChatsTab.mine,
                        onTap: () => dataController.selectTab(ChatsTab.mine),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildBody(context, chatsState, conversations),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ChatsState chatsState,
    List<Conversation> conversations,
  ) {
    if (chatsState is Chats$LoadingState) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chatsState is Chats$ErrorState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(chatsState.message),
          ],
        ),
      );
    }
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return _ConversationTile(
          conversation: conv,
          onTap: () => _navigateToConversation(context, conv.id),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  Color _statusColor(ConversationStatus status) => switch (status) {
        ConversationStatus.open => Colors.blue,
        ConversationStatus.inProgress => Colors.orange,
        ConversationStatus.finishRequested => Colors.purple,
        ConversationStatus.finished => Colors.grey,
      };

  Color _avatarColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty) return Colors.indigo;
    try {
      final hex = colorCode.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.indigo;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat.Hm().format(dt);
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(conversation.status);
    final initials = conversation.initials;
    // Use a consistent color based on the conversation id
    final colors = [
      Colors.indigo,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    final avatarColor = colors[conversation.id % colors.length];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor.withOpacity(0.2),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: conversation.hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: conversation.hasUnread
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview ?? 'No messages yet',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: conversation.hasUnread
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: conversation.hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
