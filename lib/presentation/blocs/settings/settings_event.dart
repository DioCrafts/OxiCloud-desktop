part of 'settings_bloc.dart';

// ============================================================================
// SETTINGS EVENTS
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
