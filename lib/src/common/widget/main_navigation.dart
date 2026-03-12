import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/common/util/screen_util.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/chats/controller/chats_controller.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';

/// Wraps a screen with a navigation rail (desktop/tablet) or bottom nav bar
/// (mobile). Navigation destinations: Dashboard, Chats (with badge), Settings.
///
/// On desktop/tablet the rail is shown to the left of the child.
/// On mobile a bottom navigation bar is shown below the child.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, required this.child, required this.currentRoute});

  final Widget child;
  final Routes currentRoute;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _openCount = 0;
  ChatsController? _chatsController;

  static const List<_NavDest> _destinations = [
    _NavDest(
      route: Routes.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavDest(
      route: Routes.chats,
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Chats',
    ),
    _NavDest(
      route: Routes.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final deps = Dependencies.of(context);
      final worker = AuthenticationScope.identityOf(context, listen: false);
      _chatsController = ChatsController(
        repository: deps.conversationRepository,
        workerId: worker?.id ?? 0,
      )..initialize();
      _chatsController!.addListener(_onChatsChanged);
    });
  }

  void _onChatsChanged() {
    final state = _chatsController!.state;
    if (state is Chats$IdleState) {
      final count = state.openConversations.length;
      if (count != _openCount && mounted) {
        setState(() => _openCount = count);
      }
    }
  }

  @override
  void dispose() {
    _chatsController?.removeListener(_onChatsChanged);
    _chatsController?.dispose();
    super.dispose();
  }

  int get _selectedIndex {
    final idx = _destinations.indexWhere((d) => d.route == widget.currentRoute);
    return idx < 0 ? 0 : idx;
  }

  void _navigateTo(Routes route) {
    Octopus.of(context).setState((state) => OctopusState.single(route.node()));
  }

  @override
  Widget build(BuildContext context) {
    return context.screenSizeMaybeWhen(
      orElse: () => _buildDesktop(context),
      phone: () => _buildMobile(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          // Navigation rail column
          Material(
            color: colorScheme.surface,
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => _navigateTo(_destinations[i].route),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: colorScheme.surface,
                  leading: const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: _TeleDeskLogo(),
                  ),
                  destinations: _destinations.map((d) {
                    final showBadge = d.route == Routes.chats && _openCount > 0;
                    return NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: showBadge,
                        label: Text('$_openCount'),
                        child: Icon(d.icon),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: showBadge,
                        label: Text('$_openCount'),
                        child: Icon(d.selectedIcon),
                      ),
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(width: 1),
              ],
            ),
          ),
          // Main content
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.child),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => _navigateTo(_destinations[i].route),
            destinations: _destinations.map((d) {
              final showBadge = d.route == Routes.chats && _openCount > 0;
              return NavigationDestination(
                icon: Badge(
                  isLabelVisible: showBadge,
                  label: Text('$_openCount'),
                  child: Icon(d.icon),
                ),
                selectedIcon: Badge(
                  isLabelVisible: showBadge,
                  label: Text('$_openCount'),
                  child: Icon(d.selectedIcon),
                ),
                label: d.label,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Routes route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _TeleDeskLogo extends StatelessWidget {
  const _TeleDeskLogo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'TeleDesk',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
