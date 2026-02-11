import 'package:flutter/material.dart';

/// Card widget to display and resolve sync conflicts
class ConflictCard extends StatelessWidget {
  final String conflictId;
  final String filePath;
  final DateTime localModified;
  final DateTime remoteModified;
  final int localSize;
  final int remoteSize;
  final String conflictType;
  final ValueChanged<ConflictResolution>? onResolve;

  const ConflictCard({
    super.key,
    required this.conflictId,
    required this.filePath,
    required this.localModified,
    required this.remoteModified,
    required this.localSize,
    required this.remoteSize,
    required this.conflictType,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with file name and conflict icon
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileName(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getConflictTypeLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // File path
            Text(
              filePath,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),

            // Comparison
            Row(
              children: [
                // Local version
                Expanded(
                  child: _VersionInfo(
                    label: 'Local',
                    icon: Icons.computer,
                    modified: localModified,
                    size: localSize,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                // Remote version
                Expanded(
                  child: _VersionInfo(
                    label: 'Server',
                    icon: Icons.cloud,
                    modified: remoteModified,
                    size: remoteSize,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.computer,
                  label: 'Keep Local',
                  color: Colors.blue,
                  onPressed: () => onResolve?.call(ConflictResolution.keepLocal),
                ),
                _ActionButton(
                  icon: Icons.cloud,
                  label: 'Keep Server',
                  color: Colors.green,
                  onPressed: () => onResolve?.call(ConflictResolution.keepRemote),
                ),
                _ActionButton(
                  icon: Icons.content_copy,
                  label: 'Keep Both',
                  color: Colors.orange,
                  onPressed: () => onResolve?.call(ConflictResolution.keepBoth),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName() {
    return filePath.split('/').last;
  }

  String _getConflictTypeLabel() {
    switch (conflictType) {
      case 'both_modified':
        return 'Modified on both sides';
      case 'deleted_locally':
        return 'Deleted locally, modified on server';
      case 'deleted_remotely':
        return 'Deleted on server, modified locally';
      case 'type_mismatch':
        return 'Type mismatch (file vs folder)';
      default:
        return 'Conflict detected';
    }
  }
}

class _VersionInfo extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime modified;
  final int size;
  final Color color;

  const _VersionInfo({
    required this.label,
    required this.icon,
    required this.modified,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(modified),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            _formatSize(size),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepBoth,
  skip,
}
