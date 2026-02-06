import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/sync_status.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/sync/sync_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(const SyncStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OxiCloud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(const LogoutRequested());
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          return Column(
            children: [
              // User info card
              _buildUserInfoCard(),
              const Divider(height: 1),

              // Sync status card
              _buildSyncStatusCard(state),
              const Divider(height: 1),

              // Conflicts (if any)
              if (state is SyncIdle && state.conflicts.isNotEmpty)
                _buildConflictsCard(state.conflicts),

              // Quick actions
              Expanded(child: _buildQuickActions()),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          final isSyncing = state is SyncInProgress;
          return FloatingActionButton.extended(
            onPressed: isSyncing
                ? null
                : () => context.read<SyncBloc>().add(const SyncNowRequested()),
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          final quotaPercent = user.serverInfo.quotaTotal > 0
              ? (user.serverInfo.quotaUsed / user.serverInfo.quotaTotal * 100)
              : 0.0;

          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              user.serverUrl,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Storage quota
                  Row(
                    children: [
                      const Icon(Icons.storage, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: quotaPercent / 100,
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatBytes(user.serverInfo.quotaUsed)} of ${_formatBytes(user.serverInfo.quotaTotal)} used',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSyncStatusCard(SyncState state) {
    String statusText;
    IconData statusIcon;
    Color statusColor;
    double? progress;

    if (state is SyncInProgress) {
      statusText = state.status.currentOperation ?? 'Syncing...';
      statusIcon = Icons.sync;
      statusColor = Colors.blue;
      progress = state.status.progressPercent / 100;
    } else if (state is SyncIdle) {
      final lastSync = state.lastStatus?.lastSyncTime;
      statusText = lastSync != null
          ? 'Last sync: ${_formatTime(lastSync)}'
          : 'Ready to sync';
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (state is SyncPaused) {
      statusText = 'Sync paused';
      statusIcon = Icons.pause_circle;
      statusColor = Colors.orange;
    } else if (state is SyncError) {
      statusText = state.message;
      statusIcon = Icons.error;
      statusColor = Colors.red;
    } else {
      statusText = 'Initializing...';
      statusIcon = Icons.hourglass_empty;
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (state is SyncInProgress)
                  Text(
                    '${state.status.itemsSynced}/${state.status.itemsTotal}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConflictsCard(List<SyncConflict> conflicts) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange[50],
      child: ListTile(
        leading: Icon(Icons.warning, color: Colors.orange[700]),
        title: Text(
          '${conflicts.length} conflicts found',
          style: TextStyle(color: Colors.orange[900]),
        ),
        subtitle: Text(
          'Tap to resolve',
          style: TextStyle(color: Colors.orange[700]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/conflicts'),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionCard(
                icon: Icons.folder,
                label: 'Open Sync Folder',
                onTap: () {
                  // TODO: Open sync folder in file manager
                },
              ),
              _buildActionCard(
                icon: Icons.folder_special,
                label: 'Selective Sync',
                onTap: () => Navigator.of(context).pushNamed('/selective-sync'),
              ),
              _buildActionCard(
                icon: Icons.history,
                label: 'Sync History',
                onTap: () {
                  // TODO: Navigate to sync history
                },
              ),
              _buildActionCard(
                icon: Icons.pause,
                label: 'Pause Sync',
                onTap: () {
                  context.read<SyncBloc>().add(const SyncStopped());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
