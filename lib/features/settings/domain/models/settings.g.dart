// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Settings _$SettingsFromJson(Map<String, dynamic> json) => _Settings(
      enableBackgroundSync: json['enableBackgroundSync'] as bool? ?? false,
      enableWebDAV: json['enableWebDAV'] as bool? ?? false,
      syncInterval: (json['syncInterval'] as num?)?.toInt() ?? 300,
      autoUploadPhotos: json['autoUploadPhotos'] as bool? ?? false,
      autoUploadVideos: json['autoUploadVideos'] as bool? ?? false,
      maxUploadSize: (json['maxUploadSize'] as num?)?.toInt() ?? 100,
      enableNotifications: json['enableNotifications'] as bool? ?? false,
      enableDarkMode: json['enableDarkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      webDAVUrl: json['webDAVUrl'] as String? ?? '',
      webDAVUsername: json['webDAVUsername'] as String? ?? '',
      webDAVPassword: json['webDAVPassword'] as String? ?? '',
    );

Map<String, dynamic> _$SettingsToJson(_Settings instance) => <String, dynamic>{
      'enableBackgroundSync': instance.enableBackgroundSync,
      'enableWebDAV': instance.enableWebDAV,
      'syncInterval': instance.syncInterval,
      'autoUploadPhotos': instance.autoUploadPhotos,
      'autoUploadVideos': instance.autoUploadVideos,
      'maxUploadSize': instance.maxUploadSize,
      'enableNotifications': instance.enableNotifications,
      'enableDarkMode': instance.enableDarkMode,
      'language': instance.language,
      'webDAVUrl': instance.webDAVUrl,
      'webDAVUsername': instance.webDAVUsername,
      'webDAVPassword': instance.webDAVPassword,
    };
