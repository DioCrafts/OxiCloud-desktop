// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Folder {
  String get id;
  String get name;
  String get path;
  DateTime get createdAt;
  DateTime get updatedAt;
  String? get parentId;
  bool get isFavorite;
  bool get isShared;
  int get itemCount;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FolderCopyWith<Folder> get copyWith =>
      _$FolderCopyWithImpl<Folder>(this as Folder, _$identity);

  /// Serializes this Folder to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Folder &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
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
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, path, createdAt,
      updatedAt, parentId, isFavorite, isShared, itemCount);

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, path: $path, createdAt: $createdAt, updatedAt: $updatedAt, parentId: $parentId, isFavorite: $isFavorite, isShared: $isShared, itemCount: $itemCount)';
  }
}

/// @nodoc
abstract mixin class $FolderCopyWith<$Res> {
  factory $FolderCopyWith(Folder value, $Res Function(Folder) _then) =
      _$FolderCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String path,
      DateTime createdAt,
      DateTime updatedAt,
      String? parentId,
      bool isFavorite,
      bool isShared,
      int itemCount});
}

/// @nodoc
class _$FolderCopyWithImpl<$Res> implements $FolderCopyWith<$Res> {
  _$FolderCopyWithImpl(this._self, this._then);

  final Folder _self;
  final $Res Function(Folder) _then;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? parentId = freezed,
    Object? isFavorite = null,
    Object? isShared = null,
    Object? itemCount = null,
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
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Folder implements Folder {
  const _Folder(
      {required this.id,
      required this.name,
      required this.path,
      required this.createdAt,
      required this.updatedAt,
      this.parentId,
      this.isFavorite = false,
      this.isShared = false,
      this.itemCount = 0});
  factory _Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
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
  @JsonKey()
  final int itemCount;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FolderCopyWith<_Folder> get copyWith =>
      __$FolderCopyWithImpl<_Folder>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FolderToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Folder &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
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
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, path, createdAt,
      updatedAt, parentId, isFavorite, isShared, itemCount);

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, path: $path, createdAt: $createdAt, updatedAt: $updatedAt, parentId: $parentId, isFavorite: $isFavorite, isShared: $isShared, itemCount: $itemCount)';
  }
}

/// @nodoc
abstract mixin class _$FolderCopyWith<$Res> implements $FolderCopyWith<$Res> {
  factory _$FolderCopyWith(_Folder value, $Res Function(_Folder) _then) =
      __$FolderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String path,
      DateTime createdAt,
      DateTime updatedAt,
      String? parentId,
      bool isFavorite,
      bool isShared,
      int itemCount});
}

/// @nodoc
class __$FolderCopyWithImpl<$Res> implements _$FolderCopyWith<$Res> {
  __$FolderCopyWithImpl(this._self, this._then);

  final _Folder _self;
  final $Res Function(_Folder) _then;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? parentId = freezed,
    Object? isFavorite = null,
    Object? isShared = null,
    Object? itemCount = null,
  }) {
    return _then(_Folder(
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
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
