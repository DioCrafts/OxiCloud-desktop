// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$File {
  String get id;
  String get name;
  String get path;
  int get size;
  String get mimeType;
  DateTime get createdAt;
  DateTime get updatedAt;
  String? get parentId;
  bool get isFavorite;
  bool get isShared;
  String? get thumbnailUrl;
  String? get downloadUrl;

  /// Create a copy of File
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FileCopyWith<File> get copyWith =>
      _$FileCopyWithImpl<File>(this as File, _$identity);

  /// Serializes this File to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is File &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      path,
      size,
      mimeType,
      createdAt,
      updatedAt,
      parentId,
      isFavorite,
      isShared,
      thumbnailUrl,
      downloadUrl);

  @override
  String toString() {
    return 'File(id: $id, name: $name, path: $path, size: $size, mimeType: $mimeType, createdAt: $createdAt, updatedAt: $updatedAt, parentId: $parentId, isFavorite: $isFavorite, isShared: $isShared, thumbnailUrl: $thumbnailUrl, downloadUrl: $downloadUrl)';
  }
}

/// @nodoc
abstract mixin class $FileCopyWith<$Res> {
  factory $FileCopyWith(File value, $Res Function(File) _then) =
      _$FileCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String path,
      int size,
      String mimeType,
      DateTime createdAt,
      DateTime updatedAt,
      String? parentId,
      bool isFavorite,
      bool isShared,
      String? thumbnailUrl,
      String? downloadUrl});
}

/// @nodoc
class _$FileCopyWithImpl<$Res> implements $FileCopyWith<$Res> {
  _$FileCopyWithImpl(this._self, this._then);

  final File _self;
  final $Res Function(File) _then;

  /// Create a copy of File
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? size = null,
    Object? mimeType = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? parentId = freezed,
    Object? isFavorite = null,
    Object? isShared = null,
    Object? thumbnailUrl = freezed,
    Object? downloadUrl = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      mimeType: null == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      thumbnailUrl: freezed == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadUrl: freezed == downloadUrl
          ? _self.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _File implements File {
  const _File(
      {required this.id,
      required this.name,
      required this.path,
      required this.size,
      required this.mimeType,
      required this.createdAt,
      required this.updatedAt,
      this.parentId,
      this.isFavorite = false,
      this.isShared = false,
      this.thumbnailUrl,
      this.downloadUrl});
  factory _File.fromJson(Map<String, dynamic> json) => _$FileFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  @override
  final int size;
  @override
  final String mimeType;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? parentId;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  @JsonKey()
  final bool isShared;
  @override
  final String? thumbnailUrl;
  @override
  final String? downloadUrl;

  /// Create a copy of File
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FileCopyWith<_File> get copyWith =>
      __$FileCopyWithImpl<_File>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _File &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      path,
      size,
      mimeType,
      createdAt,
      updatedAt,
      parentId,
      isFavorite,
      isShared,
      thumbnailUrl,
      downloadUrl);

  @override
  String toString() {
    return 'File(id: $id, name: $name, path: $path, size: $size, mimeType: $mimeType, createdAt: $createdAt, updatedAt: $updatedAt, parentId: $parentId, isFavorite: $isFavorite, isShared: $isShared, thumbnailUrl: $thumbnailUrl, downloadUrl: $downloadUrl)';
  }
}

/// @nodoc
abstract mixin class _$FileCopyWith<$Res> implements $FileCopyWith<$Res> {
  factory _$FileCopyWith(_File value, $Res Function(_File) _then) =
      __$FileCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String path,
      int size,
      String mimeType,
      DateTime createdAt,
      DateTime updatedAt,
      String? parentId,
      bool isFavorite,
      bool isShared,
      String? thumbnailUrl,
      String? downloadUrl});
}

/// @nodoc
class __$FileCopyWithImpl<$Res> implements _$FileCopyWith<$Res> {
  __$FileCopyWithImpl(this._self, this._then);

  final _File _self;
  final $Res Function(_File) _then;

  /// Create a copy of File
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? size = null,
    Object? mimeType = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? parentId = freezed,
    Object? isFavorite = null,
    Object? isShared = null,
    Object? thumbnailUrl = freezed,
    Object? downloadUrl = freezed,
  }) {
    return _then(_File(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      mimeType: null == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      thumbnailUrl: freezed == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadUrl: freezed == downloadUrl
          ? _self.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
