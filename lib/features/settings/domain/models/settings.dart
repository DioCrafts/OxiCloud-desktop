import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class Settings {
  final bool enableBackgroundSync;
  final bool enableWebDAV;
  final int syncInterval;
  final bool autoUploadPhotos;
  final bool autoUploadVideos;
  final int maxUploadSize;
  final bool enableNotifications;
  final bool enableDarkMode;
  final String language;
  final String webDAVUrl;
  final String webDAVUsername;
  final String webDAVPassword;

  const Settings({
    this.enableBackgroundSync = false,
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
    this.webDAVPassword = '',
  });

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);
} 