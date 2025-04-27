import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(false) bool enableBackgroundSync,
    @Default(false) bool enableWebDAV,
    @Default(300) int syncInterval,
    @Default(false) bool autoUploadPhotos,
    @Default(false) bool autoUploadVideos,
    @Default(100) int maxUploadSize,
    @Default(false) bool enableNotifications,
    @Default(false) bool enableDarkMode,
    @Default('en') String language,
    @Default('') String webDAVUrl,
    @Default('') String webDAVUsername,
    @Default('') String webDAVPassword,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
} 