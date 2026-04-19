// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FilesTableTable extends FilesTable
    with TableInfo<$FilesTableTable, FilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAvailableOfflineMeta =
      const VerificationMeta('isAvailableOffline');
  @override
  late final GeneratedColumn<bool> isAvailableOffline = GeneratedColumn<bool>(
    'is_available_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localCachePathMeta = const VerificationMeta(
    'localCachePath',
  );
  @override
  late final GeneratedColumn<String> localCachePath = GeneratedColumn<String>(
    'local_cache_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    path,
    size,
    mimeType,
    folderId,
    ownerId,
    hash,
    etag,
    createdAt,
    modifiedAt,
    syncedAt,
    isFavorite,
    isAvailableOffline,
    localCachePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'files';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_available_offline')) {
      context.handle(
        _isAvailableOfflineMeta,
        isAvailableOffline.isAcceptableOrUnknown(
          data['is_available_offline']!,
          _isAvailableOfflineMeta,
        ),
      );
    }
    if (data.containsKey('local_cache_path')) {
      context.handle(
        _localCachePathMeta,
        localCachePath.isAcceptableOrUnknown(
          data['local_cache_path']!,
          _localCachePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isAvailableOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available_offline'],
      )!,
      localCachePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_cache_path'],
      ),
    );
  }

  @override
  $FilesTableTable createAlias(String alias) {
    return $FilesTableTable(attachedDatabase, alias);
  }
}

class FilesTableData extends DataClass implements Insertable<FilesTableData> {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final String? folderId;
  final String? ownerId;
  final String? hash;
  final String? etag;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? syncedAt;
  final bool isFavorite;
  final bool isAvailableOffline;
  final String? localCachePath;
  const FilesTableData({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.folderId,
    this.ownerId,
    this.hash,
    this.etag,
    required this.createdAt,
    required this.modifiedAt,
    this.syncedAt,
    required this.isFavorite,
    required this.isAvailableOffline,
    this.localCachePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    map['size'] = Variable<int>(size);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_available_offline'] = Variable<bool>(isAvailableOffline);
    if (!nullToAbsent || localCachePath != null) {
      map['local_cache_path'] = Variable<String>(localCachePath);
    }
    return map;
  }

  FilesTableCompanion toCompanion(bool nullToAbsent) {
    return FilesTableCompanion(
      id: Value(id),
      name: Value(name),
      path: Value(path),
      size: Value(size),
      mimeType: Value(mimeType),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      isFavorite: Value(isFavorite),
      isAvailableOffline: Value(isAvailableOffline),
      localCachePath: localCachePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localCachePath),
    );
  }

