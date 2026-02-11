import 'package:flutter/material.dart';

/// Widget to display storage usage as a progress bar
class StorageUsageBar extends StatelessWidget {
  final int usedBytes;
  final int totalBytes;
  final double height;
  final Color? usedColor;
  final Color? backgroundColor;
  final bool showLabels;

  const StorageUsageBar({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
    this.height = 8,
    this.usedColor,
    this.backgroundColor,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = totalBytes > 0 ? usedBytes / totalBytes : 0.0;
    final clampedPercentage = percentage.clamp(0.0, 1.0);
    
    // Color based on usage level
    final defaultColor = _getColorForUsage(clampedPercentage);
    final fgColor = usedColor ?? defaultColor;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatBytes(usedBytes)} used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_formatBytes(totalBytes - usedBytes)} free',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              // Background
              Container(
                height: height,
                width: double.infinity,
                color: bgColor,
              ),
              // Progress
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: height,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fgColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${(clampedPercentage * 100).toStringAsFixed(1)}% of ${_formatBytes(totalBytes)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Color _getColorForUsage(double percentage) {
    if (percentage >= 0.9) {
      return Colors.red;
    } else if (percentage >= 0.75) {
      return Colors.orange;
    } else if (percentage >= 0.5) {
      return Colors.amber;
    }
    return Colors.green;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Compact storage indicator showing just the percentage and icon
class StorageIndicator extends StatelessWidget {
  final int usedBytes;
  final int totalBytes;
  final VoidCallback? onTap;

  const StorageIndicator({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = totalBytes > 0 ? (usedBytes / totalBytes * 100) : 0.0;
    final color = _getColorForUsage(percentage / 100);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForUsage(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.75) return Colors.orange;
    if (percentage >= 0.5) return Colors.amber;
    return Colors.green;
  }
}
