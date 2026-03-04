import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/sync_folder.dart';
import '../../core/repositories/sync_repository.dart';
import '../theme/oxicloud_colors.dart';

class SyncHistoryPage extends StatefulWidget {
  const SyncHistoryPage({super.key});

  @override
  State<SyncHistoryPage> createState() => _SyncHistoryPageState();
}

class _SyncHistoryPageState extends State<SyncHistoryPage> {
  List<SyncHistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = context.read<SyncRepository>();
    final result = await repo.getSyncHistory(100);

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (entries) => setState(() {
        _entries = entries;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: OxiColors.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: OxiColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No sync history yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: OxiColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'History will appear here after files are synced',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: OxiColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return _buildHistoryTile(entry);
        },
      ),
    );
  }

  Widget _buildHistoryTile(SyncHistoryEntry entry) {
    final isError = entry.status == SyncItemStatus.error;
    final icon = _getOperationIcon(entry.operation);
    final directionIcon = _getDirectionIcon(entry.direction);
    final fileName = entry.itemPath.split('/').last;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isError ? OxiColors.errorBgLight : OxiColors.primaryLight,
        child: Icon(
          icon,
          color: isError ? OxiColors.error : OxiColors.primary,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(directionIcon, size: 16, color: OxiColors.textSecondary),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.itemPath,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
          ),
          Row(
            children: [
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isError ? OxiColors.errorBgLight : OxiColors.successBgLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.operation,
                  style: TextStyle(
                    fontSize: 10,
                    color: isError ? OxiColors.error : OxiColors.successDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (entry.errorMessage != null)
            Text(
              entry.errorMessage!,
              style: const TextStyle(fontSize: 11, color: OxiColors.error),
            ),
        ],
      ),
      isThreeLine: true,
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

  IconData _getDirectionIcon(SyncDirection direction) {
    switch (direction) {
      case SyncDirection.upload:
        return Icons.arrow_upward;
      case SyncDirection.download:
        return Icons.arrow_downward;
      case SyncDirection.none:
        return Icons.swap_vert;
    }
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
