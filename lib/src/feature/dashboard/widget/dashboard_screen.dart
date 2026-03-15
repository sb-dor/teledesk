import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
import 'package:teledesk/src/common/widget/main_navigation.dart';
import 'package:teledesk/src/common/widget/scaffold_padding.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/dashboard/controller/dashboard_controller.dart';
import 'package:teledesk/src/feature/dashboard/data/dashboard_repository.dart';
import 'package:teledesk/src/feature/initialization/widget/dependencies_scope.dart';
import 'package:teledesk/src/feature/telegram/controller/telegram_polling_controller.dart';

class DashboardInhWidget extends InheritedWidget {
  const DashboardInhWidget({super.key, required this.state, required super.child});

  static DashboardScreenState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<DashboardInhWidget>()?.widget;
    assert(widget != null, 'No DashboardInhWidget found in context');
    return (widget as DashboardInhWidget).state;
  }

  final DashboardScreenState state;

  @override
  bool updateShouldNotify(DashboardInhWidget old) {
    return false;
  }
}

/// {@template dashboard_screen}
/// DashboardScreen widget.
/// {@endtemplate}
class DashboardScreen extends StatefulWidget {
  /// {@macro dashboard_screen}
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late final TelegramPollingController pollingController;
  late final DashboardController dashboardController;
  late final Identity? identity;

  @override
  void initState() {
    super.initState();
    final dependencies = DependenciesScope.of(context);
    pollingController = dependencies.telegramPollingController;
    dashboardController = DashboardController(
      dashboardRepository: DashboardRepositoryImpl(database: dependencies.database),
    )..initialize();
    identity = AuthenticationScope.identityOf(context, listen: false);
    pollingController.addListener(_onPollingChanged);
  }

  void _onPollingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    pollingController.removeListener(_onPollingChanged);
    dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigation(
      currentRoute: Routes.dashboard,
      child: DashboardInhWidget(
        state: this,
        child: _DashboardScaffold(worker: identity, isPolling: pollingController.isPolling),
      ),
    );
  }
}

class _DashboardScaffold extends StatefulWidget {
  const _DashboardScaffold({required this.worker, required this.isPolling});

  final Identity? worker;
  final bool isPolling;

  @override
  State<_DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<_DashboardScaffold> {
  late final _dashboardInhWidget = DashboardInhWidget.of(context);
  late final _dashboardController = _dashboardInhWidget.dashboardController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.isPolling ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isPolling ? 'Bot Online' : 'Bot Offline',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.isPolling ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _dashboardController.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ScaffoldPadding.of(context),
          children:[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        widget.worker?.initials ?? '?',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${widget.worker?.displayName ?? 'Agent'}!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.worker?.identityRole.name ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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

            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListenableBuilder(
              listenable: _dashboardController,
              builder: (context, child) => context.screenSizeMaybeWhen(
                orElse: () => _buildStatsGrid(context, _dashboardController.state, columns: 2),
                desktop: () => _buildStatsGrid(context, _dashboardController.state, columns: 4),
                tablet: () => _buildStatsGrid(context, _dashboardController.state, columns: 2),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildQuickActions(context)
          ]
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardState state, {required int columns}) {
    final items = [
      _StatItem(
        label: 'Open Chats',
        value: state.stats['open'] ?? 0,
        icon: Icons.inbox_rounded,
        color: Colors.blue,
        loading: state.isInProgress,
      ),
      _StatItem(
        label: 'In Progress',
        value: state.stats['inProgress'] ?? 0,
        icon: Icons.chat_bubble_outline_rounded,
        color: Colors.orange,
        loading: state.isInProgress,
      ),
      _StatItem(
        label: 'Finished Today',
        value: state.stats['finishedToday'] ?? 0,
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
        loading: state.isInProgress,
      ),
      _StatItem(
        label: 'Total Messages',
        value: state.stats['totalMessages'] ?? 0,
        icon: Icons.message_outlined,
        color: Colors.purple,
        loading: state.isInProgress,
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _StatCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _QuickActionTile(
          icon: Icons.inbox_rounded,
          label: 'View Open Chats',
          subtitle: 'See all unassigned conversations',
          color: Colors.blue,
          onTap: () =>
              Octopus.of(context).setState((state) => OctopusState.single(Routes.chats.node())),
        ),
        const SizedBox(height: 8),
        _QuickActionTile(
          icon: Icons.chat_rounded,
          label: 'My Conversations',
          subtitle: 'Chats assigned to you',
          color: Colors.orange,
          onTap: () =>
              Octopus.of(context).setState((state) => OctopusState.single(Routes.chats.node())),
        ),
      ],
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.loading,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool loading;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 12),
            if (item.loading)
              Container(
                height: 32,
                width: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              Text(
                item.value.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
