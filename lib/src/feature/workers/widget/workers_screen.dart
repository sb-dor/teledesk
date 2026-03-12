import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';
import 'package:teledesk/src/feature/workers/controller/workers_controller.dart';

const List<String> _kColors = ['#6366F1', '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'];

/// {@template workers_screen}
/// WorkersScreen widget.
/// {@endtemplate}
class WorkersScreen extends StatefulWidget {
  /// {@macro workers_screen}
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  late final WorkersController _controller;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    _controller = WorkersController(repository: deps.workerRepository)..load();
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = _controller.state;

    Widget body;
    if (state is Workers$LoadingState) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state is Workers$ErrorState) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _controller.load, child: const Text('Retry')),
          ],
        ),
      );
    } else {
      final workers = (state as Workers$IdleState).workers;
      if (workers.isEmpty) {
        body = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No workers yet',
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add a worker',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      } else {
        body = ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _WorkerCard(
            worker: workers[i],
            onChangePassword: () => _showChangePasswordDialog(context, workers[i].id),
            onDeactivate: () => _confirmDeactivate(context, workers[i]),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Worker'),
        onPressed: () => _showAddWorkerDialog(context),
      ),
      body: body,
    );
  }

  void _showAddWorkerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var selectedRole = IdentityRole.worker;
    var selectedColor = _kColors.first;
    var obscure = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Worker'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'john.doe',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                  obscureText: obscure,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                Text('Role', style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 6),
                SegmentedButton<IdentityRole>(
                  segments: const [
                    ButtonSegment(
                      value: IdentityRole.worker,
                      label: Text('Worker'),
                      icon: Icon(Icons.support_agent_rounded),
                    ),
                    ButtonSegment(
                      value: IdentityRole.admin,
                      label: Text('Admin'),
                      icon: Icon(Icons.admin_panel_settings_rounded),
                    ),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (s) => setLocal(() => selectedRole = s.first),
                ),
                const SizedBox(height: 16),
                Text('Color', style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _kColors.map((hex) {
                    final color = _hexColor(hex);
                    final isSelected = selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setLocal(() => selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop();
                  _controller.addWorker(
                    username: usernameCtrl.text.trim(),
                    password: passwordCtrl.text,
                    displayName: nameCtrl.text.trim(),
                    role: selectedRole,
                    colorCode: selectedColor,
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, int workerId) {
    final ctrl = TextEditingController();
    var obscure = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Change Password'),
          content: TextFormField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setLocal(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (ctrl.text.length >= 6) {
                  Navigator.of(ctx).pop();
                  _controller.changePassword(workerId, ctrl.text);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Password updated')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, Worker worker) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Worker'),
        content: Text(
          'Are you sure you want to deactivate ${worker.displayName}? They will no longer be able to log in.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.deactivate(worker.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  } catch (_) {
    return Colors.indigo;
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    required this.onChangePassword,
    required this.onDeactivate,
  });

  final Worker worker;
  final VoidCallback onChangePassword;
  final VoidCallback onDeactivate;

  Color get _statusColor => switch (worker.status) {
    IdentityStatus.online => Colors.green,
    IdentityStatus.away => Colors.amber,
    IdentityStatus.busy => Colors.red,
    IdentityStatus.offline => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workerColor = _hexColor(worker.colorCode);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with status dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: workerColor.withOpacity(0.2),
                  child: Text(
                    worker.initials,
                    style: TextStyle(color: workerColor, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
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
                      Text(
                        worker.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: worker.identityRole == IdentityRole.admin
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          worker.identityRole == IdentityRole.admin ? 'Admin' : 'Worker',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: worker.identityRole == IdentityRole.admin
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${worker.username}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Color dot
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: workerColor, shape: BoxShape.circle),
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'password') onChangePassword();
                if (value == 'deactivate') onDeactivate();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'password',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.lock_reset_rounded),
                    title: Text('Change Password'),
                  ),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.person_off_rounded, color: theme.colorScheme.error),
                    title: Text('Deactivate', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
