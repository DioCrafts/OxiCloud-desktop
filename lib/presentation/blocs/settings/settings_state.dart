part of 'settings_bloc.dart';

// ============================================================================
// SETTINGS STATES
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