  factory FilesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      size: serializer.fromJson<int>(json['size']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      hash: serializer.fromJson<String?>(json['hash']),
      etag: serializer.fromJson<String?>(json['etag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isAvailableOffline: serializer.fromJson<bool>(json['isAvailableOffline']),
      localCachePath: serializer.fromJson<String?>(json['localCachePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'size': serializer.toJson<int>(size),
      'mimeType': serializer.toJson<String>(mimeType),
      'folderId': serializer.toJson<String?>(folderId),
      'ownerId': serializer.toJson<String?>(ownerId),
      'hash': serializer.toJson<String?>(hash),
      'etag': serializer.toJson<String?>(etag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isAvailableOffline': serializer.toJson<bool>(isAvailableOffline),
      'localCachePath': serializer.toJson<String?>(localCachePath),
    };
  }

  FilesTableData copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    String? mimeType,
    Value<String?> folderId = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> hash = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    bool? isFavorite,
    bool? isAvailableOffline,
    Value<String?> localCachePath = const Value.absent(),
  }) => FilesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    path: path ?? this.path,
    size: size ?? this.size,
    mimeType: mimeType ?? this.mimeType,
    folderId: folderId.present ? folderId.value : this.folderId,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    hash: hash.present ? hash.value : this.hash,
    etag: etag.present ? etag.value : this.etag,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
    localCachePath: localCachePath.present
        ? localCachePath.value
        : this.localCachePath,
  );
  FilesTableData copyWithCompanion(FilesTableCompanion data) {
    return FilesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      size: data.size.present ? data.size.value : this.size,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      hash: data.hash.present ? data.hash.value : this.hash,
      etag: data.etag.present ? data.etag.value : this.etag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isAvailableOffline: data.isAvailableOffline.present
          ? data.isAvailableOffline.value
          : this.isAvailableOffline,
      localCachePath: data.localCachePath.present
          ? data.localCachePath.value
          : this.localCachePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('mimeType: $mimeType, ')
          ..write('folderId: $folderId, ')
          ..write('ownerId: $ownerId, ')
          ..write('hash: $hash, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isAvailableOffline: $isAvailableOffline, ')
          ..write('localCachePath: $localCachePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    path,
    size,
    mimeType,
    folderId,
    ownerId,
    hash,
    etag,
    createdAt,
    modifiedAt,
    syncedAt,
    isFavorite,
    isAvailableOffline,
    localCachePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.path == this.path &&
          other.size == this.size &&
          other.mimeType == this.mimeType &&
          other.folderId == this.folderId &&
          other.ownerId == this.ownerId &&
          other.hash == this.hash &&
          other.etag == this.etag &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.syncedAt == this.syncedAt &&
          other.isFavorite == this.isFavorite &&
          other.isAvailableOffline == this.isAvailableOffline &&
          other.localCachePath == this.localCachePath);
}

class FilesTableCompanion extends UpdateCompanion<FilesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> path;
  final Value<int> size;
  final Value<String> mimeType;
  final Value<String?> folderId;
  final Value<String?> ownerId;
  final Value<String?> hash;
  final Value<String?> etag;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<DateTime?> syncedAt;
  final Value<bool> isFavorite;
  final Value<bool> isAvailableOffline;
  final Value<String?> localCachePath;
  final Value<int> rowid;
  const FilesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.folderId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.hash = const Value.absent(),
    this.etag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isAvailableOffline = const Value.absent(),
    this.localCachePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilesTableCompanion.insert({
    required String id,
    required String name,
    required String path,
    required int size,
    required String mimeType,
    this.folderId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.hash = const Value.absent(),
    this.etag = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.syncedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isAvailableOffline = const Value.absent(),
    this.localCachePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       path = Value(path),
       size = Value(size),
       mimeType = Value(mimeType),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<FilesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? path,
    Expression<int>? size,
    Expression<String>? mimeType,
    Expression<String>? folderId,
    Expression<String>? ownerId,
    Expression<String>? hash,
    Expression<String>? etag,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? syncedAt,
    Expression<bool>? isFavorite,
    Expression<bool>? isAvailableOffline,
    Expression<String>? localCachePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (size != null) 'size': size,
      if (mimeType != null) 'mime_type': mimeType,
      if (folderId != null) 'folder_id': folderId,
      if (ownerId != null) 'owner_id': ownerId,
      if (hash != null) 'hash': hash,
      if (etag != null) 'etag': etag,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isAvailableOffline != null)
        'is_available_offline': isAvailableOffline,
      if (localCachePath != null) 'local_cache_path': localCachePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? path,
    Value<int>? size,
    Value<String>? mimeType,
    Value<String?>? folderId,
    Value<String?>? ownerId,
    Value<String?>? hash,
    Value<String?>? etag,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<DateTime?>? syncedAt,
    Value<bool>? isFavorite,
    Value<bool>? isAvailableOffline,
    Value<String?>? localCachePath,
    Value<int>? rowid,
  }) {
    return FilesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      folderId: folderId ?? this.folderId,
      ownerId: ownerId ?? this.ownerId,
      hash: hash ?? this.hash,
      etag: etag ?? this.etag,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
      localCachePath: localCachePath ?? this.localCachePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isAvailableOffline.present) {
      map['is_available_offline'] = Variable<bool>(isAvailableOffline.value);
    }
    if (localCachePath.present) {
      map['local_cache_path'] = Variable<String>(localCachePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('mimeType: $mimeType, ')
          ..write('folderId: $folderId, ')
          ..write('ownerId: $ownerId, ')
          ..write('hash: $hash, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isAvailableOffline: $isAvailableOffline, ')
          ..write('localCachePath: $localCachePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTableTable extends FoldersTable
    with TableInfo<$FoldersTableTable, FoldersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRootMeta = const VerificationMeta('isRoot');
  @override
  late final GeneratedColumn<bool> isRoot = GeneratedColumn<bool>(
    'is_root',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_root" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    path,
    parentId,
    ownerId,
    isRoot,
    createdAt,
    modifiedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoldersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('is_root')) {
      context.handle(
        _isRootMeta,
        isRoot.isAcceptableOrUnknown(data['is_root']!, _isRootMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoldersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoldersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      isRoot: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_root'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $FoldersTableTable createAlias(String alias) {
    return $FoldersTableTable(attachedDatabase, alias);
  }
}

class FoldersTableData extends DataClass
    implements Insertable<FoldersTableData> {
  final String id;
  final String name;
  final String path;
  final String? parentId;
  final String? ownerId;
  final bool isRoot;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? syncedAt;
  const FoldersTableData({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    this.ownerId,
    required this.isRoot,
    required this.createdAt,
    required this.modifiedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['is_root'] = Variable<bool>(isRoot);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  FoldersTableCompanion toCompanion(bool nullToAbsent) {
    return FoldersTableCompanion(
      id: Value(id),
      name: Value(name),
      path: Value(path),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      isRoot: Value(isRoot),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory FoldersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoldersTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      isRoot: serializer.fromJson<bool>(json['isRoot']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'parentId': serializer.toJson<String?>(parentId),
      'ownerId': serializer.toJson<String?>(ownerId),
      'isRoot': serializer.toJson<bool>(isRoot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  FoldersTableData copyWith({
    String? id,
    String? name,
    String? path,
    Value<String?> parentId = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    bool? isRoot,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => FoldersTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    path: path ?? this.path,
    parentId: parentId.present ? parentId.value : this.parentId,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    isRoot: isRoot ?? this.isRoot,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  FoldersTableData copyWithCompanion(FoldersTableCompanion data) {
    return FoldersTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      isRoot: data.isRoot.present ? data.isRoot.value : this.isRoot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoldersTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('parentId: $parentId, ')
          ..write('ownerId: $ownerId, ')
          ..write('isRoot: $isRoot, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    path,
    parentId,
    ownerId,
    isRoot,
    createdAt,
    modifiedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoldersTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.path == this.path &&
          other.parentId == this.parentId &&
          other.ownerId == this.ownerId &&
          other.isRoot == this.isRoot &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.syncedAt == this.syncedAt);
}

class FoldersTableCompanion extends UpdateCompanion<FoldersTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> path;
  final Value<String?> parentId;
  final Value<String?> ownerId;
  final Value<bool> isRoot;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const FoldersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.parentId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.isRoot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersTableCompanion.insert({
    required String id,
    required String name,
    required String path,
    this.parentId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.isRoot = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       path = Value(path),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<FoldersTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? path,
    Expression<String>? parentId,
    Expression<String>? ownerId,
    Expression<bool>? isRoot,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (parentId != null) 'parent_id': parentId,
      if (ownerId != null) 'owner_id': ownerId,
      if (isRoot != null) 'is_root': isRoot,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? path,
    Value<String?>? parentId,
    Value<String?>? ownerId,
    Value<bool>? isRoot,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return FoldersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      parentId: parentId ?? this.parentId,
      ownerId: ownerId ?? this.ownerId,
      isRoot: isRoot ?? this.isRoot,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (isRoot.present) {
      map['is_root'] = Variable<bool>(isRoot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('parentId: $parentId, ')
          ..write('ownerId: $ownerId, ')
          ..write('isRoot: $isRoot, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    status,
    itemId,
    itemType,
    payload,
    retryCount,
    errorMessage,
    createdAt,
    updatedAt,
    scheduledAt,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String operationType;
  final String status;
  final String itemId;
  final String itemType;
  final String payload;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;
  final int priority;
  const SyncQueueTableData({
    required this.id,
    required this.operationType,
    required this.status,
    required this.itemId,
    required this.itemType,
    required this.payload,
    required this.retryCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['status'] = Variable<String>(status);
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || scheduledAt != null) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    }
    map['priority'] = Variable<int>(priority);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      operationType: Value(operationType),
      status: Value(status),
      itemId: Value(itemId),
      itemType: Value(itemType),
      payload: Value(payload),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      scheduledAt: scheduledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledAt),
      priority: Value(priority),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      status: serializer.fromJson<String>(json['status']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      scheduledAt: serializer.fromJson<DateTime?>(json['scheduledAt']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationType': serializer.toJson<String>(operationType),
      'status': serializer.toJson<String>(status),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'scheduledAt': serializer.toJson<DateTime?>(scheduledAt),
      'priority': serializer.toJson<int>(priority),
    };
  }

  SyncQueueTableData copyWith({
    int? id,
    String? operationType,
    String? status,
    String? itemId,
    String? itemType,
    String? payload,
    int? retryCount,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> scheduledAt = const Value.absent(),
    int? priority,
  }) => SyncQueueTableData(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    status: status ?? this.status,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    payload: payload ?? this.payload,
    retryCount: retryCount ?? this.retryCount,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    scheduledAt: scheduledAt.present ? scheduledAt.value : this.scheduledAt,
    priority: priority ?? this.priority,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      status: data.status.present ? data.status.value : this.status,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('status: $status, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    status,
    itemId,
    itemType,
    payload,
    retryCount,
    errorMessage,
    createdAt,
    updatedAt,
    scheduledAt,
    priority,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.status == this.status &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.scheduledAt == this.scheduledAt &&
          other.priority == this.priority);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> operationType;
  final Value<String> status;
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<String> payload;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> scheduledAt;
  final Value<int> priority;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.status = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.priority = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String operationType,
    this.status = const Value.absent(),
    required String itemId,
    required String itemType,
    required String payload,
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.scheduledAt = const Value.absent(),
    this.priority = const Value.absent(),
  }) : operationType = Value(operationType),
       itemId = Value(itemId),
       itemType = Value(itemType),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? operationType,
    Expression<String>? status,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? scheduledAt,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (status != null) 'status': status,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (priority != null) 'priority': priority,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? operationType,
    Value<String>? status,
    Value<String>? itemId,
    Value<String>? itemType,
    Value<String>? payload,
    Value<int>? retryCount,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? scheduledAt,
    Value<int>? priority,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      status: status ?? this.status,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('status: $status, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTableTable extends SyncConflictsTable
    with TableInfo<$SyncConflictsTableTable, SyncConflictsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conflictTypeMeta = const VerificationMeta(
    'conflictType',
  );
  @override
  late final GeneratedColumn<String> conflictType = GeneratedColumn<String>(
    'conflict_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('retry_exhausted'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    itemType,
    operationType,
    conflictType,
    payload,
    errorMessage,
    resolution,
    resolvedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflictsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('conflict_type')) {
      context.handle(
        _conflictTypeMeta,
        conflictType.isAcceptableOrUnknown(
          data['conflict_type']!,
          _conflictTypeMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflictsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      conflictType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncConflictsTableTable createAlias(String alias) {
    return $SyncConflictsTableTable(attachedDatabase, alias);
  }
}

class SyncConflictsTableData extends DataClass
    implements Insertable<SyncConflictsTableData> {
  final int id;
  final String itemId;
  final String itemType;
  final String operationType;
  final String conflictType;
  final String payload;
  final String? errorMessage;
  final String? resolution;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  const SyncConflictsTableData({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.operationType,
    required this.conflictType,
    required this.payload,
    this.errorMessage,
    this.resolution,
    this.resolvedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    map['operation_type'] = Variable<String>(operationType);
    map['conflict_type'] = Variable<String>(conflictType);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncConflictsTableCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsTableCompanion(
      id: Value(id),
      itemId: Value(itemId),
      itemType: Value(itemType),
      operationType: Value(operationType),
      conflictType: Value(conflictType),
      payload: Value(payload),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      createdAt: Value(createdAt),
    );
  }

  factory SyncConflictsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictsTableData(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      operationType: serializer.fromJson<String>(json['operationType']),
      conflictType: serializer.fromJson<String>(json['conflictType']),
      payload: serializer.fromJson<String>(json['payload']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      resolution: serializer.fromJson<String?>(json['resolution']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'operationType': serializer.toJson<String>(operationType),
      'conflictType': serializer.toJson<String>(conflictType),
      'payload': serializer.toJson<String>(payload),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'resolution': serializer.toJson<String?>(resolution),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncConflictsTableData copyWith({
    int? id,
    String? itemId,
    String? itemType,
    String? operationType,
    String? conflictType,
    String? payload,
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> resolution = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
    DateTime? createdAt,
  }) => SyncConflictsTableData(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    operationType: operationType ?? this.operationType,
    conflictType: conflictType ?? this.conflictType,
    payload: payload ?? this.payload,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    resolution: resolution.present ? resolution.value : this.resolution,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncConflictsTableData copyWithCompanion(SyncConflictsTableCompanion data) {
    return SyncConflictsTableData(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      conflictType: data.conflictType.present
          ? data.conflictType.value
          : this.conflictType,
      payload: data.payload.present ? data.payload.value : this.payload,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsTableData(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('operationType: $operationType, ')
          ..write('conflictType: $conflictType, ')
          ..write('payload: $payload, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    itemType,
    operationType,
    conflictType,
    payload,
    errorMessage,
    resolution,
    resolvedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictsTableData &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.operationType == this.operationType &&
          other.conflictType == this.conflictType &&
          other.payload == this.payload &&
          other.errorMessage == this.errorMessage &&
          other.resolution == this.resolution &&
          other.resolvedAt == this.resolvedAt &&
          other.createdAt == this.createdAt);
}

class SyncConflictsTableCompanion
    extends UpdateCompanion<SyncConflictsTableData> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<String> operationType;
  final Value<String> conflictType;
  final Value<String> payload;
  final Value<String?> errorMessage;
  final Value<String?> resolution;
  final Value<DateTime?> resolvedAt;
  final Value<DateTime> createdAt;
  const SyncConflictsTableCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.operationType = const Value.absent(),
    this.conflictType = const Value.absent(),
    this.payload = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncConflictsTableCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String itemType,
    required String operationType,
    this.conflictType = const Value.absent(),
    required String payload,
    this.errorMessage = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    required DateTime createdAt,
  }) : itemId = Value(itemId),
       itemType = Value(itemType),
       operationType = Value(operationType),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncConflictsTableData> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<String>? operationType,
    Expression<String>? conflictType,
    Expression<String>? payload,
    Expression<String>? errorMessage,
    Expression<String>? resolution,
    Expression<DateTime>? resolvedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (operationType != null) 'operation_type': operationType,
      if (conflictType != null) 'conflict_type': conflictType,
      if (payload != null) 'payload': payload,
      if (errorMessage != null) 'error_message': errorMessage,
      if (resolution != null) 'resolution': resolution,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncConflictsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? itemType,
    Value<String>? operationType,
    Value<String>? conflictType,
    Value<String>? payload,
    Value<String?>? errorMessage,
    Value<String?>? resolution,
    Value<DateTime?>? resolvedAt,
    Value<DateTime>? createdAt,
  }) {
    return SyncConflictsTableCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      operationType: operationType ?? this.operationType,
      conflictType: conflictType ?? this.conflictType,
      payload: payload ?? this.payload,
      errorMessage: errorMessage ?? this.errorMessage,
      resolution: resolution ?? this.resolution,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (conflictType.present) {
      map['conflict_type'] = Variable<String>(conflictType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsTableCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('operationType: $operationType, ')
          ..write('conflictType: $conflictType, ')
          ..write('payload: $payload, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CachedFilesTableTable extends CachedFilesTable
    with TableInfo<$CachedFilesTableTable, CachedFilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    fileId,
    localPath,
    sizeBytes,
    hash,
    cachedAt,
    lastAccessedAt,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFilesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  CachedFilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFilesTableData(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $CachedFilesTableTable createAlias(String alias) {
    return $CachedFilesTableTable(attachedDatabase, alias);
  }
}

class CachedFilesTableData extends DataClass
    implements Insertable<CachedFilesTableData> {
  final String fileId;
  final String localPath;
  final int sizeBytes;
  final String? hash;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;
  final bool isPinned;
  const CachedFilesTableData({
    required this.fileId,
    required this.localPath,
    required this.sizeBytes,
    this.hash,
    required this.cachedAt,
    required this.lastAccessedAt,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['local_path'] = Variable<String>(localPath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  CachedFilesTableCompanion toCompanion(bool nullToAbsent) {
    return CachedFilesTableCompanion(
      fileId: Value(fileId),
      localPath: Value(localPath),
      sizeBytes: Value(sizeBytes),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      cachedAt: Value(cachedAt),
      lastAccessedAt: Value(lastAccessedAt),
      isPinned: Value(isPinned),
    );
  }

  factory CachedFilesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFilesTableData(
      fileId: serializer.fromJson<String>(json['fileId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      hash: serializer.fromJson<String?>(json['hash']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'localPath': serializer.toJson<String>(localPath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'hash': serializer.toJson<String?>(hash),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  CachedFilesTableData copyWith({
    String? fileId,
    String? localPath,
    int? sizeBytes,
    Value<String?> hash = const Value.absent(),
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
    bool? isPinned,
  }) => CachedFilesTableData(
    fileId: fileId ?? this.fileId,
    localPath: localPath ?? this.localPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    hash: hash.present ? hash.value : this.hash,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    isPinned: isPinned ?? this.isPinned,
  );
  CachedFilesTableData copyWithCompanion(CachedFilesTableCompanion data) {
    return CachedFilesTableData(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      hash: data.hash.present ? data.hash.value : this.hash,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFilesTableData(')
          ..write('fileId: $fileId, ')
          ..write('localPath: $localPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('hash: $hash, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fileId,
    localPath,
    sizeBytes,
    hash,
    cachedAt,
    lastAccessedAt,
    isPinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFilesTableData &&
          other.fileId == this.fileId &&
          other.localPath == this.localPath &&
          other.sizeBytes == this.sizeBytes &&
          other.hash == this.hash &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.isPinned == this.isPinned);
}

class CachedFilesTableCompanion extends UpdateCompanion<CachedFilesTableData> {
  final Value<String> fileId;
  final Value<String> localPath;
  final Value<int> sizeBytes;
  final Value<String?> hash;
  final Value<DateTime> cachedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<bool> isPinned;
  final Value<int> rowid;
  const CachedFilesTableCompanion({
    this.fileId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.hash = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFilesTableCompanion.insert({
    required String fileId,
    required String localPath,
    required int sizeBytes,
    this.hash = const Value.absent(),
    required DateTime cachedAt,
    required DateTime lastAccessedAt,
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       localPath = Value(localPath),
       sizeBytes = Value(sizeBytes),
       cachedAt = Value(cachedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<CachedFilesTableData> custom({
    Expression<String>? fileId,
    Expression<String>? localPath,
    Expression<int>? sizeBytes,
    Expression<String>? hash,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<bool>? isPinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (localPath != null) 'local_path': localPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (hash != null) 'hash': hash,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFilesTableCompanion copyWith({
    Value<String>? fileId,
    Value<String>? localPath,
    Value<int>? sizeBytes,
    Value<String?>? hash,
    Value<DateTime>? cachedAt,
    Value<DateTime>? lastAccessedAt,
    Value<bool>? isPinned,
    Value<int>? rowid,
  }) {
    return CachedFilesTableCompanion(
      fileId: fileId ?? this.fileId,
      localPath: localPath ?? this.localPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      hash: hash ?? this.hash,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFilesTableCompanion(')
          ..write('fileId: $fileId, ')
          ..write('localPath: $localPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('hash: $hash, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTableTable extends UserTable
    with TableInfo<$UserTableTable, UserTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _storageQuotaBytesMeta = const VerificationMeta(
    'storageQuotaBytes',
  );
  @override
  late final GeneratedColumn<int> storageQuotaBytes = GeneratedColumn<int>(
    'storage_quota_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageUsedBytesMeta = const VerificationMeta(
    'storageUsedBytes',
  );
  @override
  late final GeneratedColumn<int> storageUsedBytes = GeneratedColumn<int>(
    'storage_used_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    email,
    role,
    storageQuotaBytes,
    storageUsedBytes,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('storage_quota_bytes')) {
      context.handle(
        _storageQuotaBytesMeta,
        storageQuotaBytes.isAcceptableOrUnknown(
          data['storage_quota_bytes']!,
          _storageQuotaBytesMeta,
        ),
      );
    }
    if (data.containsKey('storage_used_bytes')) {
      context.handle(
        _storageUsedBytesMeta,
        storageUsedBytes.isAcceptableOrUnknown(
          data['storage_used_bytes']!,
          _storageUsedBytesMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      storageQuotaBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}storage_quota_bytes'],
      ),
      storageUsedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}storage_used_bytes'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $UserTableTable createAlias(String alias) {
    return $UserTableTable(attachedDatabase, alias);
  }
}

class UserTableData extends DataClass implements Insertable<UserTableData> {
  final String id;
  final String username;
  final String? email;
  final String role;
  final int? storageQuotaBytes;
  final int? storageUsedBytes;
  final DateTime? lastSyncAt;
  const UserTableData({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.storageQuotaBytes,
    this.storageUsedBytes,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || storageQuotaBytes != null) {
      map['storage_quota_bytes'] = Variable<int>(storageQuotaBytes);
    }
    if (!nullToAbsent || storageUsedBytes != null) {
      map['storage_used_bytes'] = Variable<int>(storageUsedBytes);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  UserTableCompanion toCompanion(bool nullToAbsent) {
    return UserTableCompanion(
      id: Value(id),
      username: Value(username),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      role: Value(role),
      storageQuotaBytes: storageQuotaBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(storageQuotaBytes),
      storageUsedBytes: storageUsedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(storageUsedBytes),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory UserTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTableData(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      email: serializer.fromJson<String?>(json['email']),
      role: serializer.fromJson<String>(json['role']),
      storageQuotaBytes: serializer.fromJson<int?>(json['storageQuotaBytes']),
      storageUsedBytes: serializer.fromJson<int?>(json['storageUsedBytes']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'email': serializer.toJson<String?>(email),
      'role': serializer.toJson<String>(role),
      'storageQuotaBytes': serializer.toJson<int?>(storageQuotaBytes),
      'storageUsedBytes': serializer.toJson<int?>(storageUsedBytes),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  UserTableData copyWith({
    String? id,
    String? username,
    Value<String?> email = const Value.absent(),
    String? role,
    Value<int?> storageQuotaBytes = const Value.absent(),
    Value<int?> storageUsedBytes = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => UserTableData(
    id: id ?? this.id,
    username: username ?? this.username,
    email: email.present ? email.value : this.email,
    role: role ?? this.role,
    storageQuotaBytes: storageQuotaBytes.present
        ? storageQuotaBytes.value
        : this.storageQuotaBytes,
    storageUsedBytes: storageUsedBytes.present
        ? storageUsedBytes.value
        : this.storageUsedBytes,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  UserTableData copyWithCompanion(UserTableCompanion data) {
    return UserTableData(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      email: data.email.present ? data.email.value : this.email,
      role: data.role.present ? data.role.value : this.role,
      storageQuotaBytes: data.storageQuotaBytes.present
          ? data.storageQuotaBytes.value
          : this.storageQuotaBytes,
      storageUsedBytes: data.storageUsedBytes.present
          ? data.storageUsedBytes.value
          : this.storageUsedBytes,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTableData(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('storageQuotaBytes: $storageQuotaBytes, ')
          ..write('storageUsedBytes: $storageUsedBytes, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    email,
    role,
    storageQuotaBytes,
    storageUsedBytes,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTableData &&
          other.id == this.id &&
          other.username == this.username &&
          other.email == this.email &&
          other.role == this.role &&
          other.storageQuotaBytes == this.storageQuotaBytes &&
          other.storageUsedBytes == this.storageUsedBytes &&
          other.lastSyncAt == this.lastSyncAt);
}

class UserTableCompanion extends UpdateCompanion<UserTableData> {
  final Value<String> id;
  final Value<String> username;
  final Value<String?> email;
  final Value<String> role;
  final Value<int?> storageQuotaBytes;
  final Value<int?> storageUsedBytes;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const UserTableCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.role = const Value.absent(),
    this.storageQuotaBytes = const Value.absent(),
    this.storageUsedBytes = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTableCompanion.insert({
    required String id,
    required String username,
    this.email = const Value.absent(),
    this.role = const Value.absent(),
    this.storageQuotaBytes = const Value.absent(),
    this.storageUsedBytes = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       username = Value(username);
  static Insertable<UserTableData> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? email,
    Expression<String>? role,
    Expression<int>? storageQuotaBytes,
    Expression<int>? storageUsedBytes,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (storageQuotaBytes != null) 'storage_quota_bytes': storageQuotaBytes,
      if (storageUsedBytes != null) 'storage_used_bytes': storageUsedBytes,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTableCompanion copyWith({
    Value<String>? id,
    Value<String>? username,
    Value<String?>? email,
    Value<String>? role,
    Value<int?>? storageQuotaBytes,
    Value<int?>? storageUsedBytes,
    Value<DateTime?>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return UserTableCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      storageQuotaBytes: storageQuotaBytes ?? this.storageQuotaBytes,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (storageQuotaBytes.present) {
      map['storage_quota_bytes'] = Variable<int>(storageQuotaBytes.value);
    }
    if (storageUsedBytes.present) {
      map['storage_used_bytes'] = Variable<int>(storageUsedBytes.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTableCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('storageQuotaBytes: $storageQuotaBytes, ')
          ..write('storageUsedBytes: $storageUsedBytes, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FilesTableTable filesTable = $FilesTableTable(this);
  late final $FoldersTableTable foldersTable = $FoldersTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $SyncConflictsTableTable syncConflictsTable =
      $SyncConflictsTableTable(this);
  late final $CachedFilesTableTable cachedFilesTable = $CachedFilesTableTable(
    this,
  );
  late final $UserTableTable userTable = $UserTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    filesTable,
    foldersTable,
    syncQueueTable,
    syncConflictsTable,
    cachedFilesTable,
    userTable,
  ];
}

typedef $$FilesTableTableCreateCompanionBuilder =
    FilesTableCompanion Function({
      required String id,
      required String name,
      required String path,
      required int size,
      required String mimeType,
      Value<String?> folderId,
      Value<String?> ownerId,
      Value<String?> hash,
      Value<String?> etag,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<DateTime?> syncedAt,
      Value<bool> isFavorite,
      Value<bool> isAvailableOffline,
      Value<String?> localCachePath,
      Value<int> rowid,
    });
typedef $$FilesTableTableUpdateCompanionBuilder =
    FilesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> path,
      Value<int> size,
      Value<String> mimeType,
      Value<String?> folderId,
      Value<String?> ownerId,
      Value<String?> hash,
      Value<String?> etag,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<DateTime?> syncedAt,
      Value<bool> isFavorite,
      Value<bool> isAvailableOffline,
      Value<String?> localCachePath,
      Value<int> rowid,
    });

class $$FilesTableTableFilterComposer
    extends Composer<_$AppDatabase, $FilesTableTable> {
  $$FilesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailableOffline => $composableBuilder(
    column: $table.isAvailableOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCachePath => $composableBuilder(
    column: $table.localCachePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FilesTableTable> {
  $$FilesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailableOffline => $composableBuilder(
    column: $table.isAvailableOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCachePath => $composableBuilder(
    column: $table.localCachePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilesTableTable> {
  $$FilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAvailableOffline => $composableBuilder(
    column: $table.isAvailableOffline,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localCachePath => $composableBuilder(
    column: $table.localCachePath,
    builder: (column) => column,
  );
}

class $$FilesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilesTableTable,
          FilesTableData,
          $$FilesTableTableFilterComposer,
          $$FilesTableTableOrderingComposer,
          $$FilesTableTableAnnotationComposer,
          $$FilesTableTableCreateCompanionBuilder,
          $$FilesTableTableUpdateCompanionBuilder,
          (
            FilesTableData,
            BaseReferences<_$AppDatabase, $FilesTableTable, FilesTableData>,
          ),
          FilesTableData,
          PrefetchHooks Function()
        > {
  $$FilesTableTableTableManager(_$AppDatabase db, $FilesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isAvailableOffline = const Value.absent(),
                Value<String?> localCachePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilesTableCompanion(
                id: id,
                name: name,
                path: path,
                size: size,
                mimeType: mimeType,
                folderId: folderId,
                ownerId: ownerId,
                hash: hash,
                etag: etag,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                syncedAt: syncedAt,
                isFavorite: isFavorite,
                isAvailableOffline: isAvailableOffline,
                localCachePath: localCachePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String path,
                required int size,
                required String mimeType,
                Value<String?> folderId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isAvailableOffline = const Value.absent(),
                Value<String?> localCachePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilesTableCompanion.insert(
                id: id,
                name: name,
                path: path,
                size: size,
                mimeType: mimeType,
                folderId: folderId,
                ownerId: ownerId,
                hash: hash,
                etag: etag,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                syncedAt: syncedAt,
                isFavorite: isFavorite,
                isAvailableOffline: isAvailableOffline,
                localCachePath: localCachePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilesTableTable,
      FilesTableData,
      $$FilesTableTableFilterComposer,
      $$FilesTableTableOrderingComposer,
      $$FilesTableTableAnnotationComposer,
      $$FilesTableTableCreateCompanionBuilder,
      $$FilesTableTableUpdateCompanionBuilder,
      (
        FilesTableData,
        BaseReferences<_$AppDatabase, $FilesTableTable, FilesTableData>,
      ),
      FilesTableData,
      PrefetchHooks Function()
    >;
typedef $$FoldersTableTableCreateCompanionBuilder =
    FoldersTableCompanion Function({
      required String id,
      required String name,
      required String path,
      Value<String?> parentId,
      Value<String?> ownerId,
      Value<bool> isRoot,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$FoldersTableTableUpdateCompanionBuilder =
    FoldersTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> path,
      Value<String?> parentId,
      Value<String?> ownerId,
      Value<bool> isRoot,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$FoldersTableTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTableTable> {
  $$FoldersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRoot => $composableBuilder(
    column: $table.isRoot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTableTable> {
  $$FoldersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRoot => $composableBuilder(
    column: $table.isRoot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTableTable> {
  $$FoldersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<bool> get isRoot =>
      $composableBuilder(column: $table.isRoot, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$FoldersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTableTable,
          FoldersTableData,
          $$FoldersTableTableFilterComposer,
          $$FoldersTableTableOrderingComposer,
          $$FoldersTableTableAnnotationComposer,
          $$FoldersTableTableCreateCompanionBuilder,
          $$FoldersTableTableUpdateCompanionBuilder,
          (
            FoldersTableData,
            BaseReferences<_$AppDatabase, $FoldersTableTable, FoldersTableData>,
          ),
          FoldersTableData,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableTableManager(_$AppDatabase db, $FoldersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<bool> isRoot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersTableCompanion(
                id: id,
                name: name,
                path: path,
                parentId: parentId,
                ownerId: ownerId,
                isRoot: isRoot,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String path,
                Value<String?> parentId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<bool> isRoot = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersTableCompanion.insert(
                id: id,
                name: name,
                path: path,
                parentId: parentId,
                ownerId: ownerId,
                isRoot: isRoot,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTableTable,
      FoldersTableData,
      $$FoldersTableTableFilterComposer,
      $$FoldersTableTableOrderingComposer,
      $$FoldersTableTableAnnotationComposer,
      $$FoldersTableTableCreateCompanionBuilder,
      $$FoldersTableTableUpdateCompanionBuilder,
      (
        FoldersTableData,
        BaseReferences<_$AppDatabase, $FoldersTableTable, FoldersTableData>,
      ),
      FoldersTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      required String operationType,
      Value<String> status,
      required String itemId,
      required String itemType,
      required String payload,
      Value<int> retryCount,
      Value<String?> errorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> scheduledAt,
      Value<int> priority,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      Value<String> operationType,
      Value<String> status,
      Value<String> itemId,
      Value<String> itemType,
      Value<String> payload,
      Value<int> retryCount,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> scheduledAt,
      Value<int> priority,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                operationType: operationType,
                status: status,
                itemId: itemId,
                itemType: itemType,
                payload: payload,
                retryCount: retryCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                scheduledAt: scheduledAt,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationType,
                Value<String> status = const Value.absent(),
                required String itemId,
                required String itemType,
                required String payload,
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => SyncQueueTableCompanion.insert(
                id: id,
                operationType: operationType,
                status: status,
                itemId: itemId,
                itemType: itemType,
                payload: payload,
                retryCount: retryCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                scheduledAt: scheduledAt,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictsTableTableCreateCompanionBuilder =
    SyncConflictsTableCompanion Function({
      Value<int> id,
      required String itemId,
      required String itemType,
      required String operationType,
      Value<String> conflictType,
      required String payload,
      Value<String?> errorMessage,
      Value<String?> resolution,
      Value<DateTime?> resolvedAt,
      required DateTime createdAt,
    });
typedef $$SyncConflictsTableTableUpdateCompanionBuilder =
    SyncConflictsTableCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> itemType,
      Value<String> operationType,
      Value<String> conflictType,
      Value<String> payload,
      Value<String?> errorMessage,
      Value<String?> resolution,
      Value<DateTime?> resolvedAt,
      Value<DateTime> createdAt,
    });

class $$SyncConflictsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTableTable> {
  $$SyncConflictsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictType => $composableBuilder(
    column: $table.conflictType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTableTable> {
  $$SyncConflictsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictType => $composableBuilder(
    column: $table.conflictType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTableTable> {
  $$SyncConflictsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflictType => $composableBuilder(
    column: $table.conflictType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncConflictsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictsTableTable,
          SyncConflictsTableData,
          $$SyncConflictsTableTableFilterComposer,
          $$SyncConflictsTableTableOrderingComposer,
          $$SyncConflictsTableTableAnnotationComposer,
          $$SyncConflictsTableTableCreateCompanionBuilder,
          $$SyncConflictsTableTableUpdateCompanionBuilder,
          (
            SyncConflictsTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncConflictsTableTable,
              SyncConflictsTableData
            >,
          ),
          SyncConflictsTableData,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableTableManager(
    _$AppDatabase db,
    $SyncConflictsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> conflictType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncConflictsTableCompanion(
                id: id,
                itemId: itemId,
                itemType: itemType,
                operationType: operationType,
                conflictType: conflictType,
                payload: payload,
                errorMessage: errorMessage,
                resolution: resolution,
                resolvedAt: resolvedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String itemType,
                required String operationType,
                Value<String> conflictType = const Value.absent(),
                required String payload,
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                required DateTime createdAt,
              }) => SyncConflictsTableCompanion.insert(
                id: id,
                itemId: itemId,
                itemType: itemType,
                operationType: operationType,
                conflictType: conflictType,
                payload: payload,
                errorMessage: errorMessage,
                resolution: resolution,
                resolvedAt: resolvedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictsTableTable,
      SyncConflictsTableData,
      $$SyncConflictsTableTableFilterComposer,
      $$SyncConflictsTableTableOrderingComposer,
      $$SyncConflictsTableTableAnnotationComposer,
      $$SyncConflictsTableTableCreateCompanionBuilder,
      $$SyncConflictsTableTableUpdateCompanionBuilder,
      (
        SyncConflictsTableData,
        BaseReferences<
          _$AppDatabase,
          $SyncConflictsTableTable,
          SyncConflictsTableData
        >,
      ),
      SyncConflictsTableData,
      PrefetchHooks Function()
    >;
typedef $$CachedFilesTableTableCreateCompanionBuilder =
    CachedFilesTableCompanion Function({
      required String fileId,
      required String localPath,
      required int sizeBytes,
      Value<String?> hash,
      required DateTime cachedAt,
      required DateTime lastAccessedAt,
      Value<bool> isPinned,
      Value<int> rowid,
    });
typedef $$CachedFilesTableTableUpdateCompanionBuilder =
    CachedFilesTableCompanion Function({
      Value<String> fileId,
      Value<String> localPath,
      Value<int> sizeBytes,
      Value<String?> hash,
      Value<DateTime> cachedAt,
      Value<DateTime> lastAccessedAt,
      Value<bool> isPinned,
      Value<int> rowid,
    });

class $$CachedFilesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFilesTableTable> {
  $$CachedFilesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFilesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFilesTableTable> {
  $$CachedFilesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFilesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFilesTableTable> {
  $$CachedFilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);
}

class $$CachedFilesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFilesTableTable,
          CachedFilesTableData,
          $$CachedFilesTableTableFilterComposer,
          $$CachedFilesTableTableOrderingComposer,
          $$CachedFilesTableTableAnnotationComposer,
          $$CachedFilesTableTableCreateCompanionBuilder,
          $$CachedFilesTableTableUpdateCompanionBuilder,
          (
            CachedFilesTableData,
            BaseReferences<
              _$AppDatabase,
              $CachedFilesTableTable,
              CachedFilesTableData
            >,
          ),
          CachedFilesTableData,
          PrefetchHooks Function()
        > {
  $$CachedFilesTableTableTableManager(
    _$AppDatabase db,
    $CachedFilesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFilesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFilesTableCompanion(
                fileId: fileId,
                localPath: localPath,
                sizeBytes: sizeBytes,
                hash: hash,
                cachedAt: cachedAt,
                lastAccessedAt: lastAccessedAt,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required String localPath,
                required int sizeBytes,
                Value<String?> hash = const Value.absent(),
                required DateTime cachedAt,
                required DateTime lastAccessedAt,
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFilesTableCompanion.insert(
                fileId: fileId,
                localPath: localPath,
                sizeBytes: sizeBytes,
                hash: hash,
                cachedAt: cachedAt,
                lastAccessedAt: lastAccessedAt,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFilesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFilesTableTable,
      CachedFilesTableData,
      $$CachedFilesTableTableFilterComposer,
      $$CachedFilesTableTableOrderingComposer,
      $$CachedFilesTableTableAnnotationComposer,
      $$CachedFilesTableTableCreateCompanionBuilder,
      $$CachedFilesTableTableUpdateCompanionBuilder,
      (
        CachedFilesTableData,
        BaseReferences<
          _$AppDatabase,
          $CachedFilesTableTable,
          CachedFilesTableData
        >,
      ),
      CachedFilesTableData,
      PrefetchHooks Function()
    >;
typedef $$UserTableTableCreateCompanionBuilder =
    UserTableCompanion Function({
      required String id,
      required String username,
      Value<String?> email,
      Value<String> role,
      Value<int?> storageQuotaBytes,
      Value<int?> storageUsedBytes,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });
typedef $$UserTableTableUpdateCompanionBuilder =
    UserTableCompanion Function({
      Value<String> id,
      Value<String> username,
      Value<String?> email,
      Value<String> role,
      Value<int?> storageQuotaBytes,
      Value<int?> storageUsedBytes,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });

class $$UserTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserTableTable> {
  $$UserTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storageQuotaBytes => $composableBuilder(
    column: $table.storageQuotaBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storageUsedBytes => $composableBuilder(
    column: $table.storageUsedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserTableTable> {
  $$UserTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storageQuotaBytes => $composableBuilder(
    column: $table.storageQuotaBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storageUsedBytes => $composableBuilder(
    column: $table.storageUsedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTableTable> {
  $$UserTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get storageQuotaBytes => $composableBuilder(
    column: $table.storageQuotaBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get storageUsedBytes => $composableBuilder(
    column: $table.storageUsedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$UserTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserTableTable,
          UserTableData,
          $$UserTableTableFilterComposer,
          $$UserTableTableOrderingComposer,
          $$UserTableTableAnnotationComposer,
          $$UserTableTableCreateCompanionBuilder,
          $$UserTableTableUpdateCompanionBuilder,
          (
            UserTableData,
            BaseReferences<_$AppDatabase, $UserTableTable, UserTableData>,
          ),
          UserTableData,
          PrefetchHooks Function()
        > {
  $$UserTableTableTableManager(_$AppDatabase db, $UserTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int?> storageQuotaBytes = const Value.absent(),
                Value<int?> storageUsedBytes = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTableCompanion(
                id: id,
                username: username,
                email: email,
                role: role,
                storageQuotaBytes: storageQuotaBytes,
                storageUsedBytes: storageUsedBytes,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String username,
                Value<String?> email = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int?> storageQuotaBytes = const Value.absent(),
                Value<int?> storageUsedBytes = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTableCompanion.insert(
                id: id,
                username: username,
                email: email,
                role: role,
                storageQuotaBytes: storageQuotaBytes,
                storageUsedBytes: storageUsedBytes,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserTableTable,
      UserTableData,
      $$UserTableTableFilterComposer,
      $$UserTableTableOrderingComposer,
      $$UserTableTableAnnotationComposer,
      $$UserTableTableCreateCompanionBuilder,
      $$UserTableTableUpdateCompanionBuilder,
      (
        UserTableData,
        BaseReferences<_$AppDatabase, $UserTableTable, UserTableData>,
      ),
      UserTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FilesTableTableTableManager get filesTable =>
      $$FilesTableTableTableManager(_db, _db.filesTable);
  $$FoldersTableTableTableManager get foldersTable =>
      $$FoldersTableTableTableManager(_db, _db.foldersTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$SyncConflictsTableTableTableManager get syncConflictsTable =>
      $$SyncConflictsTableTableTableManager(_db, _db.syncConflictsTable);
  $$CachedFilesTableTableTableManager get cachedFilesTable =>
      $$CachedFilesTableTableTableManager(_db, _db.cachedFilesTable);
  $$UserTableTableTableManager get userTable =>
      $$UserTableTableTableManager(_db, _db.userTable);
}
