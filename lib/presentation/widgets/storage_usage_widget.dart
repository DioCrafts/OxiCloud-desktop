import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/infrastructure/services/local_storage_manager.dart';
import 'package:oxicloud_desktop/presentation/providers/auth_provider.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';

/// Widget for displaying storage usage information
class StorageUsageWidget extends ConsumerStatefulWidget {
  /// Create a StorageUsageWidget
  const StorageUsageWidget({super.key});

  @override
  ConsumerState<StorageUsageWidget> createState() => _StorageUsageWidgetState();
}

class _StorageUsageWidgetState extends ConsumerState<StorageUsageWidget> {
  final LocalStorageManager _storageManager = getIt<LocalStorageManager>();
  
  int _cacheSize = 0;
  int _offlineSize = 0;
  
  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }
  
  Future<void> _loadStorageInfo() async {
    final cacheSize = await _storageManager.getCacheSize();
    final offlineSize = await _storageManager.getOfflineSize();
    
    if (mounted) {
      setState(() {
        _cacheSize = cacheSize;
        _offlineSize = offlineSize;
      });
    }
  }
  
  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = bytes;
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return i == 0
        ? '$size ${suffixes[i]}'
        : '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Usage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildServerStorageInfo(currentUser),
            const Divider(),
            _buildLocalStorageInfo(),
            const SizedBox(height: 16),
            _buildStorageLegend(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServerStorageInfo(User user) {
    final quotaBytes = user.quotaBytes;
    final usedBytes = user.usedBytes;
    final usagePercentage = user.usagePercentage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server Storage',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: quotaBytes > 0 ? usagePercentage / 100 : 0,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 8),
        Text(
          'Used ${_formatSize(usedBytes)} of ${quotaBytes == 0 ? 'Unlimited' : _formatSize(quotaBytes)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (quotaBytes > 0 && usagePercentage > 90)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Storage almost full',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildLocalStorageInfo() {
    // Calculate total
    final totalLocal = _cacheSize + _offlineSize;
    
    // Calculate percentages
    final cachePercentage = totalLocal > 0 ? _cacheSize / totalLocal : 0.0;
    final offlinePercentage = totalLocal > 0 ? _offlineSize / totalLocal : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local Storage',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (totalLocal > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Flexible(
                    flex: (cachePercentage * 100).toInt(),
                    child: Container(color: Colors.blue),
                  ),
                  Flexible(
                    flex: (offlinePercentage * 100).toInt(),
                    child: Container(color: Colors.green),
                  ),
                ],
              ),
            ),
          )
        else
          LinearProgressIndicator(
            value: 0,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Cache: ${_formatSize(_cacheSize)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: Text(
                'Offline: ${_formatSize(_offlineSize)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Total local storage: ${_formatSize(totalLocal)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildStorageLegend() {
    return Row(
      children: [
        _buildLegendItem('Server', Colors.grey.shade300),
        const SizedBox(width: 16),
        _buildLegendItem('Cache', Colors.blue),
        const SizedBox(width: 16),
        _buildLegendItem('Offline', Colors.green),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}