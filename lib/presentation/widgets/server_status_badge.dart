import 'package:flutter/material.dart';

/// Badge that shows the server connection status
class ServerStatusBadge extends StatelessWidget {
  final ServerConnectionStatus status;
  final String? serverName;
  final bool showLabel;
  final VoidCallback? onTap;

  const ServerStatusBadge({
    super.key,
    required this.status,
    this.serverName,
    this.showLabel = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForStatus();
    final icon = _getIconForStatus();
    final label = _getLabelForStatus();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: color),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                serverName ?? label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus() {
    switch (status) {
      case ServerConnectionStatus.connected:
        return Colors.green;
      case ServerConnectionStatus.connecting:
        return Colors.orange;
      case ServerConnectionStatus.disconnected:
        return Colors.red;
      case ServerConnectionStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getIconForStatus() {
    switch (status) {
      case ServerConnectionStatus.connected:
        return Icons.cloud_done;
      case ServerConnectionStatus.connecting:
        return Icons.cloud_sync;
      case ServerConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ServerConnectionStatus.unknown:
        return Icons.cloud_outlined;
    }
  }

  String _getLabelForStatus() {
    switch (status) {
      case ServerConnectionStatus.connected:
        return 'Connected';
      case ServerConnectionStatus.connecting:
        return 'Connecting...';
      case ServerConnectionStatus.disconnected:
        return 'Disconnected';
      case ServerConnectionStatus.unknown:
        return 'Unknown';
    }
  }
}

enum ServerConnectionStatus {
  connected,
  connecting,
  disconnected,
  unknown,
}
