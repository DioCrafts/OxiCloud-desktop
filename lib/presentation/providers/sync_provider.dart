import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/sync_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/domain/entities/conflict_resolution.dart';

/// Provider for sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = getIt<SyncService>();
  return syncService.statusStream;
});

/// Provider for sync statistics
final syncStatsProvider = StreamProvider<SyncStats>((ref) {
  final syncService = getIt<SyncService>();
  return syncService.statsStream;
});

/// Provider for current sync status
final currentSyncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = getIt<SyncService>();
  return syncService.currentStatus;
});

/// Provider for last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncService = getIt<SyncService>();
  return syncService.lastSyncTime;
});

/// Provider for whether sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final syncService = getIt<SyncService>();
  return syncService.isSyncing;
});

/// Notifier for sync actions
class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncService _syncService;
  
  /// Create a SyncNotifier
  SyncNotifier(this._syncService) : super(const AsyncValue.data(null));
  
  /// Trigger a manual sync
  Future<void> syncNow() async {
    if (_syncService.isSyncing) {
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      await _syncService.syncNow();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Resolve a sync conflict
  Future<void> resolveConflict({
    required String itemId,
    required ConflictResolution resolution,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _syncService.resolveConflict(
        itemId: itemId,
        resolution: resolution,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for sync actions
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
  return SyncNotifier(getIt<SyncService>());
});