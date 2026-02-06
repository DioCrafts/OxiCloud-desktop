import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/sync_repository.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateSyncFolder extends SettingsEvent {
  final String path;

  const UpdateSyncFolder(this.path);

  @override
  List<Object?> get props => [path];
}

class UpdateSyncInterval extends SettingsEvent {
  final int seconds;

  const UpdateSyncInterval(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

class UpdateBandwidthLimits extends SettingsEvent {
  final int uploadKbps;
  final int downloadKbps;

  const UpdateBandwidthLimits({
    required this.uploadKbps,
    required this.downloadKbps,
  });

  @override
  List<Object?> get props => [uploadKbps, downloadKbps];
}

class ToggleDeltaSync extends SettingsEvent {
  final bool enabled;

  const ToggleDeltaSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class TogglePauseOnMetered extends SettingsEvent {
  final bool enabled;

  const TogglePauseOnMetered(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleWifiOnly extends SettingsEvent {
  final bool enabled;

  const ToggleWifiOnly(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleFilesystemWatch extends SettingsEvent {
  final bool enabled;

  const ToggleFilesystemWatch(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateIgnorePatterns extends SettingsEvent {
  final List<String> patterns;

  const UpdateIgnorePatterns(this.patterns);

  @override
  List<Object?> get props => [patterns];
}

class ToggleNotifications extends SettingsEvent {
  final bool enabled;

  const ToggleNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleLaunchAtStartup extends SettingsEvent {
  final bool enabled;

  const ToggleLaunchAtStartup(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleMinimizeToTray extends SettingsEvent {
  final bool enabled;

  const ToggleMinimizeToTray(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// ============================================================================
// STATES
// ============================================================================

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final SyncConfig config;
  final bool isSaving;

  const SettingsLoaded({
    required this.config,
    this.isSaving = false,
  });

  SettingsLoaded copyWith({
    SyncConfig? config,
    bool? isSaving,
  }) {
    return SettingsLoaded(
      config: config ?? this.config,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [config, isSaving];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLOC
// ============================================================================

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SyncRepository _syncRepository;

  SettingsBloc(this._syncRepository) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSyncFolder>(_onUpdateSyncFolder);
    on<UpdateSyncInterval>(_onUpdateSyncInterval);
    on<UpdateBandwidthLimits>(_onUpdateBandwidthLimits);
    on<ToggleDeltaSync>(_onToggleDeltaSync);
    on<TogglePauseOnMetered>(_onTogglePauseOnMetered);
    on<ToggleWifiOnly>(_onToggleWifiOnly);
    on<ToggleFilesystemWatch>(_onToggleFilesystemWatch);
    on<UpdateIgnorePatterns>(_onUpdateIgnorePatterns);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ToggleLaunchAtStartup>(_onToggleLaunchAtStartup);
    on<ToggleMinimizeToTray>(_onToggleMinimizeToTray);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await _syncRepository.getConfig();

    result.fold(
      (failure) => emit(SettingsError(_mapFailure(failure))),
      (config) => emit(SettingsLoaded(config: config)),
    );
  }

  Future<void> _onUpdateSyncFolder(
    UpdateSyncFolder event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: event.path,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onUpdateSyncInterval(
    UpdateSyncInterval event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: event.seconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onUpdateBandwidthLimits(
    UpdateBandwidthLimits event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: event.uploadKbps,
        maxDownloadSpeedKbps: event.downloadKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onToggleDeltaSync(
    ToggleDeltaSync event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: event.enabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onTogglePauseOnMetered(
    TogglePauseOnMetered event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: event.enabled,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onToggleWifiOnly(
    ToggleWifiOnly event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: event.enabled,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onToggleFilesystemWatch(
    ToggleFilesystemWatch event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: event.enabled,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onUpdateIgnorePatterns(
    UpdateIgnorePatterns event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: event.patterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: event.enabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onToggleLaunchAtStartup(
    ToggleLaunchAtStartup event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: event.enabled,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<void> _onToggleMinimizeToTray(
    ToggleMinimizeToTray event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateConfig(
      emit,
      (config) => SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: event.enabled,
      ),
    );
  }

  Future<void> _updateConfig(
    Emitter<SettingsState> emit,
    SyncConfig Function(SyncConfig) updater,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    final newConfig = updater(currentState.config);
    emit(currentState.copyWith(isSaving: true));

    final result = await _syncRepository.updateConfig(newConfig);

    result.fold(
      (failure) => emit(SettingsError(_mapFailure(failure))),
      (_) => emit(SettingsLoaded(config: newConfig)),
    );
  }

  String _mapFailure(SyncFailure failure) {
    if (failure is NetworkSyncFailure) {
      return 'Network error: ${failure.message}';
    } else if (failure is StorageSyncFailure) {
      return 'Storage error: ${failure.message}';
    } else if (failure is UnknownSyncFailure) {
      return 'Error: ${failure.message}';
    }
    return 'Unknown error';
  }
}
