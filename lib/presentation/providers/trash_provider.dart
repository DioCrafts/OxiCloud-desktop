import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/trash_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/domain/entities/trashed_item.dart';

/// Provider for trashed items
final trashedItemsProvider = FutureProvider<List<TrashedItem>>((ref) async {
  final trashService = getIt<TrashService>();
  return await trashService.listTrashedItems();
});

/// Provider for trash expiration days
final trashExpirationDaysProvider = FutureProvider<int>((ref) async {
  final trashService = getIt<TrashService>();
  return await trashService.getTrashExpirationDays();
});

/// Notifier for trash operations
class TrashNotifier extends StateNotifier<AsyncValue<void>> {
  final TrashService _trashService;
  
  /// Create a TrashNotifier
  TrashNotifier(this._trashService) : super(const AsyncValue.data(null));
  
  /// Restore an item from trash
  Future<void> restoreItem(String trashedItemId) async {
    state = const AsyncValue.loading();
    
    try {
      await _trashService.restoreFromTrash(trashedItemId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Restore an item from trash to a specific folder
  Future<void> restoreItemTo(String trashedItemId, String destinationFolderId) async {
    state = const AsyncValue.loading();
    
    try {
      await _trashService.restoreFromTrashTo(trashedItemId, destinationFolderId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Permanently delete an item from trash
  Future<void> deleteItemPermanently(String trashedItemId) async {
    state = const AsyncValue.loading();
    
    try {
      await _trashService.deletePermanently(trashedItemId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Empty the trash
  Future<void> emptyTrash() async {
    state = const AsyncValue.loading();
    
    try {
      await _trashService.emptyTrash();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Extend expiration for a trashed item
  Future<void> extendExpiration(String trashedItemId, int additionalDays) async {
    state = const AsyncValue.loading();
    
    try {
      await _trashService.extendExpiration(trashedItemId, additionalDays);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for trash operations
final trashNotifierProvider = StateNotifierProvider<TrashNotifier, AsyncValue<void>>((ref) {
  return TrashNotifier(getIt<TrashService>());
});