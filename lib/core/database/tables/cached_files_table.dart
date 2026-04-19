import 'package:drift/drift.dart';

class CachedFilesTable extends Table {
  @override
  String get tableName => 'cached_files';

  TextColumn get fileId => text()();
  TextColumn get localPath => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get hash => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {fileId};
}
