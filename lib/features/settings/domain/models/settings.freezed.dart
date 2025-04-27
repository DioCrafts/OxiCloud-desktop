// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Settings {
  bool get enableBackgroundSync;
  bool get enableWebDAV;
  int get syncInterval;
  bool get autoUploadPhotos;
  bool get autoUploadVideos;
  int get maxUploadSize;
  bool get enableNotifications;
  bool get enableDarkMode;
  String get language;
  String get webDAVUrl;
  String get webDAVUsername;
  String get webDAVPassword;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SettingsCopyWith<Settings> get copyWith =>
      _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Settings &&
            (identical(other.enableBackgroundSync, enableBackgroundSync) ||
                other.enableBackgroundSync == enableBackgroundSync) &&
            (identical(other.enableWebDAV, enableWebDAV) ||
                other.enableWebDAV == enableWebDAV) &&
            (identical(other.syncInterval, syncInterval) ||
                other.syncInterval == syncInterval) &&
            (identical(other.autoUploadPhotos, autoUploadPhotos) ||
                other.autoUploadPhotos == autoUploadPhotos) &&
            (identical(other.autoUploadVideos, autoUploadVideos) ||
                other.autoUploadVideos == autoUploadVideos) &&
            (identical(other.maxUploadSize, maxUploadSize) ||
                other.maxUploadSize == maxUploadSize) &&
            (identical(other.enableNotifications, enableNotifications) ||
                other.enableNotifications == enableNotifications) &&
            (identical(other.enableDarkMode, enableDarkMode) ||
                other.enableDarkMode == enableDarkMode) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.webDAVUrl, webDAVUrl) ||
                other.webDAVUrl == webDAVUrl) &&
            (identical(other.webDAVUsername, webDAVUsername) ||
                other.webDAVUsername == webDAVUsername) &&
            (identical(other.webDAVPassword, webDAVPassword) ||
                other.webDAVPassword == webDAVPassword));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      enableBackgroundSync,
      enableWebDAV,
      syncInterval,
      autoUploadPhotos,
      autoUploadVideos,
      maxUploadSize,
      enableNotifications,
      enableDarkMode,
      language,
      webDAVUrl,
      webDAVUsername,
      webDAVPassword);

  @override
  String toString() {
    return 'Settings(enableBackgroundSync: $enableBackgroundSync, enableWebDAV: $enableWebDAV, syncInterval: $syncInterval, autoUploadPhotos: $autoUploadPhotos, autoUploadVideos: $autoUploadVideos, maxUploadSize: $maxUploadSize, enableNotifications: $enableNotifications, enableDarkMode: $enableDarkMode, language: $language, webDAVUrl: $webDAVUrl, webDAVUsername: $webDAVUsername, webDAVPassword: $webDAVPassword)';
  }
}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) =
      _$SettingsCopyWithImpl;
  @useResult
  $Res call(
      {bool enableBackgroundSync,
      bool enableWebDAV,
      int syncInterval,
      bool autoUploadPhotos,
      bool autoUploadVideos,
      int maxUploadSize,
      bool enableNotifications,
      bool enableDarkMode,
      String language,
      String webDAVUrl,
      String webDAVUsername,
      String webDAVPassword});
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res> implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enableBackgroundSync = null,
    Object? enableWebDAV = null,
    Object? syncInterval = null,
    Object? autoUploadPhotos = null,
    Object? autoUploadVideos = null,
    Object? maxUploadSize = null,
    Object? enableNotifications = null,
    Object? enableDarkMode = null,
    Object? language = null,
    Object? webDAVUrl = null,
    Object? webDAVUsername = null,
    Object? webDAVPassword = null,
  }) {
    return _then(_self.copyWith(
      enableBackgroundSync: null == enableBackgroundSync
          ? _self.enableBackgroundSync
          : enableBackgroundSync // ignore: cast_nullable_to_non_nullable
              as bool,
      enableWebDAV: null == enableWebDAV
          ? _self.enableWebDAV
          : enableWebDAV // ignore: cast_nullable_to_non_nullable
              as bool,
      syncInterval: null == syncInterval
          ? _self.syncInterval
          : syncInterval // ignore: cast_nullable_to_non_nullable
              as int,
      autoUploadPhotos: null == autoUploadPhotos
          ? _self.autoUploadPhotos
          : autoUploadPhotos // ignore: cast_nullable_to_non_nullable
              as bool,
      autoUploadVideos: null == autoUploadVideos
          ? _self.autoUploadVideos
          : autoUploadVideos // ignore: cast_nullable_to_non_nullable
              as bool,
      maxUploadSize: null == maxUploadSize
          ? _self.maxUploadSize
          : maxUploadSize // ignore: cast_nullable_to_non_nullable
              as int,
      enableNotifications: null == enableNotifications
          ? _self.enableNotifications
          : enableNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      enableDarkMode: null == enableDarkMode
          ? _self.enableDarkMode
          : enableDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      webDAVUrl: null == webDAVUrl
          ? _self.webDAVUrl
          : webDAVUrl // ignore: cast_nullable_to_non_nullable
              as String,
      webDAVUsername: null == webDAVUsername
          ? _self.webDAVUsername
          : webDAVUsername // ignore: cast_nullable_to_non_nullable
              as String,
      webDAVPassword: null == webDAVPassword
          ? _self.webDAVPassword
          : webDAVPassword // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Settings implements Settings {
  const _Settings(
      {this.enableBackgroundSync = false,
      this.enableWebDAV = false,
      this.syncInterval = 300,
      this.autoUploadPhotos = false,
      this.autoUploadVideos = false,
      this.maxUploadSize = 100,
      this.enableNotifications = false,
      this.enableDarkMode = false,
      this.language = 'en',
      this.webDAVUrl = '',
      this.webDAVUsername = '',
      this.webDAVPassword = ''});
  factory _Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  @override
  @JsonKey()
  final bool enableBackgroundSync;
  @override
  @JsonKey()
  final bool enableWebDAV;
  @override
  @JsonKey()
  final int syncInterval;
  @override
  @JsonKey()
  final bool autoUploadPhotos;
  @override
  @JsonKey()
  final bool autoUploadVideos;
  @override
  @JsonKey()
  final int maxUploadSize;
  @override
  @JsonKey()
  final bool enableNotifications;
  @override
  @JsonKey()
  final bool enableDarkMode;
  @override
  @JsonKey()
  final String language;
  @override
  @JsonKey()
  final String webDAVUrl;
  @override
  @JsonKey()
  final String webDAVUsername;
  @override
  @JsonKey()
  final String webDAVPassword;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SettingsCopyWith<_Settings> get copyWith =>
      __$SettingsCopyWithImpl<_Settings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Settings &&
            (identical(other.enableBackgroundSync, enableBackgroundSync) ||
                other.enableBackgroundSync == enableBackgroundSync) &&
            (identical(other.enableWebDAV, enableWebDAV) ||
                other.enableWebDAV == enableWebDAV) &&
            (identical(other.syncInterval, syncInterval) ||
                other.syncInterval == syncInterval) &&
            (identical(other.autoUploadPhotos, autoUploadPhotos) ||
                other.autoUploadPhotos == autoUploadPhotos) &&
            (identical(other.autoUploadVideos, autoUploadVideos) ||
                other.autoUploadVideos == autoUploadVideos) &&
            (identical(other.maxUploadSize, maxUploadSize) ||
                other.maxUploadSize == maxUploadSize) &&
            (identical(other.enableNotifications, enableNotifications) ||
                other.enableNotifications == enableNotifications) &&
            (identical(other.enableDarkMode, enableDarkMode) ||
                other.enableDarkMode == enableDarkMode) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.webDAVUrl, webDAVUrl) ||
                other.webDAVUrl == webDAVUrl) &&
            (identical(other.webDAVUsername, webDAVUsername) ||
                other.webDAVUsername == webDAVUsername) &&
            (identical(other.webDAVPassword, webDAVPassword) ||
                other.webDAVPassword == webDAVPassword));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      enableBackgroundSync,
      enableWebDAV,
      syncInterval,
      autoUploadPhotos,
      autoUploadVideos,
      maxUploadSize,
      enableNotifications,
      enableDarkMode,
      language,
      webDAVUrl,
      webDAVUsername,
      webDAVPassword);

  @override
  String toString() {
    return 'Settings(enableBackgroundSync: $enableBackgroundSync, enableWebDAV: $enableWebDAV, syncInterval: $syncInterval, autoUploadPhotos: $autoUploadPhotos, autoUploadVideos: $autoUploadVideos, maxUploadSize: $maxUploadSize, enableNotifications: $enableNotifications, enableDarkMode: $enableDarkMode, language: $language, webDAVUrl: $webDAVUrl, webDAVUsername: $webDAVUsername, webDAVPassword: $webDAVPassword)';
  }
}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res>
    implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) =
      __$SettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool enableBackgroundSync,
      bool enableWebDAV,
      int syncInterval,
      bool autoUploadPhotos,
      bool autoUploadVideos,
      int maxUploadSize,
      bool enableNotifications,
      bool enableDarkMode,
      String language,
      String webDAVUrl,
      String webDAVUsername,
      String webDAVPassword});
}

