import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/model/app_metadata.dart';
import 'package:teledesk/src/common/router/routes.dart';
import 'package:teledesk/src/common/widget/main_navigation.dart';
import 'package:teledesk/src/feature/authentication/model/worker.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/settings/widget/settings_scope.dart';

/// {@template settings_screen}
/// SettingsScreen widget.
/// {@endtemplate}
class SettingsScreen extends StatelessWidget {
  /// {@macro settings_screen}
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final worker = AuthenticationScope.workerOf(context);
    final metadata = Dependencies.of(context).metadata;
    final themeMode = SettingsScope.themeModeOf(context);
    final isDark = themeMode == ThemeMode.dark;

    return MainNavigation(
      currentRoute: Routes.settings,
      child: _SettingsScaffold(
        worker: worker,
        isDark: isDark,
        metadata: metadata,
      ),
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.worker,
    required this.isDark,
    required this.metadata,
  });

  final Worker? worker;
  final bool isDark;
  final AppMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      worker?.initials ?? '?',
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
                          worker?.displayName ?? 'Unknown',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${worker?.username ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            worker?.role == WorkerRole.admin ? 'Admin' : 'Worker',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
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

          // Appearance section
          Text(
            'Appearance',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              title: const Text('Dark Mode'),
              subtitle:
                  Text(isDark ? 'Dark theme active' : 'Light theme active'),
              value: isDark,
              onChanged: (v) => SettingsScope.setThemeMode(
                  context, v ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const SizedBox(height: 16),

          // Admin section
          if (worker?.isAdmin == true) ...[
            Text(
              'Administration',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.smart_toy_outlined,
                          color: colorScheme.primary, size: 20),
                    ),
                    title: const Text('Bot Settings'),
                    subtitle: const Text('Configure Telegram bot'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16),
                    onTap: () => Octopus.of(context).setState(
                      (state) =>
                          state..add(Routes.botSettings.node()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.people_outline_rounded,
                          color: colorScheme.secondary, size: 20),
                    ),
                    title: const Text('Workers'),
                    subtitle: const Text('Manage team members'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16),
                    onTap: () => Octopus.of(context).setState(
                      (state) => state..add(Routes.workers.node()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // About
          Text(
            'About',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: 'App Name', value: 'TeleDesk'),
                  const Divider(height: 24),
                  _InfoRow(label: 'Version', value: metadata.appVersion),
                  const Divider(height: 24),
                  _InfoRow(label: 'Platform', value: metadata.operatingSystem),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign out
          FilledButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
            onPressed: () {
              AuthenticationScope.controllerOf(context).signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
