import 'package:flutter/material.dart';

/// Widget that displays the current sync status with an animated indicator
class SyncStatusIndicator extends StatefulWidget {
  final SyncState state;
  final double size;
  final Color? color;

  const SyncStatusIndicator({
    super.key,
    required this.state,
    this.size = 24,
    this.color,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == SyncState.syncing) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _getColorForState(context);
    final icon = _getIconForState();

    if (widget.state == SyncState.syncing) {
      return RotationTransition(
        turns: _controller,
        child: Icon(icon, size: widget.size, color: color),
      );
    }

    return Icon(icon, size: widget.size, color: color);
  }

  Color _getColorForState(BuildContext context) {
    switch (widget.state) {
      case SyncState.synced:
        return Colors.green;
      case SyncState.syncing:
        return Theme.of(context).colorScheme.primary;
      case SyncState.error:
        return Colors.red;
      case SyncState.offline:
        return Colors.grey;
      case SyncState.paused:
        return Colors.orange;
      case SyncState.conflict:
        return Colors.amber;
    }
  }

  IconData _getIconForState() {
    switch (widget.state) {
      case SyncState.synced:
        return Icons.cloud_done;
      case SyncState.syncing:
        return Icons.sync;
      case SyncState.error:
        return Icons.cloud_off;
      case SyncState.offline:
        return Icons.cloud_outlined;
      case SyncState.paused:
        return Icons.pause_circle_outline;
      case SyncState.conflict:
        return Icons.warning_amber;
    }
  }
}

/// Enum representing the sync state
enum SyncState {
  synced,
  syncing,
  error,
  offline,
  paused,
  conflict,
}

/// Extension to convert sync state to human-readable text
extension SyncStateExtension on SyncState {
  String get label {
    switch (this) {
      case SyncState.synced:
        return 'Synced';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.error:
        return 'Error';
      case SyncState.offline:
        return 'Offline';
      case SyncState.paused:
        return 'Paused';
      case SyncState.conflict:
        return 'Conflicts';
    }
  }
}
