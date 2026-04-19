import 'package:drift/drift.dart';

class FilesTable extends Table {
  @override
  String get tableName => 'files';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  IntColumn get size => integer()();
  TextColumn get mimeType => text()();
  TextColumn get folderId => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get hash => text().nullable()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isAvailableOffline =>
      boolean().withDefault(const Constant(false))();
  TextColumn get localCachePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