/// @nodoc
class __$SettingsCopyWithImpl<$Res> implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enableBackgroundSync = null,
    Object? enableWebDAV = null,
    Object? syncInterval = null,
    Object? autoUploadPhotos = null,
    Object? autoUploadVideos = null,
    Object? maxUploadSize = null,
    Object? enableNotifications = null,
    Object? enableDarkMode = null,
    Object? language = null,
    Object? webDAVUrl = null,
    Object? webDAVUsername = null,
    Object? webDAVPassword = null,
  }) {
    return _then(_Settings(
      enableBackgroundSync: null == enableBackgroundSync
          ? _self.enableBackgroundSync
          : enableBackgroundSync // ignore: cast_nullable_to_non_nullable
              as bool,
      enableWebDAV: null == enableWebDAV
          ? _self.enableWebDAV
          : enableWebDAV // ignore: cast_nullable_to_non_nullable
              as bool,
      syncInterval: null == syncInterval
          ? _self.syncInterval
          : syncInterval // ignore: cast_nullable_to_non_nullable
              as int,
      autoUploadPhotos: null == autoUploadPhotos
          ? _self.autoUploadPhotos
          : autoUploadPhotos // ignore: cast_nullable_to_non_nullable
              as bool,
      autoUploadVideos: null == autoUploadVideos
          ? _self.autoUploadVideos
          : autoUploadVideos // ignore: cast_nullable_to_non_nullable
              as bool,
      maxUploadSize: null == maxUploadSize
          ? _self.maxUploadSize
          : maxUploadSize // ignore: cast_nullable_to_non_nullable
              as int,
      enableNotifications: null == enableNotifications
          ? _self.enableNotifications
          : enableNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      enableDarkMode: null == enableDarkMode
          ? _self.enableDarkMode
          : enableDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      webDAVUrl: null == webDAVUrl
          ? _self.webDAVUrl
          : webDAVUrl // ignore: cast_nullable_to_non_nullable
              as String,
      webDAVUsername: null == webDAVUsername
          ? _self.webDAVUsername
          : webDAVUsername // ignore: cast_nullable_to_non_nullable
              as String,
      webDAVPassword: null == webDAVPassword
          ? _self.webDAVPassword
          : webDAVPassword // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
