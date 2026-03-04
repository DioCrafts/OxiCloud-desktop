import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/sync_folder.dart';
import '../../core/entities/sync_status.dart';
import '../../core/repositories/sync_repository.dart';
import '../blocs/sync/sync_bloc.dart';
import '../theme/oxicloud_colors.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SyncItem> _pendingItems = [];
  List<SyncHistoryEntry> _recentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final repo = context.read<SyncRepository>();
    final pendingResult = await repo.getPendingItems();
    final historyResult = await repo.getSyncHistory(50);

    setState(() {
      _pendingItems = pendingResult.fold((_) => [], (items) => items);
      _recentHistory = historyResult.fold((_) => [], (entries) => entries);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions, size: 18),
              text: 'Pending (${_pendingItems.length})',
            ),
            const Tab(
              icon: Icon(Icons.history, size: 18),
              text: 'Recent',
            ),
            const Tab(
              icon: Icon(Icons.warning_amber, size: 18),
              text: 'Conflicts',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildRecentTab(),
                _buildConflictsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingItems.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'All caught up!',
        'No pending sync operations',
      );
    }

    return ListView.separated(
      itemCount: _pendingItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _pendingItems[index];
        return ListTile(
          leading: Icon(
            item.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: item.direction == SyncDirection.upload
                ? OxiColors.info
                : OxiColors.success,
          ),
          title: Text(
            item.name,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.path,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.direction == SyncDirection.upload
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_download_outlined,
                size: 16,
                color: OxiColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(item.status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTab() {
    if (_recentHistory.isEmpty) {
      return _buildEmptyState(
        Icons.history,
        'No recent activity',
        'Sync history will appear here',
      );
    }

    return ListView.separated(
      itemCount: _recentHistory.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _recentHistory[index];
        final isError = entry.status == SyncItemStatus.error;
        final fileName = entry.itemPath.split('/').last;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isError ? OxiColors.errorBgLight : OxiColors.primaryLight,
            radius: 18,
            child: Icon(
              _getOperationIcon(entry.operation),
              color: isError ? OxiColors.error : OxiColors.primary,
              size: 18,
            ),
          ),
          title: Text(fileName, overflow: TextOverflow.ellipsis),
          subtitle: Row(
            children: [
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isError
                      ? OxiColors.errorBgLight
                      : OxiColors.successBgLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.operation,
                  style: TextStyle(
                    fontSize: 10,
                    color: isError ? OxiColors.error : OxiColors.successDark,
                  ),
                ),
              ),
            ],
          ),
          trailing: Icon(
            entry.direction == SyncDirection.upload
                ? Icons.arrow_upward
                : entry.direction == SyncDirection.download
                    ? Icons.arrow_downward
                    : Icons.swap_vert,
            size: 16,
            color: OxiColors.textSecondary,
          ),
        );
      },
    );
  }

  Widget _buildConflictsTab() {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final conflicts = state is SyncIdle ? state.conflicts : <SyncConflict>[];

        if (conflicts.isEmpty) {
          return _buildEmptyState(
            Icons.check_circle_outline,
            'No conflicts',
            'All files are in sync',
          );
        }

        return ListView.separated(
          itemCount: conflicts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final conflict = conflicts[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: OxiColors.warningBg,
                child: Icon(Icons.warning, color: OxiColors.warningDark, size: 20),
              ),
              title: Text(
                conflict.fileName,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Modified locally & remotely',
                style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
              ),
              trailing: PopupMenuButton<ConflictResolution>(
                onSelected: (resolution) {
                  context.read<SyncBloc>().add(
                        ResolveConflictRequested(
                          conflictId: conflict.id,
                          resolution: resolution,
                        ),
                      );
                  _loadData();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: ConflictResolution.keepLocal,
                    child: Text('Keep Local'),
                  ),
                  const PopupMenuItem(
                    value: ConflictResolution.keepRemote,
                    child: Text('Keep Remote'),
                  ),
                  const PopupMenuItem(
                    value: ConflictResolution.keepBoth,
                    child: Text('Keep Both'),
                  ),
                  const PopupMenuItem(
                    value: ConflictResolution.skip,
                    child: Text('Skip'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: OxiColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: OxiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: OxiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SyncItemStatus status) {
    Color color;
    String label;
    switch (status) {
      case SyncItemStatus.pending:
        color = OxiColors.info;
        label = 'Pending';
      case SyncItemStatus.syncing:
        color = OxiColors.primary;
        label = 'Syncing';
      case SyncItemStatus.synced:
        color = OxiColors.success;
        label = 'Synced';
      case SyncItemStatus.error:
        color = OxiColors.error;
        label = 'Error';
      case SyncItemStatus.conflict:
        color = OxiColors.warningDark;
        label = 'Conflict';
      case SyncItemStatus.ignored:
        color = OxiColors.textSecondary;
        label = 'Ignored';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  IconData _getOperationIcon(String operation) {
    switch (operation.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;
      case 'modify':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'rename':
        return Icons.drive_file_rename_outline;
      case 'upload':
        return Icons.cloud_upload_outlined;
      case 'download':
        return Icons.cloud_download_outlined;
      default:
        return Icons.sync;
    }
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${time.day}/${time.month}/${time.year}';
  }
}
